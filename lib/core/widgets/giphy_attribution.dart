import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';

class GiphyAttribution extends StatelessWidget {
  const new({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      Strings.poweredByGiphy,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color ?? theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
