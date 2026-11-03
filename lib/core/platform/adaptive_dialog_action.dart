import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/platform.dart';

class AdaptiveDialogAction extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.isDestructive = false,
    this.isDefault = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    if (context.isCupertino) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructive,
        isDefaultAction: isDefault,
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: isDestructive
          ? TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            )
          : null,
      child: Text(label),
    );
  }
}
