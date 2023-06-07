import 'dart:math';
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
  text(Icons.title),
  oval(Icons.circle_outlined),
  rectangle(Icons.rectangle_outlined),
  line(Icons.horizontal_rule),
  arrow(Icons.north_east);

  const Tool(this.icon);

  final IconData icon;
}

const _radians90Left = -pi / 2;
const _radians90Right = pi / 2;
const _arrowAngle = 25 * pi / 180; // 25 degrees

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

const availableFontSizes = [
  30.0,
  60.0,
  90.0,
  150.0,
  220.0,
];

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class EditorModel = EditorModelBase with _$EditorModel;

abstract class EditorModelBase with Store {
  EditorModelBase(
    Uint8List imageBytes, {
    double? fixedCropRatio,
    Tool? selectedTool,
    bool showCropCircle = false,
    this.viewOnly = false,
  }) {
    _fixedCropRatio = fixedCropRatio;
    _showCropCircle = showCropCircle;
    _selectedToolPendingViewport = selectedTool ?? Tool.select;
    _initialize(imageBytes);
  }

  final TransformationController viewportTransformationController =
      TransformationController();
  late final CustomPainter _imagePainter;
  late final Widget imagePainterWidget;
  late final Widget _selectedObjectControl;
  final bool viewOnly;

  @readonly
  ui.Image? _uiImage;

  @readonly
  double _fullImageNonRotatedPhysicalWidth = 0;

  @readonly
  double _fullImageNonRotatedPhysicalHeight = 0;

  @readonly
  double? _fixedCropRatio;

  @readonly
  bool _showCropCircle = false;

  ui.Rect get fullImageRotatedPhysicalRect => MatrixUtils.transformRect(
      _physicalCropRotationMatrix, _fullImageNonRotatedPhysicalRect);

  ui.Rect get _fullImageNonRotatedPhysicalRect {
    return Rect.fromLTWH(0, 0, _fullImageNonRotatedPhysicalWidth,
        _fullImageNonRotatedPhysicalHeight);
  }

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

  Tool? _selectedToolPendingViewport;

  final viewportOverlays = ObservableList<Widget>();

  /// A counter that can be observed to trigger a redraw of the viewport overlays.
  /// This can be used if the [viewportOverlays] list hasn't changed, but an overlay
  /// needs to be redrawn.
  @readonly
  // ignore: prefer_final_fields
  var _viewportOverlaysCounter = 0;

  @readonly
  double _zoomScale = 1;

  @readonly
  bool _initialized = false;

  @readonly
  var _brushSize = availableBrushSizes[availableBrushSizes.length ~/ 2];

  @readonly
  var _fontSize = availableFontSizes[availableFontSizes.length - 1];

