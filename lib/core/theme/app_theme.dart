import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color seed = Color(0xFF9B2BFF);

  // Compact Android bottom bar: Material 3 defaults are 80 and 24.
  static const double navigationBarHeight = 64;
  static const double navigationBarIconSize = 22;
  static const double _disabledOpacity = 0.38;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: const AppBarTheme(centerTitle: false),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
    return base.copyWith(
      navigationBarTheme: _navigationBarTheme(colorScheme, base.textTheme),
    );
  }

  // Keeps the Material 3 state colors; only the sizes and the label style
  // (labelSmall instead of labelMedium) change.
  static NavigationBarThemeData _navigationBarTheme(
    ColorScheme colors,
    TextTheme textTheme,
  ) => NavigationBarThemeData(
    height: navigationBarHeight,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith(
      (states) => IconThemeData(
        size: navigationBarIconSize,
        color: _stateColor(
          states,
          colors,
          selected: colors.onSecondaryContainer,
        ),
      ),
    ),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => _labelSmall(textTheme).copyWith(
        color: _stateColor(states, colors, selected: colors.onSurface),
      ),
    ),
  );

  // A raw ThemeData's textTheme has no font sizes yet (Theme.of merges in the
  // localized geometry later), so the Material 3 geometry is merged here.
  static TextStyle _labelSmall(TextTheme textTheme) =>
      Typography.englishLike2021.labelSmall?.merge(textTheme.labelSmall) ??
      const TextStyle();

  static Color _stateColor(
    Set<WidgetState> states,
    ColorScheme colors, {
    required Color selected,
  }) {
    if (states.contains(WidgetState.disabled)) {
      return colors.onSurfaceVariant.withValues(alpha: _disabledOpacity);
    }
    return states.contains(WidgetState.selected)
        ? selected
        : colors.onSurfaceVariant;
  }
}
