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
  }) : super(key: key);

  final Uint8List imageBytes;

  @override
  State<VscImageEditor> createState() => _VscImageEditorState();
}

class _VscImageEditorState extends State<VscImageEditor> {
  _VscImageEditorState();

  late final EditorModel _model;

  @override
  void initState() {
    super.initState();
    _model = EditorModel(widget.imageBytes);
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
    return Observer(builder: (context) {
      if (!_model.initialized) {
        return const Center(child: CircularProgressIndicator());
      }

      final theme = Theme.of(context);
      return BottomNavigationBarTheme(
        data: theme.bottomNavigationBarTheme,
        child: SizedBox.expand(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            onScaleUpdate: (scaleChange, newScale) {},
                            child: SizedBox(
                              width: _model.physicalWidth,
                              height: _model.physicalHeight,
                              child: CustomPaint(
                                painter: _ImagePainter(_model),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          // TODO controls from model go here.
                          child: _CropControl(model: _model),
                        ),
                      ],
                    );
                  });
                }),
              ),
              BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                currentIndex: 8,
                onTap: (index) {},
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.pan_tool_alt),
                    label: 'Select',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.crop),
                    label: 'Crop',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.rotate_90_degrees_ccw_outlined),
                    label: 'Rotate left',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.rotate_90_degrees_cw_outlined),
                    label: 'Rotate right',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.gesture),
                    label: 'Draw',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.text_fields),
                    label: 'Text',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.circle_outlined),
                    label: 'Draw circle/ellipse',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.rectangle_outlined),
                    label: 'Draw rectangle',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.color_lens, color: Colors.red),
                    label: 'Color',
                  ),
                  BottomNavigationBarItem(
                    icon: Text('100%'),
                    label: 'Zoom',
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _CropControl extends StatelessWidget {
  const _CropControl({Key? key, required this.model}) : super(key: key);

  final EditorModel model;

  @override
  Widget build(BuildContext context) {
    // TODO move this to when control is activated.
    if (model.cropRect == Rect.zero) model.startCrop();

    return Observer(
      builder: (context) {
        final cropRect = model.cropRect;
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

class _ImagePainter extends CustomPainter {
  _ImagePainter(this._model);

  final EditorModel _model;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawImage(_model.uiImage!, Offset.zero, Paint());
  }

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
    canvas.drawPath(
        Path.combine(
            PathOperation.difference,
            Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
            Path()..addRect(cropRect)),
        transparentOverlayPaint);
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.6);
    canvas.drawRect(cropRect, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/*
                Image.memory(
                  _model.imageBytes,
                  // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
                  filterQuality: FilterQuality.medium,
                ),

 */
