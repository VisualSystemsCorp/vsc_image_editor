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

  late final _$_cropRectAtom =
      Atom(name: 'EditorModelBase._cropRect', context: context);

  Rect get cropRect {
    _$_cropRectAtom.reportRead();
    return super._cropRect;
  }

  @override
  Rect get _cropRect => cropRect;

  @override
  set _cropRect(Rect value) {
    _$_cropRectAtom.reportWrite(value, super._cropRect, () {
      super._cropRect = value;
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
  String toString() {
    return '''

    ''';
  }
}
