import 'dart:math';
import 'dart:ui';

abstract final class Breakpoints {
  // The shortest side tells phones from tablets in both orientations: a
  // landscape phone is wide but still short.
  static const double tabletShortestSide = 600;
  static const double railMinWidth = 72;
  static const double gridColumnWidth = 180;
  static const int minGridColumns = 2;

  static bool isTablet(Size screen) =>
      screen.shortestSide >= tabletShortestSide;

  static bool isPhoneLandscape(Size screen) =>
      !isTablet(screen) && screen.width > screen.height;

  static int gridColumnCount(double width) =>
      max(minGridColumns, width ~/ gridColumnWidth);
}