  @readonly
  Color _drawingColor = availableColors[0];

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
      // _debugZoomControllerMatrix();
      if (_selectedTool == Tool.crop) {
        // debugPrint('Re-centering....');
        _centerCropRect();
      }
    });

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    _uiImage = frame.image;
    _fullImageNonRotatedPhysicalWidth = _uiImage!.width.toDouble();
    _fullImageNonRotatedPhysicalHeight = _uiImage!.height.toDouble();
    _physicalNonRotatedCropRect = ui.Rect.fromLTWH(0, 0,
        _fullImageNonRotatedPhysicalWidth, _fullImageNonRotatedPhysicalHeight);
    // debugPrint('initialized');
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
      // debugPrint('Setting viewport to $newViewPort');
      final firstTimeSettingViewport = _viewport == Rect.zero;
      _viewport = newViewPort;
      if (firstTimeSettingViewport) {
        scaleToFitViewport();
      }

      if (_selectedToolPendingViewport != null) {
        selectTool(_selectedToolPendingViewport!);
        _selectedToolPendingViewport = null;
      }
    }
  }

  // ignore: unused_element
  void _debugZoomControllerMatrix() {
    final translation = Vector3.zero();
    final rotation = Quaternion.identity();
    final scale = Vector3.zero();
    viewportTransformationController.value
        .decompose(translation, rotation, scale);
    debugPrint(
        'viewportTransformationController matrix: translation: (${translation.x}, ${translation.y}), '
        'scale: ${scale.x}');
  }

  bool isModified() {
    return !_physicalCropRotationMatrix.isIdentity() ||
        _physicalNonRotatedCropRect != _fullImageNonRotatedPhysicalRect ||
        _annotationObjects.isNotEmpty ||
        _workingAnnotationObjects.isNotEmpty;
  }

  @action
  void selectTool(Tool tool, {bool cancelCropping = true}) {
    // debugPrint('Selecting tool $tool');
    if (tool == _selectedTool) return;
    if (_viewport.isEmpty) {
      // Do it after viewport is set
      _selectedToolPendingViewport = tool;
      return;
    }

    if (viewOnly) {
      _selectedTool = Tool.select;
      return;
    }

    final lastTool = _selectedTool;
    _selectedTool = tool;
    if (cancelCropping && lastTool == Tool.crop) {
      cancelCrop(selectDefaultTool: false);
    }

    viewportOverlays.clear();
    switch (_selectedTool) {
      case Tool.select:
        break;

      case Tool.crop:
        startCrop();
        break;

      case Tool.draw:
        startFreeDrawing();
        break;

      case Tool.oval:
        startDrawingOval();
        break;

      case Tool.rectangle:
        startDrawingRect();
        break;

      case Tool.line:
        startDrawingLine();
        break;

      case Tool.arrow:
        startDrawingArrow();
        break;

      case Tool.text:
        startDrawingText();
        break;
    }
  }

  @action
  void setFixedCropRatio(double? ratio) {
    if (ratio != _fixedCropRatio) {
      _fixedCropRatio = ratio;
      _updateCropRect(_controlCropRect, _Corner.bottomRight);
    }
  }

  @action
  void setShowCropCircle(bool show) => _showCropCircle = show;

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
    // debugPrint('Scaling to fit viewport');
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
    // Clear crop which also zooms so full image fits viewport, and resets pan.
    clearCrop();

    _centerCropRect();

    viewportOverlays
      ..clear()
      ..add(_CropControl(model: this as EditorModel));
  }

  void _centerCropRect() {
    final imageViewportRect = viewportImageRect;
    final cropRatio = _fixedCropRatio;
    if (cropRatio == null) {
      final insetX = imageViewportRect.width * 0.05;
      final insetY = imageViewportRect.height * 0.05;
      _updateCropRect(
          ui.Rect.fromLTWH(
            imageViewportRect.left + insetX,
            imageViewportRect.top + insetY,
            imageViewportRect.width * 0.90,
            imageViewportRect.height * 0.90,
          ),
          _Corner.bottomRight);
    } else {
      var targetWidth = imageViewportRect.width * 0.90;
      var targetHeight = targetWidth / cropRatio;
      if (targetHeight > imageViewportRect.height) {
        targetHeight = imageViewportRect.height * 0.90;
        targetWidth = targetHeight * cropRatio;
      }

      assert(targetWidth <= imageViewportRect.width);
      assert(targetHeight <= imageViewportRect.height);

      // Center the crop rect.
      _updateCropRect(
          ui.Rect.fromLTWH(
              imageViewportRect.left +
                  (imageViewportRect.width - targetWidth) / 2,
              imageViewportRect.top +
                  (imageViewportRect.height - targetHeight) / 2,
              targetWidth,
              targetHeight),
          _Corner.topLeft);
    }
  }

  ui.Rect get viewportImageRect {
    return MatrixUtils.transformRect(
        viewportTransformationController.value, fullImageRotatedPhysicalRect);
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
  void dragCrop(DragUpdateDetails details) {
    final newRect = _controlCropRect.shift(details.delta);
    final imageViewportRect = viewportImageRect;
    if (imageViewportRect.intersect(newRect) != newRect) {
      // Proposed rect exceeds bounds, don't move it
      return;
    }

    _controlCropRect = newRect;
  }

  @action
  void updateCropTopLeft(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left + details.delta.dx,
        _controlCropRect.top + details.delta.dy,
        _controlCropRect.right,
        _controlCropRect.bottom);
    _updateCropRect(newRect, _Corner.topLeft);
  }

  void _updateCropRect(ui.Rect newRect, _Corner adjustingCorner) {
    var left = newRect.left;
    var right = newRect.right;
    var top = newRect.top;
    var bottom = newRect.bottom;
    if (left > right) {
      if (adjustingCorner == _Corner.bottomRight ||
          adjustingCorner == _Corner.topRight) {
        right = left;
      } else {
        left = right;
      }
    }
    if (top > bottom) {
      if (adjustingCorner == _Corner.bottomRight ||
          adjustingCorner == _Corner.bottomLeft) {
        bottom = top;
      } else {
        top = bottom;
      }
    }

    // Cannot be out of bounds of image.
    final imageViewportRect = viewportImageRect;

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

    final cropRatio = _fixedCropRatio;
    if (cropRatio != null) {
      var width = right - left;
      var height = bottom - top;
      final targetHeight = width / cropRatio;
      if ((height - targetHeight).abs() > 0.0001) {
        if (targetHeight > imageViewportRect.height) {
          // Adjust width because height would become too tall.
          final targetWidth = height * cropRatio;
          if (adjustingCorner == _Corner.bottomRight ||
              adjustingCorner == _Corner.topRight) {
            // Adjust right
            right = left + targetWidth;
          } else {
            //
            // _Corner.bottomLeft || _Corner.topLeft: Adjust left
            left = right - targetWidth;
          }
        } else {
          // Adjust height
          if (adjustingCorner == _Corner.bottomRight ||
              adjustingCorner == _Corner.bottomLeft) {
            // Adjust bottom
            bottom = top + targetHeight;
          } else {
            // _Corner.topRight || _Corner.topLeft: Adjust top
            top = bottom - targetHeight;
          }

          final proposedRect = Rect.fromLTRB(left, top, right, bottom);
          if (imageViewportRect.intersect(proposedRect) != proposedRect) {
            // Proposed rect exceeds bounds, don't change crop
            return;
          }
        }
      }
    }

    _controlCropRect = ui.Rect.fromLTRB(left, top, right, bottom);
  }

  @action
  void updateCropBottomLeft(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left + details.delta.dx,
        _controlCropRect.top,
        _controlCropRect.right,
        _controlCropRect.bottom + details.delta.dy);
    _updateCropRect(newRect, _Corner.bottomLeft);
  }

  @action
  void updateCropTopRight(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left,
        _controlCropRect.top + details.delta.dy,
        _controlCropRect.right + details.delta.dx,
        _controlCropRect.bottom);
    _updateCropRect(newRect, _Corner.topRight);
  }

  @action
  void updateCropBottomRight(DragUpdateDetails details) {
    final newRect = ui.Rect.fromLTRB(
        _controlCropRect.left,
        _controlCropRect.top,
        _controlCropRect.right + details.delta.dx,
        _controlCropRect.bottom + details.delta.dy);
    _updateCropRect(newRect, _Corner.bottomRight);
  }

  @action
  void applyCrop() {
    // debugPrint('Before: $_physicalCropRect control=$_controlCropRect');
    final physicalRotatedCropRect = MatrixUtils.transformRect(
        viewportTransformationController.value.clone()..invert(),
        _controlCropRect);
    _physicalNonRotatedCropRect = MatrixUtils.transformRect(
        _physicalCropRotationMatrix.clone()..invert(), physicalRotatedCropRect);
    scaleToFitViewport();
    selectTool(Tool.select, cancelCropping: false);
  }

  /// Gets the edited image. If drawing annotations is in progress, the current crop or working annotations
  /// are applied to the image. This way the user gets an image which reflects what they're seeing.
  Future<ui.Image> getEditedUiImage() async {
    if (_selectedTool == Tool.crop) {
      applyCrop();
    }

    if (_workingAnnotationObjects.isNotEmpty) {
      applyAnnotations();
    }

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
    viewportOverlays
      ..clear()
      ..add(_FreeDrawControl(model: this as EditorModel));
  }

  @action
  void applyAnnotations() {
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
  void discardAnnotations() {
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

  @action
  void setFontSize(double size) {
    _fontSize = size;
    updateImage();
  }

  @action
  void startDrawingOval() {
    _workingAnnotationObjects.clear();
    viewportOverlays
      ..clear()
      ..add(_OvalDrawControl(model: this as EditorModel));
  }

  @action
  void startDrawingRect() {
    _workingAnnotationObjects.clear();
    viewportOverlays
      ..clear()
      ..add(_RectDrawControl(model: this as EditorModel));
  }

  @action
  void startDrawingLine() {
    _workingAnnotationObjects.clear();
    viewportOverlays
      ..clear()
      ..add(_LineDrawControl(model: this as EditorModel));
  }

  @action
  void startDrawingArrow() {
    _workingAnnotationObjects.clear();
    viewportOverlays
      ..clear()
      ..add(_LineDrawControl(model: this as EditorModel, isArrow: true));
  }

  @action
  void startDrawingText() {
    _workingAnnotationObjects.clear();
    viewportOverlays
      ..clear()
      ..add(_TextDrawControl(model: this as EditorModel));
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
    viewportOverlays.clear();
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
      // debugPrint(
      //     'Selected annotation: ${_selectedAnnotationObject?.getBounds()}');
      viewportOverlays.add(_selectedObjectControl);
    } else {
      // debugPrint('No annotation found');
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

    // Cause the selector to be redrawn
    ++_viewportOverlaysCounter;
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

class _TextAnnotationObject extends _AnnotationObject {
  _TextAnnotationObject(
    this.position,
    String text,
    double fontSize,
    Color color,
    double maxWidth,
    this.rotation,
  ) {
    textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: ui.FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: maxWidth);
  }

  final Offset position;
  late final TextPainter textPainter;
  final double rotation;
  final _transformMatrix = Matrix4.identity();

  @override
  void paint(Canvas canvas) {
    canvas.save();
    canvas.transform(_transformMatrix.storage);
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);
    canvas.translate(-position.dx, -position.dy);
    textPainter.paint(canvas, position);
    canvas.restore();
  }

  @override
  ui.Rect getBounds() {
    return MatrixUtils.transformRect(
        _transformMatrix.clone()
          ..translate(position.dx, position.dy)
          ..rotateZ(rotation)
          ..translate(-position.dx, -position.dy),
        Rect.fromLTWH(
            position.dx, position.dy, textPainter.width, textPainter.height));
  }

  @override
  void transform(Matrix4 m) => _transformMatrix.multiply(m);
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
          model.viewportOverlaysCounter; // observe

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
        const controlWH = 20.0;
        const halfControlWH = controlWH / 2;
        final controlCorner = Container(
          decoration:
              const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          width: controlWH,
          height: controlWH,
        );
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
            // Inside crop can be dragged
            Positioned(
              left: cropRect.left,
              top: cropRect.top,
              right: model.viewport.right - cropRect.right,
              bottom: model.viewport.bottom - cropRect.bottom,
              child: GestureDetector(
                onPanUpdate: (details) => model.dragCrop(details),
                behavior: HitTestBehavior.opaque,
                child: model.showCropCircle
                    ? Container(
                        decoration: ShapeDecoration(
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.70),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
            // upper left
            Positioned(
              left: cropRect.left - halfControlWH,
              top: cropRect.top - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropTopLeft(details),
                child: controlCorner,
              ),
            ),
            // upper right
            Positioned(
              left: cropRect.right - halfControlWH,
              top: cropRect.top - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropTopRight(details),
                child: controlCorner,
              ),
            ),
            // lower left
            Positioned(
              left: cropRect.left - halfControlWH,
              bottom: (model.viewport.bottom - cropRect.bottom) - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropBottomLeft(details),
                child: controlCorner,
              ),
            ),
            // lower right
            Positioned(
              left: cropRect.right - halfControlWH,
              bottom: (model.viewport.bottom - cropRect.bottom) - halfControlWH,
              child: GestureDetector(
                onPanUpdate: (details) => model.updateCropBottomRight(details),
                child: controlCorner,
              ),
            ),
          ],
        );
      },
    );
  }
}

