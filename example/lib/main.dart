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
    return Scaffold(
      appBar: AppBar(
        title: const Text('VscImageEditor Example'),
        actions: [
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => _share(context),
                child: const Text('Share'),
              );
            },
          ),
          Padding(
            // Avoid the "Debug" banner
            padding: const EdgeInsets.fromLTRB(0, 0, 54, 0),
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
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
