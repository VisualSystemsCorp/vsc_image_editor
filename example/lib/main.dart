import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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
  Uint8List? _imageBytes;
  VscImageEditorController controller = VscImageEditorController();
  static const _cropRatios = [null, 1.0, 1.7778];
  final _cropRatioSelections = [true, false, false];

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('VscImageEditor Example'),
        actions: [
          ToggleButtons(
            isSelected: _cropRatioSelections,
            onPressed: (index) {
              _cropRatioSelections.setAll(0, [false, false, false]);
              _cropRatioSelections[index] = true;
              setState(() {});
            },
            selectedBorderColor: colorScheme.onPrimary,
            children: [
              Text('Free', style: buttonTextStyle),
              Text('1:1', style: buttonTextStyle),
              Text('16:9', style: buttonTextStyle),
            ],
          ),
          const SizedBox(width: 8),
          // Builder is needed to get the correct context for _share().
          Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => _share(context),
                child: Text(
                  'Share',
                  style: buttonTextStyle,
                ),
              );
            },
          ),
          Padding(
            // Avoid the "Debug" banner
            padding: const EdgeInsets.fromLTRB(0, 0, 54, 0),
            child: TextButton(
              onPressed: _save,
              child: Text(
                'Save',
                style: buttonTextStyle,
              ),
            ),
          ),
        ],
      ),
      // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
      body: _imageBytes == null
          ? const SizedBox.shrink()
          : VscImageEditor(
              imageBytes: _imageBytes!,
              controller: controller,
              fixedCropRatio: _cropRatios[
                  _cropRatioSelections.indexWhere((element) => element)],
            ),
    );
  }

  Future<void> _save() async {
    final encodedBytes = await _getEncodedBytes();
    final out = File('Test-image-out.jpg');
    out.writeAsBytesSync(encodedBytes, flush: true);
    debugPrint('Wrote file');
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

  // TODO Not working yet with share_plus 4.5.2 - stack overflow on linux, "this.share is not a function error" on web
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
