import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';

// Parts derived from the "screenshot" package: https://github.com/SachinGanesh/screenshot
// License:
// The MIT License (MIT)
//
// Copyright (c) 2018 Sachin Ganesh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

/// Capture the image byte data of the widget tree as raw RGBA.
/// Value for [delay] should increase with widget tree size. Preferred value is 1 seconds.
///
/// [context] parameter is used to Inherit App Theme and MediaQuery data.
Future<Uint8List> captureFromWidget(
  Widget widget, {
  Duration delay = const Duration(seconds: 1),
  double? pixelRatio,
  BuildContext? context,
  Size? targetSize,
}) async {
  ui.Image image = await widgetToUiImage(widget,
      delay: delay,
      pixelRatio: pixelRatio,
      context: context,
      targetSize: targetSize);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();

  return byteData!.buffer.asUint8List();
}

Future<ui.Image> widgetToUiImage(
  Widget widget, {
  Duration delay = const Duration(seconds: 1),
  double? pixelRatio,
  BuildContext? context,
  Size? targetSize,
}) async {
  var retryCounter = 3;
  var isDirty = false;

  var child = widget;

  if (context != null) {
    // Inherit Theme and MediaQuery of app
    child = InheritedTheme.captureAll(
      context,
      MediaQuery(
          data: MediaQuery.of(context),
          child: Material(
            color: Colors.transparent,
            child: child,
          )),
    );
  }

  final repaintBoundary = RenderRepaintBoundary();

  Size logicalSize = targetSize ??
      ui.window.physicalSize / ui.window.devicePixelRatio; // Adapted
  Size imageSize = targetSize ?? ui.window.physicalSize; // Adapted

  assert(logicalSize.aspectRatio.toStringAsPrecision(5) ==
      imageSize.aspectRatio
          .toStringAsPrecision(5)); // Adapted (toPrecision was not available)

  final renderView = RenderView(
    window: ui.window,
    child: RenderPositionedBox(
        alignment: Alignment.center, child: repaintBoundary),
    configuration: ViewConfiguration(
      size: logicalSize,
      devicePixelRatio: pixelRatio ?? 1.0,
    ),
  );

  final pipelineOwner = PipelineOwner();
  final buildOwner = BuildOwner(
      focusManager: FocusManager(),
      onBuildScheduled: () {
        // current render is dirty, mark it.
        isDirty = true;
      });

  pipelineOwner.rootNode = renderView;
  renderView.prepareInitialFrame();

  final rootElement = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: child,
      )).attachToRenderTree(
    buildOwner,
  );

  // Render Widget

  buildOwner.buildScope(
    rootElement,
  );
  buildOwner.finalizeTree();

  pipelineOwner.flushLayout();
  pipelineOwner.flushCompositingBits();
  pipelineOwner.flushPaint();

  ui.Image? image;

  do {
    isDirty = false;

    if (image != null) {
      image.dispose();
    }

    image = await repaintBoundary.toImage(
        pixelRatio: pixelRatio ?? (imageSize.width / logicalSize.width));

    // This delay should increase with Widget tree Size
    await Future.delayed(delay);

    // Check does this require rebuild
    if (isDirty) {
      // Previous capture has been updated, re-render again.
      buildOwner.buildScope(
        rootElement,
      );
      buildOwner.finalizeTree();
      pipelineOwner.flushLayout();
      pipelineOwner.flushCompositingBits();
      pipelineOwner.flushPaint();
    }
    retryCounter--;

    // retry until capture is successful
  } while (isDirty && retryCounter >= 0);

  return image;
}
