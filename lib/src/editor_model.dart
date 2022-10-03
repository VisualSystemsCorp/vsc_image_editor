import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide TransformationController;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:zoom_widget/zoom_widget.dart';

part 'editor_model.g.dart';

enum Tool {
  select(Icons.pan_tool_alt),
  crop(Icons.crop),
  draw(Icons.gesture),
  text(Icons.text_fields),
  oval(Icons.circle_outlined),
  rectangle(Icons.rectangle_outlined);

  const Tool(this.icon);

  final IconData icon;
}

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {
  EditorModelBase(Uint8List imageBytes) {
    _initialize(imageBytes);
  }

  final TransformationController transformationController =
      TransformationController();
  late final ImagePainter imagePainter;

  @readonly
  ui.Image? _uiImage;

  @readonly
  double _physicalWidth = 0;

  @readonly
  double _physicalHeight = 0;

  @readonly
  ui.Rect _viewport = ui.Rect.zero;

  @readonly
  ui.Rect _physicalCropRect = ui.Rect.zero;

  // We save current physical crop during cropping in case it is canceled.
  ui.Rect _savedPhysicalCropRect = ui.Rect.zero;

  @readonly
  ui.Rect _controlCropRect = ui.Rect.zero;

  @readonly
  var _selectedTool = Tool.select;

  @readonly
  // ignore: prefer_final_fields
  var _viewportOverlays = ObservableList<Widget>();

  @readonly
  double _zoomScale = 1;

  @readonly
  bool _initialized = false;

  @action
  Future<void> _initialize(Uint8List imageBytes) async {
    imagePainter = ImagePainter(this as EditorModel);
    transformationController.addListener(() {
      _zoomScale = transformationController.value.getMaxScaleOnAxis();
    });

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    _physicalWidth = _uiImage!.width.toDouble();
    _physicalHeight = _uiImage!.height.toDouble();
    _physicalCropRect = ui.Rect.fromLTWH(0, 0, _physicalWidth, _physicalHeight);

    _initialized = true;
  }

  void dispose() {
    _uiImage?.dispose();
    transformationController.dispose();
  }

  @action
  void setViewportSize(double width, double height) {
    _viewport = ui.Rect.fromLTWH(_viewport.left, _viewport.top, width, height);
    debugPrint('viewport updated $_viewport');
  }

  @action
  void selectTool(Tool tool, {bool cancelCropping = true}) {
    final lastTool = _selectedTool;
    _selectedTool = tool;
    if (cancelCropping && lastTool == Tool.crop && tool != Tool.crop) {
      cancelCrop(selectDefaultTool: false);
    }

    switch (_selectedTool) {
      case Tool.select:
        _viewportOverlays.clear();
        break;

      case Tool.crop:
        startCrop();
        break;
      default:
        break;
    }
  }

  @action
  void startCrop() {
    // Reset any current crop
    _savedPhysicalCropRect = _physicalCropRect;
    clearCrop();

    // Zoom so full image fits viewport, and reset pan
    // TODO Rotation!
    final scale = min(
        _viewport.width / _physicalWidth, _viewport.height / _physicalHeight);
    transformationController.value = Matrix4.identity()..scale(scale);

    final insetX = _viewport.width * 0.10;
    final insetY = _viewport.height * 0.10;
    _updateCropRect(ui.Rect.fromLTRB(
        insetX, insetY, _viewport.width - insetX, _viewport.height - insetY));

    _viewportOverlays
      ..clear()
      ..add(_CropControl(model: this as EditorModel));
  }

  @action
  void cancelCrop({bool selectDefaultTool = true}) {
    _physicalCropRect = _savedPhysicalCropRect;
    if (selectDefaultTool) {
      selectTool(Tool.select);
    }
  }

  @action
  void clearCrop() {
    _physicalCropRect = ui.Rect.fromLTWH(0, 0, _physicalWidth, _physicalHeight);
  }

  @action
  void updateCropLeftTop(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left + details.delta.dx,
        _controlCropRect.top + details.delta.dy,
        _controlCropRect.right,
        _controlCropRect.bottom);
    _updateCropRect(newRect);
  }

  void _updateCropRect(ui.Rect newRect) {
    var left = newRect.left;
    var right = newRect.right;
    var top = newRect.top;
    var bottom = newRect.bottom;
    if (left > right) {
      left = right;
    }
    if (top > bottom) {
      top = bottom;
    }

    // Cannot be out of bounds of image.
    final imageViewportRect = MatrixUtils.transformRect(
        transformationController.value,
        ui.Rect.fromLTWH(0, 0, _physicalWidth, _physicalHeight));
    if (left < imageViewportRect.left) {
      left = imageViewportRect.left;
    }

    if (right > imageViewportRect.right) {
      right = imageViewportRect.right;
    }

    if (top < imageViewportRect.top) {
      top = imageViewportRect.top;
    }

    if (bottom > imageViewportRect.bottom) {
      bottom = imageViewportRect.bottom;
    }

    _controlCropRect = ui.Rect.fromLTRB(left, top, right, bottom);
  }

  @action
  void updateCropLeftBottom(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left + details.delta.dx,
        _controlCropRect.top,
        _controlCropRect.right,
        _controlCropRect.bottom + details.delta.dy);
    _updateCropRect(newRect);
  }

  @action
  void updateCropRightTop(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left,
        _controlCropRect.top + details.delta.dy,
        _controlCropRect.right + details.delta.dx,
        _controlCropRect.bottom);
    _updateCropRect(newRect);
  }

  @action
  void updateCropRightBottom(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left,
        _controlCropRect.top,
        _controlCropRect.right + details.delta.dx,
        _controlCropRect.bottom + details.delta.dy);
    _updateCropRect(newRect);
  }

  @action
  void applyCrop() {
    // debugPrint('Before: $_physicalCropRect control=$_controlCropRect');
    _physicalCropRect = MatrixUtils.transformRect(
        Matrix4.copy(transformationController.value)..invert(),
        _controlCropRect);
    // debugPrint('after $_physicalCropRect');
    selectTool(Tool.select, cancelCropping: false);
  }

  Future<ui.Image> getEditedUiImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    imagePainter.paint(canvas, Size.zero);
    return recorder.endRecording().toImage(
        _physicalCropRect.width.floor(), _physicalCropRect.height.floor());
  }
}

