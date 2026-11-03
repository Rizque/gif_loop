import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

// Plays the remix plan itself (trim, order, speed and merged frames), so the
// preview shows exactly what the export will produce.
class RemixPreviewController {
  new({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  final ValueNotifier<int> sourceIndex = ValueNotifier(0);
  List<RemixFrame> _frames = const [];
  PlaybackEngine? _engine;
  bool _isPinned = false;
  Duration _lastTick = Duration.zero;

  void showPlan(RemixPlan plan) {
    _frames = plan.frames;
    _engine = _frames.isEmpty
        ? null
        : PlaybackEngine([for (final frame in _frames) frame.duration]);
    if (!_isPinned) _restart();
  }

  void pin(int index) {
    _isPinned = true;
    _ticker.stop();
    sourceIndex.value = index;
  }

  void resume() {
    _isPinned = false;
    _restart();
  }

  void _restart() {
    _ticker.stop();
    if (_frames case [final first, ...]) {
      sourceIndex.value = first.sourceIndex;
      if (_frames.length > 1) {
        _lastTick = Duration.zero;
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    final engine = _engine;
    if (engine != null) {
      sourceIndex.value = _frames[engine.advance(delta)].sourceIndex;
    }
  }

  void dispose() {
    _ticker.dispose();
    sourceIndex.dispose();
  }
}
