import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/adaptive_segmented_control.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/labeled_control.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';

class PlaybackSettingsControls extends StatelessWidget {
  const new({
    required this.speed,
    required this.loopMode,
    required this.onSpeedChanged,
    required this.onLoopModeChanged,
    super.key,
  });

  final double speed;
  final LoopMode loopMode;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<LoopMode> onLoopModeChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: Spacing.s,
    children: [
      LabeledControl(
        label: Strings.speed,
        child: AdaptiveSegmentedControl<double>(
          values: StudioSettings.speeds,
          selected: speed,
          labelOf: Strings.speedLabel,
          onChanged: onSpeedChanged,
        ),
      ),
      LabeledControl(
        label: Strings.loopMode,
        child: AdaptiveSegmentedControl<LoopMode>(
          values: LoopMode.values,
          selected: loopMode,
          labelOf: (mode) => switch (mode) {
            LoopMode.forward => Strings.loopForward,
            LoopMode.reverse => Strings.loopReverse,
            LoopMode.pingPong => Strings.loopPingPong,
          },
          onChanged: onLoopModeChanged,
        ),
      ),
    ],
  );
}
