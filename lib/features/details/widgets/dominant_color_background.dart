import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class DominantColorBackground extends StatelessWidget {
  const new({required this.color, required this.child, super.key});

  static const double _tintStrength = 0.55;
  static const double _gradientFade = 0.4;

  final Color? color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final color = this.color;
    final tint = color == null
        ? surface
        : Color.alphaBlend(color.withValues(alpha: _tintStrength), surface);
    final foreground =
        ThemeData.estimateBrightnessForColor(tint) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: tint),
      duration: AppDurations.long,
      builder: (context, animatedTint, child) {
        final top = animatedTint ?? tint;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [top, Color.lerp(top, surface, _gradientFade) ?? top],
            ),
          ),
          child: child,
        );
      },
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(
            onSurface: foreground,
            onSurfaceVariant: foreground.withValues(alpha: 0.75),
          ),
          textTheme: theme.textTheme.apply(
            bodyColor: foreground,
            displayColor: foreground,
          ),
          iconTheme: theme.iconTheme.copyWith(color: foreground),
        ),
        child: child,
      ),
    );
  }
}
