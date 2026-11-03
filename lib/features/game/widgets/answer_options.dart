import 'package:flutter/material.dart';
import 'package:gif_loop/core/theme/feedback_colors.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class AnswerOptions extends StatelessWidget {
  const new({
    required this.options,
    required this.answer,
    required this.selectedOption,
    required this.columns,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String answer;
  final String? selectedOption;
  final int columns;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    spacing: Spacing.s,
    children: [
      for (var start = 0; start < options.length; start += columns)
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.s,
            children: [
              for (final option in options.skip(start).take(columns))
                Expanded(
                  child: _OptionButton(
                    label: option,
                    outcome: _outcomeOf(option),
                    onPressed: selectedOption == null
                        ? () => onSelected(option)
                        : null,
                  ),
                ),
            ],
          ),
        ),
    ],
  );

  _Outcome _outcomeOf(String option) {
    if (selectedOption == null) return _Outcome.pending;
    if (option == answer) return _Outcome.correct;
    if (option == selectedOption) return _Outcome.wrong;
    return _Outcome.dimmed;
  }
}

enum _Outcome { pending, correct, wrong, dimmed }

class _OptionButton extends StatelessWidget {
  const new({
    required this.label,
    required this.outcome,
    required this.onPressed,
  });

  static const double _minHeight = 56;
  static const double _revealScale = 1.04;
  static const double _dimmedOpacity = 0.45;

  final String label;
  final _Outcome outcome;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (outcome) {
      _Outcome.pending ||
      _Outcome.dimmed => (colors.surfaceContainerHigh, colors.onSurface),
      _Outcome.correct => (FeedbackColors.correct, FeedbackColors.onFeedback),
      _Outcome.wrong => (colors.error, colors.onError),
    };
    return AnimatedOpacity(
      duration: AppDurations.medium,
      opacity: outcome == _Outcome.dimmed ? _dimmedOpacity : 1,
      child: AnimatedScale(
        duration: AppDurations.medium,
        curve: Curves.easeOutBack,
        scale: outcome == _Outcome.correct ? _revealScale : 1,
        child: AnimatedContainer(
          duration: AppDurations.medium,
          constraints: const BoxConstraints(minHeight: _minHeight),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(Radii.tile),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(Radii.tile),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.m),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