abstract class _PathDrawControl extends StatelessWidget {
  _PathDrawControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;
  final _painterNotifier = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onPanStart: onDrawStart,
        onPanUpdate: onDrawUpdate,
        child: CustomPaint(
          // TODO I can't explain why, but this do-nothing painter is required to get the image to update while drawing.
          //  It may be because it repaints on the _painterNotifier change, but not sure.
          //  Also, just calling model.updateImage() in onPanUpdate doesn't cause the drawing to repaint until
          //  the pointer moves out of the window, or over a button.
          painter: _StubPainter(_painterNotifier),
        ),
      ),
    );
  }

  void _repaintDrawing() => _painterNotifier.value = !_painterNotifier.value;

  void onDrawStart(DragStartDetails start);

  void onDrawUpdate(DragUpdateDetails update);
}

class _FreeDrawControl extends _PathDrawControl {
  _FreeDrawControl({Key? key, required EditorModel model})
      : super(key: key, model: model);

  @override
  void onDrawStart(DragStartDetails start) {
    final path = Path();
    final pathObj = _PathAnnotationObject(path, model._createPathPaint());
    model._workingAnnotationObjects.add(pathObj);
    final pt =
        model._transformViewportPointToPhysicalImagePoint(start.localPosition);
    path.moveTo(pt.dx, pt.dy);
    _repaintDrawing();
  }

