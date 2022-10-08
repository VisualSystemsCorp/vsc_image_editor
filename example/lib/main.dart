import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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

  Uint8List? _imageBytes;
  VscImageEditorController controller = VscImageEditorController();
  final _cropRatioSelections = [true, false, false];
  final _toolSelections = [true, false, false];
  Tool? _selectedTool = _selectableTools[0];
  double? _cropRatio = _cropRatios[0];
  bool _showCropCircle = false;

  @override
  void initState() {
    super.initState();
    _loader();
  }

  Future<void> _loader() async {
    final imageByteData = await rootBundle.load('assets/Test-12MP-image.jpg');
    _imageBytes = imageByteData.buffer.asUint8List();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonTextStyle = TextStyle(
      color: colorScheme.onPrimary,
    );

    final isMobile = !kIsWeb && (Platform.isIOS || Platform.isAndroid);
    return Scaffold(
      appBar: AppBar(
        title: const Text('VscImageEditor'),
        actions: [
          ToggleButtons(
            isSelected: _toolSelections,
            onPressed: (index) {
              _toolSelections.setAll(0, [false, false, false]);
              _toolSelections[index] = true;
              _selectedTool = _selectableTools[index];
              setState(() {});
            },
            selectedBorderColor: colorScheme.onPrimary.withOpacity(0.54),
            children: _selectableTools
                .map((tool) => Icon(tool.icon, color: colorScheme.onPrimary))
                .toList(growable: false),
          ),
          VerticalDivider(
            color: colorScheme.onPrimary,
            indent: 10,
            endIndent: 10,
          ),
          ToggleButtons(
            isSelected: _cropRatioSelections,
            onPressed: (index) {
              _cropRatioSelections.setAll(0, [false, false, false]);
              _cropRatioSelections[index] = true;
              _cropRatio = _cropRatios[index];
              _showCropCircle = _cropRatio == 1;
              setState(() {});
            },
            selectedBorderColor: colorScheme.onPrimary.withOpacity(0.54),
            children: [
              Text('Free', style: buttonTextStyle),
              Text('1:1', style: buttonTextStyle),
              Text('16:9', style: buttonTextStyle),
            ],
          ),
          VerticalDivider(
            color: colorScheme.onPrimary,
            indent: 10,
            endIndent: 10,
          ),
          // // Builder is needed to get the correct context for _share().
          // if (isMobile)
          //   Builder(
          //     builder: (context) {
          //       return TextButton(
          //         onPressed: () => _share(context),
          //         child: Text(
          //           'Share',
          //           style: buttonTextStyle,
          //         ),
          //       );
          //     },
          //   ),
          // if (!isMobile)
          Expanded(
            child: TextButton(
              onPressed: () => _save(context),
              child: Text(
                'Save',
                style: buttonTextStyle,
              ),
            ),
          ),

          // Avoid the "Debug" banner
          if (!isMobile) const SizedBox(width: 24),
        ],
      ),
      // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
      body: _imageBytes == null
          ? const SizedBox.shrink()
          : VscImageEditor(
              imageBytes: _imageBytes!,
              controller: controller,
              fixedCropRatio: _cropRatio,
              selectedTool: _selectedTool,
              showCropCircle: _showCropCircle,
            ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final encodedBytes = await _getEncodedBytes();
    if (kIsWeb) {
      final path = await FileSaver.instance.saveFile(
        'Test-image-out.jpg',
        Uint8List.fromList(encodedBytes),
        '',
        mimeType: MimeType.JPEG,
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

  Future<List<int>> _getEncodedBytes() async {
    final image = await controller.getEditedUiImage();
    if (image == null) {
      throw Exception('Image is null');
    }

    final byteData = await image.toByteData();
    if (byteData == null) {
      throw Exception('ByteData is null');
    }

    final rawBytes = byteData.buffer.asUint8List();
    final internalImage =
        img.Image.fromBytes(image.width, image.height, rawBytes);
    final encodedBytes = img.encodeJpg(internalImage, quality: 99);
    return encodedBytes;
  }

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
}
