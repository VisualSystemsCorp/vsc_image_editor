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

  late final _$_imagePainterTriggerAtom =
      Atom(name: 'EditorModelBase._imagePainterTrigger', context: context);

  bool get imagePainterTrigger {
    _$_imagePainterTriggerAtom.reportRead();
    return super._imagePainterTrigger;
  }

  @override
  bool get _imagePainterTrigger => imagePainterTrigger;

  @override
  set _imagePainterTrigger(bool value) {
    _$_imagePainterTriggerAtom.reportWrite(value, super._imagePainterTrigger,
        () {
      super._imagePainterTrigger = value;
    });
  }

  late final _$_initializeAsyncAction =
      AsyncAction('EditorModelBase._initialize', context: context);

  @override
  Future<void> _initialize(Uint8List imageBytes) {
    return _$_initializeAsyncAction.run(() => super._initialize(imageBytes));
  }

  late final _$EditorModelBaseActionController =
      ActionController(name: 'EditorModelBase', context: context);

  @override
  void updateImage() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateImage');
    try {
      return super.updateImage();
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

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
  void updateCropLeftTop(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropLeftTop');
    try {
      return super.updateCropLeftTop(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropLeftBottom(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropLeftBottom');
    try {
      return super.updateCropLeftBottom(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropRightTop(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropRightTop');
    try {
      return super.updateCropRightTop(details);
    } finally {
      _$EditorModelBaseActionController.endAction(_$actionInfo);
    }
  }

  @override
  void updateCropRightBottom(DragUpdateDetails details) {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.updateCropRightBottom');
    try {
      return super.updateCropRightBottom(details);
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
  void startDraw() {
    final _$actionInfo = _$EditorModelBaseActionController.startAction(
        name: 'EditorModelBase.startDraw');
    try {
      return super.startDraw();
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
