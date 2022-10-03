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

  /*
     Zoom level - default fit to window, mobile pinch to zoom
     elements such as image, and widgets that will be part of the image, are effect by zoom
     Crop markers must be same size regardless of zoom, same with widget sticker markers, so
     individual widgets must be zoomed and positioned relative to the zoom when drawing on screen.
     brush size
     font size is fixed and text draws on image at the zoomed-in size (i.e., text size looks the same on the screen when adding it zoomed in
     or out, but once placed, a zoom in/out affects the visual size. Same with brush. So font size in inverse of zoom size.
      color
   */
  @override
  Widget build(BuildContext context) {
    final toolItems = Tool.values
        .map(
          (tool) => PopupMenuItem(
            child: Icon(tool.icon),
            onTap: () => _model.selectTool(tool),
          ),
        )
        .toList(growable: false);

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
              child: LayoutBuilder(builder: (context, constraints) {
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
                              _model.transformationController,
                          child: SizedBox(
                            width: _model.physicalCropRect.width,
                            height: _model.physicalCropRect.height,
                            child: CustomPaint(
                              painter: _model.imagePainter,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Stack(children: _model.viewportOverlays),
                      ),
                    ],
                  );
                });
              }),
            ),
            Container(
              color: theme.colorScheme.surface,
              height: 64,
              child: Row(
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
                    onPressed: () {},
                    icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
                    tooltip: 'Rotate left',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                    tooltip: 'Rotate right',
                  ),
                  IconButton(
                    onPressed: () => _model.clearCrop(),
                    icon: const Icon(Icons.crop_original_outlined),
                    tooltip: 'Clear crop',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.color_lens, color: Colors.red),
                    tooltip: 'Color',
                  ),
                  Tooltip(
                    message: 'Zoom',
                    child: TextButton(
                      onPressed: () {},
                      child: Row(
                        children: [
                          Text(
                              '${(_model.zoomScale * 100).toStringAsFixed(1)}%'),
                          const Icon(Icons.arrow_drop_up),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class VscImageEditorController {
  EditorModel? model;

  Future<ui.Image?> getEditedUiImage() async => model?.getEditedUiImage();
}
