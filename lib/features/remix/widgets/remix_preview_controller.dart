import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

// Plays the remix plan itself (trim, order, speed and merged frames), so the
// preview shows exactly what the export will produce.
class RemixPreviewController extends ChangeNotifier {
  new({required TickerProvider vsync}) {
    _ticker = vsync.createTicker(_onTick);
  }

  late final Ticker _ticker;
  final ValueNotifier<int> sourceIndex = ValueNotifier(0);
  List<RemixFrame> _frames = const [];
  PlaybackEngine? _engine;
  bool _isPinned = false;
  bool? _wantsPlayback;
  Duration _lastTick = Duration.zero;

  // Follows the system reduce-motion setting until the user presses play or
  // pause themselves.
  bool autoplay = true;

  bool get hasPlayback => _frames.length > 1;

  bool get isPlaying => _ticker.isActive;

  void showPlan(RemixPlan plan) {
    _frames = plan.frames;
    _engine = _frames.isEmpty
        ? null
        : PlaybackEngine([for (final frame in _frames) frame.duration]);
    if (!_isPinned) _restart();
  }

  void togglePlay() {
    _wantsPlayback = !isPlaying;
    _isPinned = false;
    _restart();
  }

  void pin(int index) {
    _isPinned = true;
    _ticker.stop();
    sourceIndex.value = index;
    notifyListeners();
  }

  void resume() {
    _isPinned = false;
    _restart();
  }

  void _restart() {
    _ticker.stop();
    if (_frames case [final first, ...]) {
      sourceIndex.value = first.sourceIndex;
      if (hasPlayback && (_wantsPlayback ?? autoplay)) {
        _lastTick = Duration.zero;
        _ticker.start();
      }
    }
    notifyListeners();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    final engine = _engine;
    if (engine != null) {
      sourceIndex.value = _frames[engine.advance(delta)].sourceIndex;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    sourceIndex.dispose();
    super.dispose();
  }
}