  @override
  void onDrawUpdate(DragUpdateDetails update) {
    final path =
        (model._workingAnnotationObjects.last as _PathAnnotationObject).path;
    final pt =
        model._transformViewportPointToPhysicalImagePoint(update.localPosition);
    path.lineTo(pt.dx, pt.dy);
    _repaintDrawing();
  }
}

class _OvalDrawControl extends _PathDrawControl {
  _OvalDrawControl({Key? key, required EditorModel model})
      : super(key: key, model: model);

  final _startPt = _ValueHolder(Offset.zero);

  @override
  void onDrawStart(DragStartDetails start) {
    model._workingAnnotationObjects
        .add(_PathAnnotationObject(Path(), model._createPathPaint()));
    _startPt.value =
        model._transformViewportPointToPhysicalImagePoint(start.localPosition);
  }

  @override
  void onDrawUpdate(DragUpdateDetails update) {
    final pathObj =
        model._workingAnnotationObjects.last as _PathAnnotationObject;
    final lowerRightPt =
        model._transformViewportPointToPhysicalImagePoint(update.localPosition);
    pathObj.path = Path()
      ..addOval(Rect.fromLTRB(_startPt.value.dx, _startPt.value.dy,
          lowerRightPt.dx, lowerRightPt.dy));
    _repaintDrawing();
  }
}

