const double _fontSizeStep = 1;

// Picks the largest font size, from maxSize down, for which the caption
// still fits. Measuring is injected so this stays pure and testable.
double fitCaptionFontSize({
  required double maxSize,
  required double minSize,
  required bool Function(double fontSize) fits,
}) {
  for (var size = maxSize; size > minSize; size -= _fontSizeStep) {
    if (fits(size)) return size;
  }
  return minSize;
}
