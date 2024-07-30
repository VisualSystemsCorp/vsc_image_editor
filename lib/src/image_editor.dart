import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vsc_image_editor/src/editor_model.dart';
import 'package:zoom_widget/zoom_widget.dart';

const _defaultToolNames = <Tool, String>{
  Tool.select: 'Select/Move',
  Tool.crop: 'Crop',
  Tool.draw: 'Draw',
  Tool.oval: 'Oval',
  Tool.rectangle: 'Rectangle',
  Tool.text: 'Text',
  Tool.line: 'Line',
  Tool.arrow: 'Arrow',
};

const _buttonBarGap = SizedBox(width: 12);

/// A widget which allows the user to crop, rotate, and annotate an image.
class VscImageEditor extends StatefulWidget {
  const VscImageEditor({
    Key? key,
    required this.imageBytes,
    this.controller,
    this.fixedCropRatio,
    this.selectedTool,
    this.showCropCircle = false,
    this.viewOnly = false,
  }) : super(key: key);

  /// The original unedited image.
  final Uint8List imageBytes;

  /// A controller that can be used to retrieve the edited image.
  final VscImageEditorController? controller;

  /// If non-null, cropping will be restricted to this crop ratio. For example, a
  /// value of 1.0 will restrict the crop to a 1:1 ratio. This is a ratio of width
  /// to height, so a 16:9 ratio = 1.7778.
  final double? fixedCropRatio;

  /// If set, this is the tool that will be selected when the editor starts.
  final Tool? selectedTool;

  /// If true, the crop rectangle will show an embedded circle which is useful
  /// if you're setting a circle-based avatar with a [fixedCropRatio] of 1.0.
  final bool showCropCircle;

  /// True if you just want to view the image.
  final bool viewOnly;

  @override
  State<VscImageEditor> createState() => VscImageEditorState();
}

class VscImageEditorState extends State<VscImageEditor> {
  VscImageEditorState();

  late final EditorModel _model;

  @override
  void initState() {
    super.initState();
    _model = EditorModel(
      widget.imageBytes,
      fixedCropRatio: widget.fixedCropRatio,
      selectedTool: widget.selectedTool,
      showCropCircle: widget.showCropCircle,
      viewOnly: widget.viewOnly,
    );
    widget.controller?.model = _model;
  }

