import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';

class RemixCaptionFields extends StatefulWidget {
  const new({super.key});

  @override
  State<RemixCaptionFields> createState() => _RemixCaptionFieldsState();
}

class _RemixCaptionFieldsState extends State<RemixCaptionFields> {
  late final TextEditingController _top;
  late final TextEditingController _bottom;

  @override
  void initState() {
    super.initState();
    final settings = context.read<RemixEditorCubit>().state.settings;
    _top = TextEditingController(text: settings.topText);
    _bottom = TextEditingController(text: settings.bottomText);
  }

  @override
  void dispose() {
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemixEditorCubit>();
    return Column(
      spacing: Spacing.m,
      children: [
        _CaptionField(
          controller: _top,
          label: Strings.topText,
          action: TextInputAction.next,
          onChanged: cubit.topTextChanged,
        ),
        _CaptionField(
          controller: _bottom,
          label: Strings.bottomText,
          action: TextInputAction.done,
          onChanged: cubit.bottomTextChanged,
        ),
      ],
    );
  }
}

class _CaptionField extends StatelessWidget {
  const new({
    required this.controller,
    required this.label,
    required this.action,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction action;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    maxLength: RemixLimits.maxCaptionLength,
    textInputAction: action,
    textCapitalization: TextCapitalization.sentences,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    onChanged: onChanged,
  );
}
