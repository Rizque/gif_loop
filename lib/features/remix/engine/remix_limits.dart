import 'dart:math';

abstract final class RemixLimits {
  static const int maxOutputWidth = 480;
  static const int maxOutputFrames = 150;
  static const int maxCaptionLength = 40;
}

typedef RemixSize = ({int width, int height});

RemixSize remixOutputSize({required int width, required int height}) {
  if (width <= RemixLimits.maxOutputWidth) {
    return (width: max(1, width), height: max(1, height));
  }
  return (
    width: RemixLimits.maxOutputWidth,
    height: max(1, (height * RemixLimits.maxOutputWidth / width).round()),
  );
}
