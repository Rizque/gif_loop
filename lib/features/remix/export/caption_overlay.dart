import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:gif_loop/features/remix/export/caption_painter.dart';

// Needs Flutter's text engine, so it runs on the main isolate. Straight
// (unpremultiplied) alpha is what the image package's alpha blend expects.
Future<Uint8List?> renderCaptionOverlay({
  required int width,
  required int height,
  required String topText,
  required String bottomText,
}) async {
  if (topText.trim().isEmpty && bottomText.trim().isEmpty) return null;
  final recorder = ui.PictureRecorder();
  CaptionPainter(
    topText: topText,
    bottomText: bottomText,
  ).paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  return data?.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
