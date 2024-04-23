import 'dart:async';
import 'dart:io';

import 'package:chunked_stream/chunked_stream.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vsc_image_editor/vsc_image_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VscImageEditor Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const _Example(),
    );
  }
}

class _Example extends StatefulWidget {
  const _Example({Key? key}) : super(key: key);

  @override
  State<_Example> createState() => _ExampleState();
}

class _ExampleState extends State<_Example> {
  static const _cropRatios = [null, 1.0, 1.7778];
  static const _selectableTools = [Tool.select, Tool.crop, Tool.draw];

  final _cropRatioSelections = [true, false, false];
  final _toolSelections = [true, false, false];
  Tool? _selectedTool = _selectableTools[0];
  double? _cropRatio = _cropRatios[0];
  bool _showCropCircle = false;
  bool _viewOnly = false;
  Uint8List? _lastEditedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VscImageEditor Example'),
      ),
      body: SingleChildScrollView(
        child: Align(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              const Text('Fixed Crop Ratio'),
              ToggleButtons(
                isSelected: _cropRatioSelections,
                onPressed: (index) {
                  _cropRatioSelections.setAll(0, [false, false, false]);
                  _cropRatioSelections[index] = true;
                  _cropRatio = _cropRatios[index];
                  setState(() {});
                },
                // selectedBorderColor: colorScheme.onPrimary.withOpacity(0.54),
                children: const [
                  Text('None'),
                  Text('1:1'),
                  Text('16:9'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Initial Tool Selection'),
              ToggleButtons(
                isSelected: _toolSelections,
                onPressed: (index) {
                  _toolSelections.setAll(0, [false, false, false]);
                  _toolSelections[index] = true;
                  _selectedTool = _selectableTools[index];
                  setState(() {});
                },
                children: _selectableTools
                    .map((tool) => Icon(tool.icon))
                    .toList(growable: false),
              ),
              const SizedBox(height: 24),
              const Text('Show Crop Circle'),
              Switch(
                value: _showCropCircle,
                onChanged: (value) => setState(() {
                  _showCropCircle = value;
                }),
              ),
              const SizedBox(height: 24),
              const Text('View-only'),
              Switch(
                value: _viewOnly,
                onChanged: (value) => setState(() {
                  _viewOnly = value;
                }),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _pickFileAndEdit(context),
                child: const Text('Edit an Image'),
              ),
              const SizedBox(height: 24),
              if (_lastEditedImage != null) const Text('Last image edited'),
              if (_lastEditedImage != null)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Image.memory(_lastEditedImage!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFileAndEdit(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withReadStream: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }

    var imageBytes = await readByteStream(result.files[0].readStream!);
    // Ensure the Uint8List is a proper sublist. See remark on readByteStream().
    imageBytes = imageBytes.sublist(imageBytes.offsetInBytes,
        imageBytes.offsetInBytes + imageBytes.lengthInBytes);

    if (mounted) {
      await _showEditDialog(context, imageBytes);
    }
  }

  Future<void> _showEditDialog(
      BuildContext context, Uint8List imageBytes) async {
    VscImageEditorController controller = VscImageEditorController();
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: 1.0,
          child: Card(
            child: Scaffold(
              appBar: AppBar(
                leading: CloseButton(
                  onPressed: () async {
                    if (await _isOkToClose(context, controller)) {
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                ),
                primary: false,
                title: Text(_viewOnly ? 'View Image' : 'Edit Image'),
                actions: [
                  if (!_viewOnly)
                    Padding(
                      // Avoid the "Debug" banner
                      padding: const EdgeInsets.only(right: 20.0),
                      child: IconButton(
                        icon: const Icon(Icons.save),
                        tooltip: 'Save image',
                        onPressed: () async {
                          await _saveImage(context, controller);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                ],
              ),
              body: VscImageEditor(
                imageBytes: imageBytes,
                controller: controller,
                fixedCropRatio: _cropRatio,
                selectedTool: _selectedTool,
                showCropCircle: _showCropCircle,
                viewOnly: _viewOnly,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isOkToClose(
      BuildContext context, VscImageEditorController controller) async {
    if (!controller.isModified()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
            'You have made changes, but not yet saved them. What do you want to do?'),
        actions: [
          TextButton(
            child: const Text('Keep Editing'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text('Discard Changes'),
            onPressed: () => Navigator.pop(context, true),
          ),
          TextButton(
              child: const Text('Save Changes'),
              onPressed: () async {
                await _saveImage(context, controller);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              }),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveImage(
      BuildContext context, VscImageEditorController controller) async {
    final box = context.findRenderObject() as RenderBox?;
    final navigator = Navigator.of(context);

    var dialogDisplayed = false;
    showDialog(
      context: context,
      builder: (context) {
        dialogDisplayed = true;
        return const SimpleDialog(
          titlePadding: EdgeInsets.zero,
          children: [
            Center(child: Text('Saving image...')),
          ],
        );
      },
      barrierDismissible: false,
    );

    while (!dialogDisplayed) {
      await Future.delayed(const Duration(milliseconds: 32));
    }

    // Wait for dialog animations to complete.
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      await _saveWhileDialogDisplayed(box, controller);
    } finally {
      // Remove the dialog
      navigator.pop();
    }
  }

  Future<void> _saveWhileDialogDisplayed(
      RenderBox? box, VscImageEditorController controller) async {
    final encodedBytes = await _getEncodedBytes(controller);
    if (kIsWeb) {
      final path = await FileSaver.instance.saveFile(
        name: 'Test-image-out.jpg',
        bytes: Uint8List.fromList(encodedBytes),
        ext: '',
        mimeType: MimeType.jpeg,
      );
      debugPrint('Downloaded $path');
    } else {
      final tmpDir = await getTemporaryDirectory();
      final out = File(p.join(tmpDir.path, 'Test-image-out.jpg'));
      out.writeAsBytesSync(encodedBytes, flush: true);
      debugPrint('Wrote file $out');

      if (Platform.isAndroid || Platform.isIOS) {
        final xFile = XFile(out.absolute.path, mimeType: 'image/jpeg');
        final result = await Share.shareXFiles(
          [xFile],
          subject: 'VscImageEditor - edited image',
          text: 'Test',
          sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
        );

        debugPrint('Shared to ${result.status.name}');
      }
    }
  }

  Future<List<int>> _getEncodedBytes(
      VscImageEditorController controller) async {
    final image = await controller.getEditedUiImage();
    if (image == null) {
      throw Exception('Image is null');
    }

    final byteData = await image.toByteData();
    if (byteData == null) {
      throw Exception('ByteData is null');
    }

    final rawBytes = byteData.buffer;
    final internalImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: rawBytes,
      format: img.Format.uint8,
      order: img.ChannelOrder.rgba,
    );
    final encodedBytes = img.encodeJpg(internalImage, quality: 99);
    setState(() {
      _lastEditedImage = Uint8List.fromList(encodedBytes);
    });
    return encodedBytes;
  }

/*
  // TODO Not working yet with share_plus 4.5.3 - stack overflow on linux, "this.share is not a function" error on web
  //  Android: Failed assertion: line 111 pos 12: 'paths.every((element) => element.isNotEmpty)': is not true.
  Future<void> _share(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final encodedBytes = await _getEncodedBytes();
    final xFile = XFile.fromData(
      Uint8List.fromList(encodedBytes),
      mimeType: 'image/jpeg',
      name: 'Test-image-out.jpg',
    );

    final result = await Share.shareXFiles(
      [xFile],
      subject: 'Test',
      text: 'Hello',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );

    debugPrint('Shared to ${result.status.name}');
  }
 */
}
