import 'dart:typed_data';

import 'package:flutter/material.dart';

class VscImageEditor extends StatelessWidget {
  const VscImageEditor({
    Key? key,
    required this.imageBytes,
  }) : super(key: key);

  final Uint8List imageBytes;

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
    final theme = Theme.of(context);
    return BottomNavigationBarTheme(
      data: theme.bottomNavigationBarTheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "medium" provides better scaling results than "high" - see https://github.com/flutter/flutter/issues/79645#issuecomment-819920763.
          Expanded(
            child: Stack(
              children: [
                Image.memory(
                  imageBytes,
                  filterQuality: FilterQuality.medium,
                ),
                FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: CustomPaint(
                    painter: CropPainter(),
                  ),
                ),
              ],
            ),
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
                icon: Icon(Icons.rotate_90_degrees_ccw),
                label: 'Rotate left',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rotate_90_degrees_cw),
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
    );
  }
}

class CropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cropRect = Rect.fromLTWH(300, 200, 400, 500);
    final transparentOverlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/*
    image.image
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((info, _) async {
      debugPrint('info: $info ');
      final bytes = await captureFromWidget(
        Stack(
          children: [
            image,
            Center(child: Icon(Icons.ac_unit, color: Colors.green, size: 300))
          ],
        ),
        pixelRatio: 1,
        context: context,
        targetSize:
            Size(info.image.width.toDouble(), info.image.height.toDouble()),
      );
      debugPrint('bytes=${bytes.length}');

      final internalImage = img.decodeImage(bytes);
      final encodedBytes = img.encodeJpg(internalImage!, quality: 98);
      // img.Image.fromBytes(info.image.width, info.image.height, bytes));
      debugPrint('Encoded bytes = ${encodedBytes.length}');

      final out = File('/home/dsyrstad/Downloads/Test-12MP-OUT.jpg');
      out.writeAsBytesSync(encodedBytes, flush: true);
      debugPrint('Wrote file');
    }));

 */
