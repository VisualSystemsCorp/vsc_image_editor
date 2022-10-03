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

  late final _$_physicalWidthAtom =
      Atom(name: 'EditorModelBase._physicalWidth', context: context);

  double get physicalWidth {
    _$_physicalWidthAtom.reportRead();
    return super._physicalWidth;
  }

  @override
  double get _physicalWidth => physicalWidth;

  @override
  set _physicalWidth(double value) {
    _$_physicalWidthAtom.reportWrite(value, super._physicalWidth, () {
      super._physicalWidth = value;
    });
  }

  late final _$_physicalHeightAtom =
      Atom(name: 'EditorModelBase._physicalHeight', context: context);

  double get physicalHeight {
    _$_physicalHeightAtom.reportRead();
    return super._physicalHeight;
  }

  @override
  double get _physicalHeight => physicalHeight;

  @override
  set _physicalHeight(double value) {
    _$_physicalHeightAtom.reportWrite(value, super._physicalHeight, () {
      super._physicalHeight = value;
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

  late final _$_physicalCropRectAtom =
      Atom(name: 'EditorModelBase._physicalCropRect', context: context);

  Rect get physicalCropRect {
    _$_physicalCropRectAtom.reportRead();
    return super._physicalCropRect;
  }

  @override
  Rect get _physicalCropRect => physicalCropRect;

  @override
  set _physicalCropRect(Rect value) {
    _$_physicalCropRectAtom.reportWrite(value, super._physicalCropRect, () {
      super._physicalCropRect = value;
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

  late final _$_initializeAsyncAction =
      AsyncAction('EditorModelBase._initialize', context: context);

  @override
  Future<void> _initialize(Uint8List imageBytes) {
    return _$_initializeAsyncAction.run(() => super._initialize(imageBytes));
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
  String toString() {
    return '''

    ''';
  }
}
