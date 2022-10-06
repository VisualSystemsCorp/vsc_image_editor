import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TransformationController;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart' hide Listenable;
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

const availableBrushSizes = [
  5.0,
  10.0,
  20.0,
  30.0,
  40.0,
];
const availableColors = [
  Colors.yellow,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.purple,
  Colors.white,
  Colors.black,
];

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {
  EditorModelBase(Uint8List imageBytes) {
    _initialize(imageBytes);
  }

  final TransformationController viewportTransformationController =
      TransformationController();
  late final CustomPainter _imagePainter;
  late final Widget imagePainterWidget;
  late final Widget _selectedObjectControl;

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

  @readonly
  var _brushSize = 10.0;

  @readonly
  Color _drawingColor = Colors.yellow;

  @readonly
  _AnnotationObject? _selectedAnnotationObject;

  @readonly
  var _viewportTransformationMatrix = Matrix4.identity();

  final _workingAnnotationObjects = <_AnnotationObject>[];

  final _annotationObjects = <_AnnotationObject>[];

  final _imagePainterNotifier = ValueNotifier<bool>(false);

  @action
  Future<void> _initialize(Uint8List imageBytes) async {
    _imagePainter = _ImagePainter(this as EditorModel, _imagePainterNotifier);
    imagePainterWidget = _ImagePainterWidget(model: this as EditorModel);
    _selectedObjectControl = _SelectedObjectControl(model: this as EditorModel);

    viewportTransformationController.addListener(() {
      _zoomScale = viewportTransformationController.value.getMaxScaleOnAxis();
      _viewportTransformationMatrix = viewportTransformationController.value;
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

  void updateImage() =>
      _imagePainterNotifier.value = !_imagePainterNotifier.value;

  @action
  void setViewportSize(double width, double height) {
    final newViewPort =
        ui.Rect.fromLTWH(_viewport.left, _viewport.top, width, height);
    if (newViewPort != _viewport) {
      _viewport = newViewPort;
      // debugPrint('viewport updated $_viewport');
    }
  }

  @action
  void selectTool(Tool tool, {bool cancelCropping = true}) {
    if (tool == _selectedTool) return;

    final lastTool = _selectedTool;
    _selectedTool = tool;
    if (cancelCropping && lastTool == Tool.crop) {
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
        startFreeDrawing();
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
    scaleToFitViewport();
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
    final picture = recorder.endRecording();
    final image = picture.toImage(physicalRotatedCropRect.width.floor(),
        physicalRotatedCropRect.height.floor());
    picture.dispose();
    return image;
  }

  @action
  void startFreeDrawing() {
    _workingAnnotationObjects.clear();
    _viewportOverlays
      ..clear()
      ..add(_FreeDrawControl(model: this as EditorModel));
  }

  @action
  void applyDrawing() {
    final nonEmptyObjects = _workingAnnotationObjects
        .where((anno) => !anno.getBounds().isEmpty)
        .toList(growable: false);
    if (nonEmptyObjects.isNotEmpty) {
      _annotationObjects.addAll(nonEmptyObjects);
    }

    _workingAnnotationObjects.clear();
    selectTool(Tool.select);
  }

  @action
  void undoLastWorkingAnnotation() {
    if (_workingAnnotationObjects.isNotEmpty) {
      _workingAnnotationObjects.removeLast();
    }
  }

  @action
  void discardDrawing() {
    _workingAnnotationObjects.clear();
    selectTool(Tool.select);
  }

  Paint _createPathPaint() {
    return Paint()
      ..color = _drawingColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _brushSize
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  @action
  void setBrushSize(double size) {
    _brushSize = size;
    updateImage();
  }

  @action
  void setDrawingColor(Color color) {
    _drawingColor = color;
    updateImage();
  }

  Offset _transformViewportPointToPhysicalImagePoint(Offset pt) {
    // This matrix goes from viewport coordinates to full-image coordinates
    final inverseViewportM = _viewportTransformationMatrix.clone()..invert();
    final physicalCroppedRotatedPt =
        MatrixUtils.transformPoint(inverseViewportM, pt);

    // Uncrop the point (untranslate by the rotated crop offset)
    final physicalRotatedPt =
        physicalCroppedRotatedPt + physicalRotatedCropRect.topLeft;

    // Unrotate the point
    final physicalRawPt = MatrixUtils.transformPoint(
        _physicalCropRotationMatrix.clone()..invert(), physicalRotatedPt);

    return physicalRawPt;
  }

  Rect _transformPhysicalImageRectToViewportRect(Rect physicalRawRect) {
    // Rotate
    final physicalRotatedRect =
        MatrixUtils.transformRect(_physicalCropRotationMatrix, physicalRawRect);

    // Crop
    final physicalCroppedRotatedRect = physicalRotatedRect
        .intersect(physicalRotatedCropRect)
        .translate(-physicalRotatedCropRect.left, -physicalRotatedCropRect.top);

    // Convert to the viewport pan/scale
    final viewportRect = MatrixUtils.transformRect(
        _viewportTransformationMatrix, physicalCroppedRotatedRect);

    return viewportRect;
  }

  @action
  void maybeSelectAnnotationAt(Offset viewportPoint) {
    _selectedAnnotationObject = null;
    _viewportOverlays.clear();
    final physicalPt =
        _transformViewportPointToPhysicalImagePoint(viewportPoint);
    for (final annotation in _annotationObjects.reversed) {
      final bounds = annotation.getBounds();
      if (bounds.contains(physicalPt)) {
        _selectedAnnotationObject = annotation;
      } else {
        // Search around the hit point in a 10x10 pixel area.
        for (var x = -5.0; x <= 5.0; x++) {
          for (var y = -5.0; y <= 5.0; y++) {
            if (bounds.contains(physicalPt + Offset(x, y))) {
              _selectedAnnotationObject = annotation;
              break;
            }
          }
        }
      }

      if (_selectedAnnotationObject != null) {
        break;
      }
    }

    if (_selectedAnnotationObject != null) {
      debugPrint('Adding selected object control');
      _viewportOverlays.add(_selectedObjectControl);
    }
  }

  @action
  void moveSelectedObject(Offset viewportDelta) {
    final selectedObject = _selectedAnnotationObject;
    if (selectedObject == null) return;

    final phyCurrTopLeft = selectedObject.getBounds().topLeft;
    final vpCurrTopLeft = _transformPhysicalImageRectToViewportRect(
            Rect.fromLTWH(phyCurrTopLeft.dx, phyCurrTopLeft.dy, 1, 1))
        .topLeft;
    final phyNewTopLeft = _transformViewportPointToPhysicalImagePoint(
        vpCurrTopLeft + viewportDelta);
    final phyDelta = phyNewTopLeft - phyCurrTopLeft;
    // debugPrint(
    //     'phyDelta=$phyDelta phyCurrTopLeft=$phyCurrTopLeft vpCurrTopLeft=$vpCurrTopLeft');
    selectedObject
        .transform(Matrix4.translationValues(phyDelta.dx, phyDelta.dy, 0.0));
    // Cause the selector to update
    _selectedAnnotationObject = selectedObject;
    updateImage();
  }

  @action
  void removeSelectedObject() {
    final selectedObject = _selectedAnnotationObject;
    if (selectedObject == null) return;

    _annotationObjects.remove(_selectedAnnotationObject);
    _selectedAnnotationObject = null;
  }
}

abstract class _AnnotationObject {
  void paint(Canvas canvas);

  Rect getBounds();

  void transform(Matrix4 m);
}

class _PathAnnotationObject extends _AnnotationObject {
  _PathAnnotationObject(this.path, this._paint);

  Path path;
  final Paint _paint;

  @override
  void paint(Canvas canvas) {
    canvas.drawPath(path, _paint);
  }

  @override
  ui.Rect getBounds() => path.getBounds();

  @override
  void transform(Matrix4 m) {
    path = path.transform(m.storage);
  }
}

class _SelectedObjectControl extends StatelessWidget {
  const _SelectedObjectControl({Key? key, required this.model})
      : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (model.selectedAnnotationObject != null) {
          final bounds = model.selectedAnnotationObject!.getBounds();
          final vpBounds =
              model._transformPhysicalImageRectToViewportRect(bounds);
          return Positioned(
            left: vpBounds.left - 22,
            top: vpBounds.top - 22,
            child: GestureDetector(
              onPanUpdate: (p) {
                model.moveSelectedObject(p.delta);
              },
              child: Stack(
                children: [
                  Positioned(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(width: 3, color: Colors.white),
                        boxShadow: const [
                          BoxShadow(blurRadius: 10, blurStyle: BlurStyle.outer),
                        ],
                      ),
                      width: vpBounds.width + 28,
                      height: vpBounds.height + 28,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => model.removeSelectedObject(),
                      child: Tooltip(
                        message: 'Remove',
                        child: Container(
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(
                            Icons.clear,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
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
          ],
        );
      },
    );
  }
}

class _FreeDrawControl extends StatelessWidget {
  _FreeDrawControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;
  final _painterNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return SizedBox(
          width: model.physicalRotatedCropRect.width,
          height: model.physicalRotatedCropRect.height,
          child: GestureDetector(
            onPanStart: (start) {
              final path = Path();
              final pathObj =
                  _PathAnnotationObject(path, model._createPathPaint());
              model._workingAnnotationObjects.add(pathObj);
              final pt = model._transformViewportPointToPhysicalImagePoint(
                  start.localPosition);
              path.moveTo(pt.dx, pt.dy);
              _repaintDrawing();
            },
            onPanEnd: (_) {},
            onPanUpdate: (update) {
              // debugPrint('onDrawUpdate');
              final path = (model._workingAnnotationObjects.last
                      as _PathAnnotationObject)
                  .path;
              final pt = model._transformViewportPointToPhysicalImagePoint(
                  update.localPosition);
              path.lineTo(pt.dx, pt.dy);
              _repaintDrawing();
            },
            child: CustomPaint(
              // TODO I can't explain why, but this do-nothing painter is required to get the image to update while drawing.
              //  It may be because it repaints on the _painterNotifier change, but not sure.
              //  Also, just calling model.updateImage() in onPanUpdate doesn't cause the drawing to repaint until
              //  the pointer moves out of the window, or over a button.
              painter: _StubPainter(_painterNotifier),
            ),
          ),
        );
      },
    );
  }

  void _repaintDrawing() => _painterNotifier.value = !_painterNotifier.value;
}

class _StubPainter extends CustomPainter {
  _StubPainter(Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CropScrimPainter extends CustomPainter {
  _CropScrimPainter(this.cropRect);

  ui.Rect cropRect;

  @override
  void paint(Canvas canvas, Size size) {
    final transparentOverlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // Difference doesn't seem to work on web with flutter 3.3.3, see:
    // https://github.com/flutter/flutter/issues/44572#issuecomment-1079774078
    // So we just draw four rects instead.
    // canvas.drawPath(
    //     Path.combine(
    //         PathOperation.difference,
    //         Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
    //         Path()..addRect(cropRect)),
    //     transparentOverlayPaint);

    // Top rect
    canvas.drawRect(
        Rect.fromLTRB(0, 0, size.width, cropRect.top), transparentOverlayPaint);
    // Left rect
    canvas.drawRect(
        Rect.fromLTRB(0, cropRect.top, cropRect.left, cropRect.bottom),
        transparentOverlayPaint);
    // Right rect
    canvas.drawRect(
        Rect.fromLTRB(
            cropRect.right, cropRect.top, size.width, cropRect.bottom),
        transparentOverlayPaint);
    // Bottom rect
    canvas.drawRect(Rect.fromLTRB(0, cropRect.bottom, size.width, size.height),
        transparentOverlayPaint);

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
    return Observer(builder: (context) {
      return CustomPaint(
        size: model.physicalRotatedCropRect.size,
        foregroundPainter: model._imagePainter,
        willChange: true,
        isComplex: true,
      );
    });
  }
}

abstract class _ViewportPainter extends CustomPainter {
  _ViewportPainter(this._model, Listenable repaint) : super(repaint: repaint);

  final EditorModel _model;

  void paintTransformed(Canvas canvas, Size size);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(-_model.physicalRotatedCropRect.left,
        -_model.physicalRotatedCropRect.top);
    canvas.clipRect(_model.physicalRotatedCropRect);
    canvas.transform(_model.physicalCropRotationMatrix.storage);

    paintTransformed(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) => false;
}

class _ImagePainter extends _ViewportPainter {
  _ImagePainter(EditorModel model, Listenable repaint) : super(model, repaint);

  @override
  void paintTransformed(Canvas canvas, Size size) {
    canvas.drawImage(
      _model.uiImage!,
      Offset.zero,
      Paint()..filterQuality = FilterQuality.medium,
    );

    for (final annotation in _model._annotationObjects) {
      annotation.paint(canvas);
    }

    for (final annotation in _model._workingAnnotationObjects) {
      annotation.paint(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant _ImagePainter oldDelegate) => false;
}
