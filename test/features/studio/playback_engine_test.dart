import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

const _ms100 = Duration(milliseconds: 100);

PlaybackEngine _engine(int frames, {LoopMode mode = LoopMode.forward}) =>
    PlaybackEngine(List.filled(frames, _ms100))..mode = mode;

List<int> _play(PlaybackEngine engine, int ticks, {Duration tick = _ms100}) => [
  for (var i = 0; i < ticks; i++) engine.advance(tick),
];

void main() {
  group('frame durations', () {
    test('treats frames shorter than 20 ms as 100 ms', () {
      final engine = PlaybackEngine(const [
        Duration.zero,
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
        Duration(milliseconds: 40),
      ]);

      expect(engine.advance(const Duration(milliseconds: 99)), 0);
      expect(engine.advance(const Duration(milliseconds: 1)), 1);
      expect(engine.advance(_ms100), 2);
      expect(engine.advance(const Duration(milliseconds: 20)), 3);
      expect(engine.advance(const Duration(milliseconds: 40)), 0);
    });

    test('a zero-duration frame does not make playback spin', () {
      final engine = PlaybackEngine(const [Duration.zero, Duration.zero]);

      expect(engine.advance(const Duration(milliseconds: 99)), 0);
      expect(engine.advance(const Duration(milliseconds: 1)), 1);
    });

    test('respects frames of different lengths', () {
      final engine = PlaybackEngine(const [
        Duration(milliseconds: 50),
        Duration(milliseconds: 200),
      ]);

      expect(engine.advance(const Duration(milliseconds: 50)), 1);
      expect(engine.advance(const Duration(milliseconds: 150)), 1);
      expect(engine.advance(const Duration(milliseconds: 50)), 0);
    });
  });

  group('forward', () {
    test('stays on a frame until its duration has elapsed', () {
      final engine = _engine(3);

      expect(engine.advance(const Duration(milliseconds: 60)), 0);
      expect(engine.advance(const Duration(milliseconds: 39)), 0);
      expect(engine.advance(const Duration(milliseconds: 1)), 1);
    });

    test('wraps around to the first frame', () {
      expect(_play(_engine(3), 4), [1, 2, 0, 1]);
    });

    test('handles elapsed time spanning several frames', () {
      final engine = _engine(5);

      expect(engine.advance(const Duration(milliseconds: 350)), 3);
      expect(engine.advance(const Duration(milliseconds: 50)), 4);
    });

    test('skips whole cycles after a very long pause', () {
      final engine = _engine(4);

      expect(engine.advance(const Duration(hours: 1, milliseconds: 200)), 2);
    });
  });

  group('reverse', () {
    test('plays backwards and wraps to the last frame', () {
      expect(_play(_engine(3, mode: LoopMode.reverse), 4), [2, 1, 0, 2]);
    });

    test('continues from the current frame when the mode changes', () {
      final engine = _engine(4)
        ..advance(const Duration(milliseconds: 200))
        ..mode = LoopMode.reverse;

      expect(_play(engine, 3), [1, 0, 3]);
    });
  });

  group('ping-pong', () {
    test('switches direction at both ends without repeating a frame', () {
      expect(_play(_engine(4, mode: LoopMode.pingPong), 8), [
        1,
        2,
        3,
        2,
        1,
        0,
        1,
        2,
      ]);
    });

    test('bounces correctly when one advance crosses an end', () {
      final engine = _engine(3, mode: LoopMode.pingPong);

      expect(engine.advance(const Duration(milliseconds: 300)), 1);
      expect(engine.advance(const Duration(milliseconds: 100)), 0);
    });

    test('works with two frames', () {
      expect(_play(_engine(2, mode: LoopMode.pingPong), 4), [1, 0, 1, 0]);
    });

    test('skips whole bounce cycles after a very long pause', () {
      final engine = _engine(4, mode: LoopMode.pingPong);
      final cycle = const Duration(milliseconds: 600) * 1000;

      expect(engine.advance(cycle + const Duration(milliseconds: 400)), 2);
    });
  });

  group('speed', () {
    test('2x plays two frames per frame duration', () {
      final engine = _engine(6)..speed = 2;

      expect(_play(engine, 2), [2, 4]);
    });

    test('0.5x needs twice the time per frame', () {
      final engine = _engine(3)..speed = 0.5;

      expect(_play(engine, 4), [0, 1, 1, 2]);
    });

    test('0.25x needs four times the time per frame', () {
      final engine = _engine(3)..speed = 0.25;

      expect(_play(engine, 4), [0, 0, 0, 1]);
    });
  });

  group('seek and step', () {
    test('seek clamps to the frame range and resets frame progress', () {
      final engine = _engine(5)
        ..advance(const Duration(milliseconds: 50))
        ..seek(3);
      expect(engine.currentIndex, 3);
      expect(engine.advance(const Duration(milliseconds: 99)), 3);

      engine.seek(10);
      expect(engine.currentIndex, 4);

      engine.seek(-1);
      expect(engine.currentIndex, 0);
    });

    test('stepping wraps around both ends', () {
      final engine = _engine(3)..stepBackward();
      expect(engine.currentIndex, 2);

      engine.stepForward();
      expect(engine.currentIndex, 0);

      engine.stepForward();
      expect(engine.currentIndex, 1);
    });
  });

  group('single-frame GIF', () {
    test('never leaves the only frame', () {
      final engine = PlaybackEngine(const [_ms100]);

      expect(_play(engine, 3), [0, 0, 0]);
      engine.stepForward();
      expect(engine.currentIndex, 0);
      engine.stepBackward();
      expect(engine.currentIndex, 0);
    });
  });

  test('ignores non-positive elapsed time', () {
    final engine = _engine(3);

    expect(engine.advance(Duration.zero), 0);
    expect(engine.advance(const Duration(milliseconds: -100)), 0);
  });
}
