import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class TappableTile extends StatelessWidget {
  const new({
    required this.aspectRatio,
    required this.semanticLabel,
    required this.heroTag,
    required this.onTap,
    required this.child,
    super.key,
  });

  final double aspectRatio;
  final String semanticLabel;
  final Object heroTag;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    button: true,
    excludeSemantics: true,
    child: AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.tile),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: heroTag, child: child),
            Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: onTap),
            ),
          ],
        ),
      ),
    ),
  );
}
