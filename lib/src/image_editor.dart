import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:vsc_image_editor/src/editor_model.dart';
import 'package:zoom_widget/zoom_widget.dart';

class VscImageEditor extends StatefulWidget {
  const VscImageEditor({
    Key? key,
    required this.imageBytes,
    this.controller,
  }) : super(key: key);

  final Uint8List imageBytes;
  final VscImageEditorController? controller;

  @override
  State<VscImageEditor> createState() => VscImageEditorState();
}

class VscImageEditorState extends State<VscImageEditor> {
  VscImageEditorState();

  late final EditorModel _model;

  @override
  void initState() {
    super.initState();
    _model = EditorModel(widget.imageBytes);
    widget.controller?.model = _model;
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      if (!_model.initialized) {
        return const Center(child: CircularProgressIndicator());
      }

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
                  return Observer(builder: (context) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Zoom(
                            initTotalZoomOut: true,
                            enableScroll: false,
                            transformationController:
                                _model.viewportTransformationController,
                            child: _model.imagePainterWidget,
                          ),
                        ),
                        Positioned.fill(
                          child: GestureDetector(
                            onTapUp: (p) =>
                                _model.maybeSelectAnnotationAt(p.localPosition),
                          ),
                        ),
                        Positioned.fill(
                          child: Stack(children: _model.viewportOverlays),
                        ),
                      ],
                    );
                  });
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
    });
  }

  Widget _buildButtons() {
    switch (_model.selectedTool) {
      case Tool.select:
        return _buildMainButtons();
      case Tool.crop:
        return _buildCropButtons();
      case Tool.draw:
        return _buildDrawButtons();
      case Tool.text:
      case Tool.oval:
      case Tool.rectangle:
        return _buildMainButtons();
    }
  }

  Widget _buildCropButtons() {
    return Row(
      key: const ValueKey('crop'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
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
      ],
    );
  }

  Widget _buildDrawButtons() {
    const brushColor = Colors.red;
    return Row(
      key: const ValueKey('draw'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FloatingActionButton.small(
          onPressed: () => _model.applyDrawing(),
          tooltip: 'Apply drawing',
          child: const Icon(Icons.done),
        ),
        const SizedBox(width: 24),
        FloatingActionButton.small(
          onPressed: () => _model.discardDrawing(),
          tooltip: 'Discard drawing',
          child: const Icon(Icons.close),
        ),
        const SizedBox(width: 24),
        FloatingActionButton.small(
          onPressed: () => _model.clearDrawing(),
          tooltip: 'Clear drawing',
          child: const Icon(Icons.undo),
        ),
        const SizedBox(width: 24),
        PopupMenuButton(
          itemBuilder: (context) => availableColors
              .map(
                (color) => PopupMenuItem(
                  onTap: () => _model.setDrawingColor(color),
                  child: Icon(
                    Icons.water_drop,
                    color: color,
                    shadows: [
                      if (color == Colors.white)
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
          offset: const Offset(48, 0),
          child: Row(
            children: [
              Icon(
                Icons.color_lens,
                color: _model.drawingColor,
                shadows: [
                  if (_model.drawingColor == Colors.white)
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
        ),
        const SizedBox(width: 24),
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
          offset: const Offset(48, 0),
          child: Row(
            children: const [
              Icon(Icons.brush),
              Icon(Icons.arrow_drop_up),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainButtons() {
    final toolItems = Tool.values
        .map(
          (tool) => PopupMenuItem(
            child: Icon(tool.icon),
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
        PopupMenuButton(
          itemBuilder: (context) => toolItems,
          tooltip: 'Tools',
          offset: const Offset(48, 0),
          child: Row(
            children: [
              Icon(_model.selectedTool.icon),
              const Icon(Icons.arrow_drop_up),
            ],
          ),
        ),
        IconButton(
          onPressed: () => _model.rotate90Left(),
          icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
          tooltip: 'Rotate left',
        ),
        IconButton(
          onPressed: () => _model.rotate90Right(),
          icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
          tooltip: 'Rotate right',
        ),
        IconButton(
          onPressed: () => _model.clearCrop(),
          icon: const Icon(Icons.fullscreen),
          tooltip: 'Clear crop',
        ),
        PopupMenuButton(
          itemBuilder: (context) => zoomItems,
          tooltip: 'Zoom',
          offset: const Offset(48, 0),
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
}
