import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_state.dart';
import 'package:gif_loop/features/remix/widgets/remix_caption_fields.dart';
import 'package:gif_loop/features/remix/widgets/remix_preview_controller.dart';
import 'package:gif_loop/features/studio/widgets/playback_settings_controls.dart';

class RemixControls extends StatelessWidget {
  const new({required this.sourceFrameCount, required this.preview, super.key});

  final int sourceFrameCount;
  final RemixPreviewController preview;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemixEditorCubit>();
    return BlocBuilder<RemixEditorCubit, RemixEditorState>(
      buildWhen: (previous, current) =>
          previous.settings != current.settings ||
          previous.plan != current.plan ||
          previous.exportStatus != current.exportStatus,
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Spacing.l,
        children: [
          if (sourceFrameCount > 1)
            _TrimControl(
              sourceFrameCount: sourceFrameCount,
              start: state.settings.trimStart,
              end: state.settings.trimEnd,
              preview: preview,
            ),
          PlaybackSettingsControls(
            speed: state.settings.speed,
            loopMode: state.settings.loopMode,
            onSpeedChanged: cubit.speedChanged,
            onLoopModeChanged: cubit.loopModeChanged,
          ),
          const RemixCaptionFields(),
          _OutputInfo(state: state),
          FilledButton.icon(
            onPressed: state.canExport ? cubit.export : null,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text(Strings.exportGif),
          ),
          if (state.plan.exceedsFrameLimit)
            Text(
              Strings.frameLimitExceeded,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _TrimControl extends StatelessWidget {
  const new({
    required this.sourceFrameCount,
    required this.start,
    required this.end,
    required this.preview,
  });

  final int sourceFrameCount;
  final int start;
  final int end;
  final RemixPreviewController preview;

  // Scrubbing pauses the preview on the frame under the moved handle.
  void _onChanged(BuildContext context, RangeValues values) {
    final newStart = values.start.round();
    final newEnd = values.end.round();
    preview.pin(newStart != start ? newStart : newEnd);
    context.read<RemixEditorCubit>().trimChanged(newStart, newEnd);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: Strings.trim,
    container: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(Strings.trim, style: Theme.of(context).textTheme.labelLarge),
        Text(Strings.trimRange(start + 1, end + 1)),
        RangeSlider(
          values: RangeValues(start.toDouble(), end.toDouble()),
          max: (sourceFrameCount - 1).toDouble(),
          divisions: sourceFrameCount - 1,
          labels: RangeLabels('${start + 1}', '${end + 1}'),
          onChanged: (values) => _onChanged(context, values),
          onChangeEnd: (_) => preview.resume(),
        ),
      ],
    ),
  );
}

class _OutputInfo extends StatelessWidget {
  const new({required this.state});

  final RemixEditorState state;

  @override
  Widget build(BuildContext context) {
    final size = state.outputSize;
    if (size == null) return const SizedBox.shrink();
    final seconds = (state.plan.duration.inMilliseconds / 1000).toStringAsFixed(
      1,
    );
    return Text(
      Strings.remixInfo(
        size.width,
        size.height,
        state.plan.frames.length,
        seconds,
      ),
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge,
    );
  }
}
