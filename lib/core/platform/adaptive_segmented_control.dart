import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/platform.dart';

class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const new({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    if (context.isCupertino) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: selected,
        children: {for (final value in values) value: Text(labelOf(value))},
        onValueChanged: (value) {
          if (value != null) onChanged(value);
        },
      );
    }
    return SegmentedButton<T>(
      showSelectedIcon: false,
      segments: [
        for (final value in values)
          ButtonSegment(value: value, label: Text(labelOf(value))),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onChanged(selection.single),
    );
  }
}
