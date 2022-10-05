import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TransformationController;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
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

const _radians90Left = -pi / 2;
const _radians90Right = pi / 2;

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {
  EditorModelBase(Uint8List imageBytes) {
    _initialize(imageBytes);
  }

  final TransformationController viewportTransformationController =
      TransformationController();
  late final CustomPainter _imagePainter;
  late final Widget imagePainterWidget;

  @readonly
  ui.Image? _uiImage;

  @readonly
  double _fullImageNonRotatedPhysicalWidth = 0;

  @readonly
  double _fullImageNonRotatedPhysicalHeight = 0;

  ui.Rect get fullImageRotatedPhysicalRect => MatrixUtils.transformRect(
      _physicalCropRotationMatrix,
      Rect.fromLTWH(0, 0, _fullImageNonRotatedPhysicalWidth,
          _fullImageNonRotatedPhysicalHeight));

  double get fullImageRotatedPhysicalWidth =>
      fullImageRotatedPhysicalRect.width;
  double get fullImageRotatedPhysicalHeight =>
      fullImageRotatedPhysicalRect.height;

  /// The non-rotated cropping rectangle with dimensions in respect to the full image width/height.
  @readonly
  ui.Rect _physicalNonRotatedCropRect = ui.Rect.zero;

  /// The rotated cropping rectangle with dimensions in respect to the full image width/height.
  ui.Rect get physicalRotatedCropRect => MatrixUtils.transformRect(
      _physicalCropRotationMatrix, _physicalNonRotatedCropRect);

  @readonly
  ui.Rect _viewport = ui.Rect.zero;

  /// The rotation matrix with respect to the full image - how much the image has been rotated.
  @readonly
  var _physicalCropRotationMatrix = Matrix4.identity();

  // We save current physical crop during cropping in case it is canceled.
  ui.Rect _savedPhysicalNonRotatedCropRect = ui.Rect.zero;

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

  Path? _activePath;

  @readonly
  bool _imagePainterTrigger = false;

  @action
  Future<void> _initialize(Uint8List imageBytes) async {
    _imagePainter = ImagePainter(this as EditorModel);
    imagePainterWidget = _ImagePainterWidget(model: this as EditorModel);

    viewportTransformationController.addListener(() {
      _zoomScale = viewportTransformationController.value.getMaxScaleOnAxis();
    });

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    _fullImageNonRotatedPhysicalWidth = _uiImage!.width.toDouble();
    _fullImageNonRotatedPhysicalHeight = _uiImage!.height.toDouble();
    _physicalNonRotatedCropRect = ui.Rect.fromLTWH(0, 0,
        _fullImageNonRotatedPhysicalWidth, _fullImageNonRotatedPhysicalHeight);

    _initialized = true;
  }

  void dispose() {
    _uiImage?.dispose();
    viewportTransformationController.dispose();
  }

  @action
  void updateImage() => _imagePainterTrigger = !_imagePainterTrigger;

  @action
  void setViewportSize(double width, double height) {
    _viewport = ui.Rect.fromLTWH(_viewport.left, _viewport.top, width, height);
    // debugPrint('viewport updated $_viewport');
  }

  @action
  void selectTool(Tool tool, {bool cancelCropping = true}) {
    if (tool == _selectedTool) return;

    final lastTool = _selectedTool;
    _selectedTool = tool;
    if (cancelCropping && lastTool == Tool.crop && tool != Tool.crop) {
      cancelCrop(selectDefaultTool: false);
    }

    _viewportOverlays.clear();
    switch (_selectedTool) {
      case Tool.select:
        break;

      case Tool.crop:
        startCrop();
        break;

      case Tool.draw:
        startDraw();
        break;

      default:
        break;
    }
  }

  /// Sets the new scale, which also resets the pan (translation).
  @action
  void setScale(double scale) {
    final rotation = Quaternion.identity();
    final scaleVector = Vector3.zero();
    viewportTransformationController.value
        .decompose(Vector3.zero(), rotation, scaleVector);

    // No change? Don't reset translation.
    if (scaleVector.x == scale) return;

    viewportTransformationController.value =
        Matrix4.compose(Vector3.zero(), rotation, Vector3(scale, scale, scale));
  }

  /// Scale image to fit the viewport and reset the pan.
  @action
  void scaleToFitViewport() {
    final scale = min(_viewport.width / physicalRotatedCropRect.width,
        _viewport.height / physicalRotatedCropRect.height);
    setScale(scale);
  }

  /// Rotate the image 90 degrees to the left (CCW). Pan/translation is reset and image is scaled to fit the viewport.
  @action
  void rotate90Left() {
    // Cancel cropping if user decided to rotate while cropping.
    if (_selectedTool == Tool.crop) {
      cancelCrop();
    }

    // Rotate around 0,0 and adjust the rotated Y origin down with respect to the full image width
    _physicalCropRotationMatrix = _physicalCropRotationMatrix.clone()
      ..translate(0.0, fullImageRotatedPhysicalWidth)
      ..multiply(Matrix4.rotationZ(_radians90Left));

    scaleToFitViewport();
  }

  /// Rotate the image 90 degrees to the right (CW). Pan/translation is reset and image is scaled to fit the viewport.
  @action
  void rotate90Right() {
    // Cancel cropping if user decided to rotate while cropping.
    if (_selectedTool == Tool.crop) {
      cancelCrop();
    }

    // Rotate around 0,0 and adjust the rotated X origin left with respect to the full image height
    _physicalCropRotationMatrix = _physicalCropRotationMatrix.clone()
      ..translate(fullImageRotatedPhysicalHeight, 0.0)
      ..multiply(Matrix4.rotationZ(_radians90Right));

    scaleToFitViewport();
  }

  @action
  void startCrop() {
    // Reset any current crop
    _savedPhysicalNonRotatedCropRect = _physicalNonRotatedCropRect;
    clearCrop();

    // Zoom so full image fits viewport, and reset pan
    scaleToFitViewport();

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
    _physicalNonRotatedCropRect = _savedPhysicalNonRotatedCropRect;
    scaleToFitViewport();
    if (selectDefaultTool) {
      selectTool(Tool.select);
    }
  }

  @action
  void clearCrop() {
    _physicalNonRotatedCropRect = ui.Rect.fromLTWH(0, 0,
        _fullImageNonRotatedPhysicalWidth, _fullImageNonRotatedPhysicalHeight);
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
        viewportTransformationController.value, fullImageRotatedPhysicalRect);
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
    final physicalRotatedCropRect = MatrixUtils.transformRect(
        viewportTransformationController.value.clone()..invert(),
        _controlCropRect);
    _physicalNonRotatedCropRect = MatrixUtils.transformRect(
        _physicalCropRotationMatrix.clone()..invert(), physicalRotatedCropRect);
    selectTool(Tool.select, cancelCropping: false);
  }

  Future<ui.Image> getEditedUiImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _imagePainter.paint(canvas, Size.zero);
    return recorder.endRecording().toImage(
        physicalRotatedCropRect.width.floor(),
        physicalRotatedCropRect.height.floor());
  }

  @action
  void startDraw() {
    _viewportOverlays
      ..clear()
      ..add(_DrawControl(model: this as EditorModel));
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

class _DrawControl extends StatelessWidget {
  const _DrawControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return GestureDetector(
          onPanStart: (start) {
            model._activePath ??= Path();
            model._activePath!
                .moveTo(start.globalPosition.dx, start.globalPosition.dy);
            model.updateImage();
            debugPrint('onPanStart');
          },
          onPanEnd: (_) {
            debugPrint('onPanEnd');
          },
          onPanUpdate: (update) {
            model._activePath!
                .lineTo(update.globalPosition.dx, update.globalPosition.dy);
            model.updateImage();
            debugPrint('onPanUpdate');
          },
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
    // Difference doesn't seem to work on web with flutter 3.3.3 https://github.com/flutter/flutter/issues/44572#issuecomment-1079774078
    if (!kIsWeb) {
      canvas.drawPath(
          Path.combine(
              PathOperation.difference,
              Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
              Path()..addRect(cropRect)),
          transparentOverlayPaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawRect(cropRect, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ImagePainterWidget extends StatelessWidget {
  const _ImagePainterWidget({Key? key, required this.model}) : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        // Listen to the counter for updates
        model.imagePainterTrigger;
        debugPrint('updating');
        return CustomPaint(painter: model._imagePainter);
      },
    );
  }
}

class ImagePainter extends CustomPainter {
  ImagePainter(this._model);

  final EditorModel _model;

  @override
  void paint(Canvas canvas, Size size) {
    debugPrint('PAINT');
    canvas.save();
    canvas.translate(-_model.physicalRotatedCropRect.left,
        -_model.physicalRotatedCropRect.top);
    canvas.clipRect(_model.physicalRotatedCropRect);
    canvas.transform(_model.physicalCropRotationMatrix.storage);
    canvas.drawImage(
      _model.uiImage!,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );

    if (_model._activePath != null) {
      final pathPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(_model._activePath!, pathPaint);
    }

    canvas.restore();
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
