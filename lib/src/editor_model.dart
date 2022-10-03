import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:mobx/mobx.dart';

part 'editor_model.g.dart';

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {
  EditorModelBase(Uint8List imageBytes) {
    _initialize(imageBytes);
  }

  @readonly
  ui.Image? _uiImage;

  @readonly
  double _physicalWidth = 0;

  @readonly
  double _physicalHeight = 0;

  @readonly
  ui.Rect _viewport = ui.Rect.zero;

  @readonly
  ui.Rect _cropRect = ui.Rect.zero;

  @readonly
  bool _initialized = false;

  Future<void> _initialize(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    _physicalWidth = _uiImage!.width.toDouble();
    _physicalHeight = _uiImage!.height.toDouble();
    _initialized = true;
  }

  void dispose() {
    _uiImage?.dispose();
  }

  @action
  void setViewportSize(double width, double height) {
    _viewport = ui.Rect.fromLTWH(_viewport.left, _viewport.top, width, height);
  }

  @action
  void startCrop() {
    final insetX = _viewport.width * 0.10;
    final insetY = _viewport.height * 0.10;
    _cropRect = ui.Rect.fromLTRB(
        insetX, insetY, _viewport.width - insetX, _viewport.height - insetY);
  }

  @action
  void updateCropLeftTop(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(_cropRect.left + details.delta.dx,
        _cropRect.top + details.delta.dy, _cropRect.right, _cropRect.bottom);
    _updateCropRect(newRect);
  }

  void _updateCropRect(ui.Rect newRect) {
    if (newRect.left < (newRect.right - 20) &&
        newRect.top < (newRect.bottom - 20) &&
        _viewport.intersect(newRect) == newRect) {
      _cropRect = newRect;
    }
  }

  @action
  void updateCropLeftBottom(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(_cropRect.left + details.delta.dx,
        _cropRect.top, _cropRect.right, _cropRect.bottom + details.delta.dy);
    _updateCropRect(newRect);
  }

  @action
  void updateCropRightTop(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _cropRect.left,
        _cropRect.top + details.delta.dy,
        _cropRect.right + details.delta.dx,
        _cropRect.bottom);
    _updateCropRect(newRect);
  }

  @action
  void updateCropRightBottom(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _cropRect.left,
        _cropRect.top,
        _cropRect.right + details.delta.dx,
        _cropRect.bottom + details.delta.dy);
    _updateCropRect(newRect);
  }
}

/*
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) async {
      debugPrint('info: $info ');
      final bytes = await captureFromWidget(
        Stack(
          children: [
            image,
            Center(child: Icon(Icons.ac_unit, color: Colors.green, size: 300))
          ],
        ),
        pixelRatio: 1,
        context: context,
        targetSize:
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      debugPrint('bytes=${bytes.length}');

      final internalImage = img.decodeImage(bytes);
      final encodedBytes = img.encodeJpg(internalImage!, quality: 98);
      // img.Image.fromBytes(info.image.width, info.image.height, bytes));
      debugPrint('Encoded bytes = ${encodedBytes.length}');

      final out = File('/home/dsyrstad/Downloads/Test-12MP-OUT.jpg');
      out.writeAsBytesSync(encodedBytes, flush: true);
      debugPrint('Wrote file');
    }));

 */
