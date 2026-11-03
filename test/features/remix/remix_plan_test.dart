import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/remix/domain/remix_settings.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

const _ms100 = Duration(milliseconds: 100);

List<Duration> _durations(int count, [Duration duration = _ms100]) =>
    List.filled(count, duration);

RemixSettings _settings(
  int count, {
  int trimStart = 0,
  int? trimEnd,
  double speed = 1,
  LoopMode loopMode = LoopMode.forward,
}) => RemixSettings(
  trimStart: trimStart,
  trimEnd: trimEnd ?? count - 1,
  speed: speed,
  loopMode: loopMode,
);

List<int> _indices(RemixPlan plan) => [
  for (final frame in plan.frames) frame.sourceIndex,
];

List<int> _delaysMs(RemixPlan plan) => [
  for (final frame in plan.frames) frame.duration.inMilliseconds,
];

void main() {
  group('RemixPlan order', () {
    test('plays the trimmed range forward', () {
      final plan = RemixPlan.build(
        _durations(6),
        _settings(6, trimStart: 1, trimEnd: 4),
      );

      expect(_indices(plan), [1, 2, 3, 4]);
    });

    test('plays the trimmed range in reverse', () {
      final plan = RemixPlan.build(
        _durations(6),
        _settings(6, trimStart: 1, trimEnd: 3, loopMode: LoopMode.reverse),
      );

      expect(_indices(plan), [3, 2, 1]);
    });

    test('ping-pong goes back without repeating the end frames', () {
      final plan = RemixPlan.build(
        _durations(5),
        _settings(5, loopMode: LoopMode.pingPong),
      );

      expect(_indices(plan), [0, 1, 2, 3, 4, 3, 2, 1]);
    });

    test('ping-pong over two frames does not duplicate either', () {
      final plan = RemixPlan.build(
        _durations(2),
        _settings(2, loopMode: LoopMode.pingPong),
      );

      expect(_indices(plan), [0, 1]);
    });

    test('clamps a trim range outside the source', () {
      final plan = RemixPlan.build(
        _durations(3),
        _settings(3, trimStart: -2, trimEnd: 10),
      );

      expect(_indices(plan), [0, 1, 2]);
    });

    test('handles a single-frame source', () {
      final plan = RemixPlan.build(
        _durations(1),
        _settings(1, loopMode: LoopMode.pingPong),
      );

      expect(_indices(plan), [0]);
      expect(_delaysMs(plan), [100]);
    });

    test('is empty for an empty source', () {
      expect(RemixPlan.build(const [], _settings(0)).frames, isEmpty);
    });
  });

  group('RemixPlan timing', () {
    test('divides durations by the speed factor', () {
      expect(
        _delaysMs(RemixPlan.build(_durations(2), _settings(2, speed: 2))),
        [50, 50],
      );
      expect(
        _delaysMs(RemixPlan.build(_durations(2), _settings(2, speed: 0.25))),
        [400, 400],
      );
    });

    test('rounds delays to 10 ms while keeping the total', () {
      final plan = RemixPlan.build(
        _durations(3, const Duration(milliseconds: 33)),
        _settings(3),
      );

      expect(_delaysMs(plan).every((delay) => delay % 10 == 0), isTrue);
      expect(plan.duration.inMilliseconds, closeTo(99, 10));
    });

    test('normalizes source frames shorter than 20 ms to 100 ms first', () {
      final plan = RemixPlan.build(const [
        Duration.zero,
        Duration(milliseconds: 10),
        _ms100,
      ], _settings(3));

      expect(_delaysMs(plan), [100, 100, 100]);
    });

    test('merges frames that would drop below 20 ms', () {
      final plan = RemixPlan.build(
        _durations(8, const Duration(milliseconds: 30)),
        _settings(8, speed: 2),
      );

      expect(_delaysMs(plan).every((delay) => delay >= 20), isTrue);
      expect(_indices(plan), [0, 2, 4, 6]);
      expect(plan.duration, const Duration(milliseconds: 120));
    });

    test('keeps the overall duration when merging uneven frames', () {
      final source = [
        for (var i = 0; i < 25; i++) Duration(milliseconds: 20 + i % 3 * 10),
      ];
      final sourceTotalMs = source.fold<int>(
        0,
        (total, duration) => total + duration.inMilliseconds,
      );

      final plan = RemixPlan.build(source, _settings(25, speed: 2));

      expect(_delaysMs(plan).every((delay) => delay >= 20), isTrue);
      expect(plan.duration.inMilliseconds, closeTo(sourceTotalMs / 2, 10));
      expect(plan.frames.length, lessThan(source.length));
    });

    test('a short last frame is merged into the previous one', () {
      final plan = RemixPlan.build(const [
        _ms100,
        Duration(milliseconds: 30),
      ], _settings(2, speed: 2));

      expect(_indices(plan), [0]);
      expect(_delaysMs(plan), [70]);
    });
  });

  group('frame limit', () {
    test('detects plans above the frame cap', () {
      const count = RemixLimits.maxOutputFrames + 1;

      expect(
        RemixPlan.build(_durations(count), _settings(count)).exceedsFrameLimit,
        isTrue,
      );
      expect(
        RemixPlan.build(
          _durations(count),
          _settings(count, trimEnd: count - 2),
        ).exceedsFrameLimit,
        isFalse,
      );
    });
  });

  group('remixOutputSize', () {
    test('never scales up', () {
      expect(remixOutputSize(width: 200, height: 150), (
        width: 200,
        height: 150,
      ));
    });

    test('scales down to the max width keeping the aspect ratio', () {
      expect(remixOutputSize(width: 960, height: 540), (
        width: 480,
        height: 270,
      ));
    });
  });
}
