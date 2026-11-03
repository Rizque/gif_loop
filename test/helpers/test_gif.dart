import 'dart:typed_data';

import 'package:image/image.dart' as img;

const List<(int, int, int)> testGifColors = [
  (0, 0, 255),
  (0, 255, 0),
  (255, 255, 0),
];

// A tiny animated GIF: one solid color per frame, 100 ms each.
Uint8List buildTestGif({int width = 20, int height = 10}) {
  final encoder = img.GifEncoder();
  for (final (red, green, blue) in testGifColors) {
    final frame = img.Image(width: width, height: height)
      ..clear(img.ColorRgb8(red, green, blue));
    encoder.addFrame(frame, duration: 10);
  }
  return encoder.finish()!;
}
