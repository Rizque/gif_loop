import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/remix/domain/remix_settings.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/studio/engine/frame_timing.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

class RemixFrame extends Equatable {
  const new(this.sourceIndex, this.duration);

  final int sourceIndex;
  final Duration duration;

  @override
  List<Object?> get props => [sourceIndex, duration];
}

// GIF delays are stored in 10 ms units and many viewers play delays below
// 20 ms at 100 ms, so every output delay is a multiple of 10 ms and at least
// 20 ms. Frames that would be shorter are merged (later frames dropped, their
// time added) so the overall playback speed stays correct.
class RemixPlan extends Equatable {
  const new(this.frames);

  factory build(List<Duration> sourceDurations, RemixSettings settings) {
    if (sourceDurations.isEmpty) return const RemixPlan([]);
    final groups = _mergeShortFrames([
      for (final index in _order(sourceDurations.length, settings))
        (
          index,
          normalizeFrameDuration(sourceDurations[index]).inMicroseconds /
              Duration.microsecondsPerMillisecond /
              settings.speed,
        ),
    ]);
    final frames = <RemixFrame>[];
    var carryMs = 0.0;
    for (final (index, durationMs) in groups) {
      final targetMs = durationMs + carryMs;
      final units = max(_minDelayUnits, (targetMs / _delayUnitMs).round());
      carryMs = targetMs - units * _delayUnitMs;
      frames.add(
        RemixFrame(index, Duration(milliseconds: units * _delayUnitMs)),
      );
    }
    return RemixPlan(frames);
  }

  static const int _delayUnitMs = 10;
  static final int _minDelayUnits =
      minGifFrameDuration.inMilliseconds ~/ _delayUnitMs;

  final List<RemixFrame> frames;

  Duration get duration =>
      frames.fold(Duration.zero, (total, frame) => total + frame.duration);

  bool get exceedsFrameLimit => frames.length > RemixLimits.maxOutputFrames;

  static List<int> _order(int sourceCount, RemixSettings settings) {
    final last = sourceCount - 1;
    final start = settings.trimStart.clamp(0, last);
    final end = settings.trimEnd.clamp(start, last);
    final forward = [for (var index = start; index <= end; index++) index];
    return switch (settings.loopMode) {
      LoopMode.forward => forward,
      LoopMode.reverse => forward.reversed.toList(),
      LoopMode.pingPong => [
        ...forward,
        ...forward.reversed.skip(1).take(max(0, forward.length - 2)),
      ],
    };
  }

  static List<(int, double)> _mergeShortFrames(List<(int, double)> frames) {
    final minMs = minGifFrameDuration.inMilliseconds.toDouble();
    final groups = <(int, double)>[];
    for (final (index, durationMs) in frames) {
      if (groups case [..., (final groupIndex, final groupMs)]
          when groupMs < minMs) {
        groups.last = (groupIndex, groupMs + durationMs);
      } else {
        groups.add((index, durationMs));
      }
    }
    if (groups
        case [..., (final previousIndex, final previousMs), (_, final lastMs)]
        when lastMs < minMs) {
      groups
        ..removeLast()
        ..last = (previousIndex, previousMs + lastMs);
    }
    return groups;
  }

  @override
  List<Object?> get props => [frames];
}