class _RectDrawControl extends _PathDrawControl {
  _RectDrawControl({Key? key, required EditorModel model})
      : super(key: key, model: model);

  final _startPt = _ValueHolder(Offset.zero);

  @override
  void onDrawStart(DragStartDetails start) {
    model._workingAnnotationObjects
        .add(_PathAnnotationObject(Path(), model._createPathPaint()));
    _startPt.value =
        model._transformViewportPointToPhysicalImagePoint(start.localPosition);
  }

  @override
  void onDrawUpdate(DragUpdateDetails update) {
    final pathObj =
        model._workingAnnotationObjects.last as _PathAnnotationObject;
    final lowerRightPt =
        model._transformViewportPointToPhysicalImagePoint(update.localPosition);
    pathObj.path = Path()
      ..addRect(Rect.fromLTRB(_startPt.value.dx, _startPt.value.dy,
          lowerRightPt.dx, lowerRightPt.dy));
    _repaintDrawing();
  }
}

class _LineDrawControl extends _PathDrawControl {
  _LineDrawControl({Key? key, required EditorModel model, this.isArrow = false})
      : super(key: key, model: model);

  final _startPt = _ValueHolder(Offset.zero);
  final bool isArrow;

  @override
  void onDrawStart(DragStartDetails start) {
    model._workingAnnotationObjects
        .add(_PathAnnotationObject(Path(), model._createPathPaint()));
    _startPt.value =
        model._transformViewportPointToPhysicalImagePoint(start.localPosition);
  }

  @override
  void onDrawUpdate(DragUpdateDetails update) {
    final pathObj =
        model._workingAnnotationObjects.last as _PathAnnotationObject;
    final endPt =
        model._transformViewportPointToPhysicalImagePoint(update.localPosition);
    pathObj.path = Path()
      ..moveTo(_startPt.value.dx, _startPt.value.dy)
      ..lineTo(endPt.dx, endPt.dy);
    if (isArrow) {
      final delta = endPt - _startPt.value;
      final angle = atan2(delta.dy, delta.dx);
      final arrowSize = 15.0 * (model.brushSize / 5.0);
      pathObj.path
        ..moveTo(endPt.dx - arrowSize * cos(angle - _arrowAngle),
            endPt.dy - arrowSize * sin(angle - _arrowAngle))
        ..lineTo(endPt.dx, endPt.dy)
        ..lineTo(endPt.dx - arrowSize * cos(angle + _arrowAngle),
            endPt.dy - arrowSize * sin(angle + _arrowAngle))
        ..close();
    }

    _repaintDrawing();
  }
}

class _TextDrawControl extends StatelessWidget {
  const _TextDrawControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (tapDown) => _promptForText(context, tapDown),
      ),
    );
  }

  Future<void> _promptForText(
      BuildContext context, TapDownDetails tapDown) async {
    final text = _ValueHolder('');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter text'),
          content: SizedBox(
            width: 360,
            child: TextField(
              autofocus: true,
              onChanged: (value) => text.value = value,
              maxLines: 3,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context, null),
            ),
            TextButton(
              child: const Text('Ok'),
              onPressed: () => Navigator.pop(context, text.value),
            ),
          ],
        );
      },
    );

    if (result != null) {
      final phyPt = model
          ._transformViewportPointToPhysicalImagePoint(tapDown.localPosition);
      final rotationQ = Quaternion.identity();
      model.physicalCropRotationMatrix
          .decompose(Vector3.zero(), rotationQ, Vector3.zero());
      // Radians is the same value when rotated 90 or 270, so you have to multiple by the Z sign.
      final rotation = rotationQ.radians * -(rotationQ.z.sign);

      model._workingAnnotationObjects.add(_TextAnnotationObject(
        phyPt,
        result,
        model.fontSize,
        model.drawingColor,
        model.physicalRotatedCropRect.width,
        rotation,
      ));
      model.updateImage();
    }
  }
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

class _ValueHolder<T> {
  _ValueHolder(this.value);

  T value;
}