class _CropControl extends StatelessWidget {
  const _CropControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        final cropRect = model.controlCropRect;
        const controlWH = 15.0;
        const halfControlWH = controlWH / 2;
        final controlSquare =
            Container(color: Colors.white, width: controlWH, height: controlWH);
        return Stack(
          children: [
            // scrim
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(painter: _CropScrimPainter(cropRect)),
            ),
            // upper left
            Positioned(
              left: cropRect.left - halfControlWH,
              top: cropRect.top - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropLeftTop(details),
                child: controlSquare,
              ),
            ),
            // upper right
            Positioned(
              left: cropRect.right - halfControlWH,
              top: cropRect.top - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropRightTop(details),
                child: controlSquare,
              ),
            ),
            // lower left
            Positioned(
              left: cropRect.left - halfControlWH,
              bottom: (model.viewport.bottom - cropRect.bottom) - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropLeftBottom(details),
                child: controlSquare,
              ),
            ),
            // lower right
            Positioned(
              left: cropRect.right - halfControlWH,
              bottom: (model.viewport.bottom - cropRect.bottom) - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropRightBottom(details),
                child: controlSquare,
              ),
            ),
            Positioned(
                left: (cropRect.left + cropRect.width / 2) - (20 * 2 + 4),
                top: (cropRect.top + cropRect.height) - 20,
                child: Row(
                  children: [
                    FloatingActionButton.small(
                      onPressed: () => model.applyCrop(),
                      child: const Icon(Icons.done),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      onPressed: () => model.cancelCrop(),
                      child: const Icon(Icons.close),
                    ),
                  ],
                )),
          ],
        );
      },
    );
  }
}

class _CropScrimPainter extends CustomPainter {
  _CropScrimPainter(this.cropRect);

  ui.Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final transparentOverlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    canvas.drawPath(
        Path.combine(
            PathOperation.difference,
            Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
            Path()..addRect(cropRect)),
        transparentOverlayPaint);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawRect(cropRect, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ImagePainter extends CustomPainter {
  ImagePainter(this._model);

  final EditorModel _model;

  @override
  void paint(Canvas canvas, Size _) {
    canvas.translate(
        -_model.physicalCropRect.left, -_model.physicalCropRect.top);
    canvas.clipRect(_model.physicalCropRect);
    canvas.drawImage(
      _model.uiImage!,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
/*
                Image.memory(
                  _model.imageBytes,
                  // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
                  filterQuality: FilterQuality.medium,
                ),

 */