  @override
  void didUpdateWidget(covariant VscImageEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    _model.setFixedCropRatio(widget.fixedCropRatio);
    if (widget.selectedTool != null) {
      _model.selectTool(widget.selectedTool!);
    }

    _model.setShowCropCircle(widget.showCropCircle);
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        if (!_model.initialized) {
          return const Center(child: CircularProgressIndicator());
        }

        _model.fixedCropRatio; // Watch this
        final theme = Theme.of(context);
        return BottomNavigationBarTheme(
          data: theme.bottomNavigationBarTheme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _model.setViewportSize(
                        constraints.maxWidth, constraints.maxHeight);
                    return Observer(
                      builder: (context) {
                        // Make sure this is observed so we rebuild when the overlays change.
                        _model.viewportOverlays.length;

                        return Stack(
                          children: [
                            Zoom(
                              initTotalZoomOut: false,
                              enableScroll: false,
                              transformationController:
                                  _model.viewportTransformationController,
                              child: _model.imagePainterWidget,
                            ),
                            Positioned.fill(
                              child: GestureDetector(
                                onTapUp: (p) => _model
                                    .maybeSelectAnnotationAt(p.localPosition),
                              ),
                            ),
                            Positioned.fill(
                              child: Stack(
                                children: _model.viewportOverlays,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                color: theme.colorScheme.surface,
                height: 64,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _buildButtons(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildButtons() {
    switch (_model.selectedTool) {
      case Tool.select:
        return _buildMainButtons();
      case Tool.crop:
        return _buildCropButtons();
      case Tool.draw:
      case Tool.oval:
      case Tool.rectangle:
      case Tool.line:
      case Tool.arrow:
        return _buildDrawButtons();
      case Tool.text:
        return _buildTextButtons();
    }
  }

  Widget _buildCropButtons() {
    return Row(
      key: const ValueKey('crop'),
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(width: 24),
        Icon(_model.selectedTool.icon),
        const Spacer(),
        FloatingActionButton.small(
          onPressed: () => _model.applyCrop(),
          tooltip: 'Apply crop',
          child: const Icon(Icons.done),
        ),
        const SizedBox(width: 24),
        FloatingActionButton.small(
          onPressed: () => _model.cancelCrop(),
          tooltip: 'Cancel cropping',
          child: const Icon(Icons.close),
        ),
        const Spacer(),
        // Even-out right side
        const Icon(null),
      ],
    );
  }

  Widget _buildDrawButtons() {
    return Row(
      key: const ValueKey('draw'),
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buttonBarGap,
        Icon(_model.selectedTool.icon),
        const Spacer(),
        FloatingActionButton.small(
          onPressed: () => _model.applyAnnotations(),
          tooltip: 'Apply drawing',
          child: const Icon(Icons.done),
        ),
        _buttonBarGap,
        FloatingActionButton.small(
          onPressed: () => _model.discardAnnotations(),
          tooltip: 'Discard drawing',
          child: const Icon(Icons.close),
        ),
        _buttonBarGap,
        FloatingActionButton.small(
          onPressed: () => _model.undoLastWorkingAnnotation(),
          tooltip: 'Undo',
          child: const Icon(Icons.undo),
        ),
        _buttonBarGap,
        _buildColorPicker(),
        _buttonBarGap,
        PopupMenuButton(
          itemBuilder: (context) => availableBrushSizes
              .map(
                (size) => PopupMenuItem(
                  onTap: () => _model.setBrushSize(size),
                  child: Icon(
                    Icons.circle,
                    size: size,
                    color: _model.brushSize == size ? Colors.green : null,
                  ),
                ),
              )
              .toList(growable: false),
          tooltip: 'Brush size',
          offset: const Offset(96, 0),
          child: const Row(
            children: [
              Icon(Icons.brush),
              Icon(Icons.arrow_drop_up),
            ],
          ),
        ),
        const Spacer(),
        // Even-out right side
        const Icon(null),
      ],
    );
  }

  Widget _buildTextButtons() {
    return Row(
      key: const ValueKey('text'),
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _buttonBarGap,
        Icon(_model.selectedTool.icon),
        const Spacer(),
        FloatingActionButton.small(
          onPressed: () => _model.applyAnnotations(),
          tooltip: 'Apply',
          child: const Icon(Icons.done),
        ),
        _buttonBarGap,
        FloatingActionButton.small(
          onPressed: () => _model.discardAnnotations(),
          tooltip: 'Discard',
          child: const Icon(Icons.close),
        ),
        _buttonBarGap,
        FloatingActionButton.small(
          onPressed: () => _model.undoLastWorkingAnnotation(),
          tooltip: 'Undo',
          child: const Icon(Icons.undo),
        ),
        _buttonBarGap,
        _buildColorPicker(),
        _buttonBarGap,
        PopupMenuButton(
          itemBuilder: (context) => availableFontSizes
              .map(
                (size) => PopupMenuItem(
                  onTap: () => _model.setFontSize(size),
                  child: Text(
                    'A',
                    style: TextStyle(
                        fontSize: size / 3,
                        fontWeight: FontWeight.bold,
                        color: (_model.fontSize == size) ? Colors.green : null),
                  ),
                ),
              )
              .toList(growable: false),
          tooltip: 'Font size',
          offset: const Offset(96, 0),
          child: const Row(
            children: [
              Icon(Icons.format_size),
              Icon(Icons.arrow_drop_up),
            ],
          ),
        ),
        const Spacer(),
        // Even-out right side
        const Icon(null),
      ],
    );
  }

  PopupMenuButton<dynamic> _buildColorPicker() {
    return PopupMenuButton(
      itemBuilder: (context) => availableColors
          .map(
            (color) => PopupMenuItem(
              onTap: () => _model.setDrawingColor(color),
              child: Icon(
                Icons.water_drop,
                color: color,
                shadows: [
                  if (color == Colors.white || color == Colors.yellow)
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),
                  if (color == Colors.black)
                    const Shadow(
                      color: Colors.white,
                      blurRadius: 10,
                    ),
                ],
              ),
            ),
          )
          .toList(growable: false),
      tooltip: 'Color',
      offset: const Offset(96, 0),
      child: Row(
        children: [
          Icon(
            Icons.color_lens,
            color: _model.drawingColor,
            shadows: [
              if (_model.drawingColor == Colors.white ||
                  _model.drawingColor == Colors.yellow)
                const Shadow(
                  color: Colors.black,
                  blurRadius: 10,
                ),
              if (_model.drawingColor == Colors.black)
                const Shadow(
                  color: Colors.white,
                  blurRadius: 10,
                ),
            ],
          ),
          const Icon(Icons.arrow_drop_up),
        ],
      ),
    );
  }

  Widget _buildMainButtons() {
    final toolItems = Tool.values
        .map(
          (tool) => PopupMenuItem(
            child: Row(
              children: [
                Icon(tool.icon),
                const SizedBox(width: 8),
                Text(_defaultToolNames[tool] ?? ''),
              ],
            ),
            onTap: () => _model.selectTool(tool),
          ),
        )
        .toList(growable: false);

    final zoomItems = [
      PopupMenuItem(
        child: const Text('400%'),
        onTap: () => _model.setScale(4.0),
      ),
      PopupMenuItem(
        child: const Text('200%'),
        onTap: () => _model.setScale(2.0),
      ),
      PopupMenuItem(
        child: const Text('100%'),
        onTap: () => _model.setScale(1.0),
      ),
      PopupMenuItem(
        child: const Text('50%'),
        onTap: () => _model.setScale(0.5),
      ),
      PopupMenuItem(
        child: const Text('25%'),
        onTap: () => _model.setScale(0.25),
      ),
      PopupMenuItem(
        child: const Text('12%'),
        onTap: () => _model.setScale(0.12),
      ),
      PopupMenuItem(
        child: const Text('View full image'),
        onTap: () => _model.scaleToFitViewport(),
      ),
    ];

    return Row(
      key: const ValueKey('main'),
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (!_model.viewOnly)
          PopupMenuButton(
            itemBuilder: (context) => toolItems,
            tooltip: 'Tools',
            offset: const Offset(32, 0),
            child: Row(
              children: [
                Icon(_model.selectedTool.icon),
                const Icon(Icons.arrow_drop_up),
              ],
            ),
          ),
        if (!_model.viewOnly)
          IconButton(
            onPressed: () => _model.rotate90Left(),
            icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
            tooltip: 'Rotate left',
          ),
        if (!_model.viewOnly)
          IconButton(
            onPressed: () => _model.rotate90Right(),
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
            tooltip: 'Rotate right',
          ),
        if (!_model.viewOnly)
          IconButton(
            onPressed: () => _model.clearCrop(),
            icon: const Icon(Icons.fullscreen),
            tooltip: 'Clear crop',
          ),
        PopupMenuButton(
          itemBuilder: (context) => zoomItems,
          tooltip: 'Zoom',
          offset: const Offset(150, 0),
          child: Row(
            children: [
              Text('${(_model.zoomScale * 100).toStringAsFixed(1)}%'),
              const Icon(Icons.arrow_drop_up),
            ],
          ),
        ),
      ],
    );
  }
}

class VscImageEditorController {
  EditorModel? model;

  Future<ui.Image?> getEditedUiImage() async => model?.getEditedUiImage();

  bool isModified() => model?.isModified() ?? false;
}
