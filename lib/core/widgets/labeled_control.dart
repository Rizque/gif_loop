import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class LabeledControl extends StatelessWidget {
  const new({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    container: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Spacing.xs,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: child,
          ),
        ),
      ],
    ),
  );
}
