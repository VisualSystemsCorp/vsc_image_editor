import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:vsc_image_editor/vsc_image_editor.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VscImageEditor Demo',
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
        title: const Text('VscImageEditor Demo'),
      ),
      // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
      body: _imageBytes == null
          ? const SizedBox.shrink()
          : VscImageEditor(imageBytes: _imageBytes!),
    );
  }
}
