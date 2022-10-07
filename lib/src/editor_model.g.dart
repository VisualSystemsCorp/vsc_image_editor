// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_model.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic, no_leading_underscores_for_local_identifiers

mixin _$EditorModel on EditorModelBase, Store {
  late final _$_uiImageAtom =
      Atom(name: 'EditorModelBase._uiImage', context: context);

  ui.Image? get uiImage {
    _$_uiImageAtom.reportRead();
    return super._uiImage;
  }

  @override
  ui.Image? get _uiImage => uiImage;

  @override
  set _uiImage(ui.Image? value) {
    _$_uiImageAtom.reportWrite(value, super._uiImage, () {
      super._uiImage = value;
    });
  }

  late final _$_fullImageNonRotatedPhysicalWidthAtom = Atom(
      name: 'EditorModelBase._fullImageNonRotatedPhysicalWidth',
      context: context);

  double get fullImageNonRotatedPhysicalWidth {
    _$_fullImageNonRotatedPhysicalWidthAtom.reportRead();
    return super._fullImageNonRotatedPhysicalWidth;
  }

  @override
  double get _fullImageNonRotatedPhysicalWidth =>
      fullImageNonRotatedPhysicalWidth;

  @override
  set _fullImageNonRotatedPhysicalWidth(double value) {
    _$_fullImageNonRotatedPhysicalWidthAtom
        .reportWrite(value, super._fullImageNonRotatedPhysicalWidth, () {
      super._fullImageNonRotatedPhysicalWidth = value;
    });
  }

  late final _$_fullImageNonRotatedPhysicalHeightAtom = Atom(
      name: 'EditorModelBase._fullImageNonRotatedPhysicalHeight',
      context: context);

  double get fullImageNonRotatedPhysicalHeight {
    _$_fullImageNonRotatedPhysicalHeightAtom.reportRead();
    return super._fullImageNonRotatedPhysicalHeight;
  }

  @override
  double get _fullImageNonRotatedPhysicalHeight =>
      fullImageNonRotatedPhysicalHeight;

  @override
  set _fullImageNonRotatedPhysicalHeight(double value) {
    _$_fullImageNonRotatedPhysicalHeightAtom
        .reportWrite(value, super._fullImageNonRotatedPhysicalHeight, () {
      super._fullImageNonRotatedPhysicalHeight = value;
    });
  }

  late final _$_fixedCropRatioAtom =
      Atom(name: 'EditorModelBase._fixedCropRatio', context: context);

  double? get fixedCropRatio {
    _$_fixedCropRatioAtom.reportRead();
    return super._fixedCropRatio;
  }

  @override
  double? get _fixedCropRatio => fixedCropRatio;

  @override
  set _fixedCropRatio(double? value) {
    _$_fixedCropRatioAtom.reportWrite(value, super._fixedCropRatio, () {
      super._fixedCropRatio = value;
    });
  }

  late final _$_physicalNonRotatedCropRectAtom = Atom(
      name: 'EditorModelBase._physicalNonRotatedCropRect', context: context);

  Rect get physicalNonRotatedCropRect {
    _$_physicalNonRotatedCropRectAtom.reportRead();
    return super._physicalNonRotatedCropRect;
  }

  @override
  Rect get _physicalNonRotatedCropRect => physicalNonRotatedCropRect;

  @override
  set _physicalNonRotatedCropRect(Rect value) {
    _$_physicalNonRotatedCropRectAtom
        .reportWrite(value, super._physicalNonRotatedCropRect, () {
      super._physicalNonRotatedCropRect = value;
    });
  }

  late final _$_viewportAtom =
      Atom(name: 'EditorModelBase._viewport', context: context);

  Rect get viewport {
    _$_viewportAtom.reportRead();
    return super._viewport;
  }

  @override
  Rect get _viewport => viewport;

  @override
  set _viewport(Rect value) {
    _$_viewportAtom.reportWrite(value, super._viewport, () {
      super._viewport = value;
    });
  }

  late final _$_physicalCropRotationMatrixAtom = Atom(
      name: 'EditorModelBase._physicalCropRotationMatrix', context: context);

  Matrix4 get physicalCropRotationMatrix {
    _$_physicalCropRotationMatrixAtom.reportRead();
    return super._physicalCropRotationMatrix;
  }

  @override
  Matrix4 get _physicalCropRotationMatrix => physicalCropRotationMatrix;

  @override
  set _physicalCropRotationMatrix(Matrix4 value) {
    _$_physicalCropRotationMatrixAtom
        .reportWrite(value, super._physicalCropRotationMatrix, () {
      super._physicalCropRotationMatrix = value;
    });
  }

  late final _$_controlCropRectAtom =
      Atom(name: 'EditorModelBase._controlCropRect', context: context);

  Rect get controlCropRect {
    _$_controlCropRectAtom.reportRead();
    return super._controlCropRect;
  }

  @override
  Rect get _controlCropRect => controlCropRect;

  @override
  set _controlCropRect(Rect value) {
    _$_controlCropRectAtom.reportWrite(value, super._controlCropRect, () {
      super._controlCropRect = value;
    });
  }

  late final _$_selectedToolAtom =
      Atom(name: 'EditorModelBase._selectedTool', context: context);

  Tool get selectedTool {
    _$_selectedToolAtom.reportRead();
    return super._selectedTool;
  }

  @override
  Tool get _selectedTool => selectedTool;

  @override
  set _selectedTool(Tool value) {
    _$_selectedToolAtom.reportWrite(value, super._selectedTool, () {
      super._selectedTool = value;
    });
  }

  late final _$_viewportOverlaysAtom =
      Atom(name: 'EditorModelBase._viewportOverlays', context: context);

  ObservableList<Widget> get viewportOverlays {
    _$_viewportOverlaysAtom.reportRead();
    return super._viewportOverlays;
  }

  @override
  ObservableList<Widget> get _viewportOverlays => viewportOverlays;

  @override
  set _viewportOverlays(ObservableList<Widget> value) {
    _$_viewportOverlaysAtom.reportWrite(value, super._viewportOverlays, () {
      super._viewportOverlays = value;
    });
  }

  late final _$_zoomScaleAtom =
      Atom(name: 'EditorModelBase._zoomScale', context: context);

  double get zoomScale {
    _$_zoomScaleAtom.reportRead();
    return super._zoomScale;
  }

  @override
  double get _zoomScale => zoomScale;

  @override
  set _zoomScale(double value) {
    _$_zoomScaleAtom.reportWrite(value, super._zoomScale, () {
      super._zoomScale = value;
    });
  }

  late final _$_initializedAtom =
      Atom(name: 'EditorModelBase._initialized', context: context);

  bool get initialized {
    _$_initializedAtom.reportRead();
    return super._initialized;
  }

  @override
  bool get _initialized => initialized;

  @override
  set _initialized(bool value) {
    _$_initializedAtom.reportWrite(value, super._initialized, () {
      super._initialized = value;
    });
  }

  late final _$_brushSizeAtom =
      Atom(name: 'EditorModelBase._brushSize', context: context);

  double get brushSize {
    _$_brushSizeAtom.reportRead();
    return super._brushSize;
  }

  @override
  double get _brushSize => brushSize;

  @override
  set _brushSize(double value) {
    _$_brushSizeAtom.reportWrite(value, super._brushSize, () {
      super._brushSize = value;
    });
  }

  late final _$_fontSizeAtom =
      Atom(name: 'EditorModelBase._fontSize', context: context);

  double get fontSize {
    _$_fontSizeAtom.reportRead();
    return super._fontSize;
  }

  @override
  double get _fontSize => fontSize;

  @override
  set _fontSize(double value) {
    _$_fontSizeAtom.reportWrite(value, super._fontSize, () {
      super._fontSize = value;
    });
  }

  late final _$_drawingColorAtom =
      Atom(name: 'EditorModelBase._drawingColor', context: context);

  Color get drawingColor {
    _$_drawingColorAtom.reportRead();
    return super._drawingColor;
  }

  @override
  Color get _drawingColor => drawingColor;

  @override
  set _drawingColor(Color value) {
    _$_drawingColorAtom.reportWrite(value, super._drawingColor, () {
      super._drawingColor = value;
    });
  }

  late final _$_selectedAnnotationObjectAtom =
      Atom(name: 'EditorModelBase._selectedAnnotationObject', context: context);

  _AnnotationObject? get selectedAnnotationObject {
    _$_selectedAnnotationObjectAtom.reportRead();
    return super._selectedAnnotationObject;
  }

  @override
  _AnnotationObject? get _selectedAnnotationObject => selectedAnnotationObject;

  @override
  set _selectedAnnotationObject(_AnnotationObject? value) {
    _$_selectedAnnotationObjectAtom
        .reportWrite(value, super._selectedAnnotationObject, () {
      super._selectedAnnotationObject = value;
    });
  }

  late final _$_viewportTransformationMatrixAtom = Atom(
      name: 'EditorModelBase._viewportTransformationMatrix', context: context);

  Matrix4 get viewportTransformationMatrix {
    _$_viewportTransformationMatrixAtom.reportRead();
    return super._viewportTransformationMatrix;
  }

  @override
  Matrix4 get _viewportTransformationMatrix => viewportTransformationMatrix;

  @override
  set _viewportTransformationMatrix(Matrix4 value) {
    _$_viewportTransformationMatrixAtom
        .reportWrite(value, super._viewportTransformationMatrix, () {
      super._viewportTransformationMatrix = value;
    });
  }

  late final _$_initializeAsyncAction =
      AsyncAction('EditorModelBase._initialize', context: context);

  @override
  Future<void> _initialize(Uint8List imageBytes, double? fixedCropRatio) {
    return _$_initializeAsyncAction
        .run(() => super._initialize(imageBytes, fixedCropRatio));
  }

  late final _$EditorModelBaseActionController =
      ActionController(name: 'EditorModelBase', context: context);

  @override
  void setViewportSize(double width, double height) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setViewportSize');
    try {
      return super.setViewportSize(width, height);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void selectTool(Tool tool, {bool cancelCropping = true}) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.selectTool');
    try {
      return super.selectTool(tool, cancelCropping: cancelCropping);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFixedCropRatio(double? ratio) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setFixedCropRatio');
    try {
      return super.setFixedCropRatio(ratio);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setScale(double scale) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setScale');
    try {
      return super.setScale(scale);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void scaleToFitViewport() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.scaleToFitViewport');
    try {
      return super.scaleToFitViewport();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void rotate90Left() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.rotate90Left');
    try {
      return super.rotate90Left();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void rotate90Right() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.rotate90Right');
    try {
      return super.rotate90Right();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startCrop() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startCrop');
    try {
      return super.startCrop();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void cancelCrop({bool selectDefaultTool = true}) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.cancelCrop');
    try {
      return super.cancelCrop(selectDefaultTool: selectDefaultTool);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void clearCrop() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.clearCrop');
    try {
      return super.clearCrop();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void dragCrop(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.dragCrop');
    try {
      return super.dragCrop(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropTopLeft(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropTopLeft');
    try {
      return super.updateCropTopLeft(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropBottomLeft(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropBottomLeft');
    try {
      return super.updateCropBottomLeft(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropTopRight(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropTopRight');
    try {
      return super.updateCropTopRight(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropBottomRight(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropBottomRight');
    try {
      return super.updateCropBottomRight(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyCrop() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.applyCrop');
    try {
      return super.applyCrop();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startFreeDrawing() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startFreeDrawing');
    try {
      return super.startFreeDrawing();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void applyAnnotations() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.applyAnnotations');
    try {
      return super.applyAnnotations();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void undoLastWorkingAnnotation() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.undoLastWorkingAnnotation');
    try {
      return super.undoLastWorkingAnnotation();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void discardAnnotations() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.discardAnnotations');
    try {
      return super.discardAnnotations();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setBrushSize(double size) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setBrushSize');
    try {
      return super.setBrushSize(size);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setDrawingColor(Color color) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setDrawingColor');
    try {
      return super.setDrawingColor(color);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setFontSize(double size) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.setFontSize');
    try {
      return super.setFontSize(size);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDrawingOval() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDrawingOval');
    try {
      return super.startDrawingOval();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDrawingRect() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDrawingRect');
    try {
      return super.startDrawingRect();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDrawingLine() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDrawingLine');
    try {
      return super.startDrawingLine();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDrawingArrow() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDrawingArrow');
    try {
      return super.startDrawingArrow();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void startDrawingText() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDrawingText');
    try {
      return super.startDrawingText();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void maybeSelectAnnotationAt(Offset viewportPoint) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.maybeSelectAnnotationAt');
    try {
      return super.maybeSelectAnnotationAt(viewportPoint);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void moveSelectedObject(Offset viewportDelta) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.moveSelectedObject');
    try {
      return super.moveSelectedObject(viewportDelta);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void removeSelectedObject() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.removeSelectedObject');
    try {
      return super.removeSelectedObject();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''

    ''';
  }
}
