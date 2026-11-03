import 'dart:math';

abstract final class Breakpoints {
  static const double navigationRail = 600;
  static const double gridColumnWidth = 180;
  static const int minGridColumns = 2;

  static int gridColumnCount(double width) =>
      max(minGridColumns, width ~/ gridColumnWidth);
}
