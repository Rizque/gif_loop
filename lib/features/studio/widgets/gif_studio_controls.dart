import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/platform/adaptive_segmented_control.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
import 'package:gif_loop/features/studio/gif_studio_controller.dart';

class GifStudioControls extends StatelessWidget {
  const new({required this.controller, required this.onRetry, super.key});

  final GifStudioController controller;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => AnimatedSize(
      duration: AppDurations.short,
      alignment: Alignment.topCenter,
      child: switch (controller.status) {
        StudioStatus.loading => _DecodingProgress(
          progress: controller.progress,
        ),
        StudioStatus.failure => _StudioError(
          failure: controller.failure ?? const UnknownFailure(),
          onRetry: onRetry,
        ),
        StudioStatus.ready when controller.hasPlayback => _PlaybackControls(
          controller: controller,
        ),
        StudioStatus.ready => const SizedBox.shrink(),
      },
    ),
  );
}

class _DecodingProgress extends StatelessWidget {
  const new({required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.s,
      children: [
        Text(
          progress == null
              ? Strings.downloadingGif
              : Strings.decodingFrames((progress * 100).round()),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        LinearProgressIndicator(value: progress),
      ],
    );
  }
}

class _StudioError extends StatelessWidget {
  const new({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      spacing: Spacing.m,
      children: [
        Icon(failure.icon),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(failure.title, style: textTheme.titleSmall),
              Text(failure.message, style: textTheme.bodySmall),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: onRetry,
          child: const Text(Strings.retry),
        ),
      ],
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const new({required this.controller});

  final GifStudioController controller;

  void _step(VoidCallback move) {
    unawaited(HapticFeedback.selectionClick());
    move();
  }

  @override
  Widget build(BuildContext context) {
    final isPaused = !controller.isPlaying;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.s,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: Strings.previousFrame,
              onPressed: isPaused ? () => _step(controller.stepBackward) : null,
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            IconButton.filled(
              tooltip: controller.isPlaying ? Strings.pause : Strings.play,
              onPressed: controller.togglePlay,
              icon: Icon(
                controller.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            ),
            IconButton(
              tooltip: Strings.nextFrame,
              onPressed: isPaused ? () => _step(controller.stepForward) : null,
              icon: const Icon(Icons.skip_next_rounded),
            ),
            const Spacer(),
            _FrameCounter(controller: controller),
          ],
        ),
        _FrameScrubber(controller: controller),
        _LabeledControl(
          label: Strings.speed,
          child: AdaptiveSegmentedControl<double>(
            values: StudioSettings.speeds,
            selected: controller.speed,
            labelOf: Strings.speedLabel,
            onChanged: (speed) => controller.speed = speed,
          ),
        ),
        _LabeledControl(
          label: Strings.loopMode,
          child: AdaptiveSegmentedControl<LoopMode>(
            values: LoopMode.values,
            selected: controller.loopMode,
            labelOf: (mode) => switch (mode) {
              LoopMode.forward => Strings.loopForward,
              LoopMode.reverse => Strings.loopReverse,
              LoopMode.pingPong => Strings.loopPingPong,
            },
            onChanged: (mode) => controller.loopMode = mode,
          ),
        ),
      ],
    );
  }
}

class _FrameCounter extends StatelessWidget {
  const new({required this.controller});

  final GifStudioController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: controller.frameIndex,
    builder: (context, index, _) => Text(
      Strings.frameCounter(index + 1, controller.frameCount),
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    ),
  );
}

class _FrameScrubber extends StatelessWidget {
  const new({required this.controller});

  final GifStudioController controller;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: controller.frameIndex,
    builder: (context, index, _) => Semantics(
      label: Strings.frameScrubber,
      child: Slider.adaptive(
        value: index.toDouble(),
        max: (controller.frameCount - 1).toDouble(),
        divisions: controller.frameCount - 1,
        semanticFormatterCallback: (value) =>
            Strings.frameCounter(value.round() + 1, controller.frameCount),
        onChangeStart: (_) => controller.pause(),
        onChanged: (value) => controller.seek(value.round()),
      ),
    ),
  );
}

class _LabeledControl extends StatelessWidget {
  const new({required this.label, required this.child});

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
