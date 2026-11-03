import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

enum StudioStatus { loading, ready, failure }

class GifStudioController extends ChangeNotifier {
  new({required TickerProvider vsync, required this._loader}) {
    _ticker = vsync.createTicker(_onTick);
    _lifecycleListener = AppLifecycleListener(
      onHide: _onAppHidden,
      onShow: _onAppShown,
    );
  }

  static const List<double> speeds = [0.25, 0.5, 1, 2];

  final GifFrameLoader _loader;
  late final Ticker _ticker;
  late final AppLifecycleListener _lifecycleListener;
  final ValueNotifier<int> frameIndex = ValueNotifier(0);

  StudioStatus _status = StudioStatus.loading;
  double? _progress;
  Failure? _failure;
  List<GifFrame> _frames = const [];
  PlaybackEngine? _engine;
  CancellationToken? _loading;
  bool _isPlaying = false;
  bool _resumeWhenShown = false;
  Duration _lastTick = Duration.zero;

  StudioStatus get status => _status;

  double? get progress => _progress;

  Failure? get failure => _failure;

  int get frameCount => _frames.length;

  bool get hasPlayback => frameCount > 1;

  bool get isPlaying => _isPlaying;

  double get speed => _engine?.speed ?? 1;

  LoopMode get loopMode => _engine?.mode ?? LoopMode.forward;

  ui.Image get currentImage => _frames[frameIndex.value].image;

  Future<void> load({String? url, File? file}) async {
    _loading?.cancel();
    final loading = _loading = CancellationToken();
    _pauseTicker();
    _disposeFrames();
    _status = StudioStatus.loading;
    _progress = null;
    _failure = null;
    notifyListeners();

    final result = await _loader.load(
      url: url,
      file: file,
      cancellation: loading,
      onProgress: (progress) {
        if (loading.isCancelled) return;
        _progress = progress;
        notifyListeners();
      },
    );
    if (loading.isCancelled) {
      if (result case Success(value: final frames)) _disposeAll(frames);
      return;
    }
    switch (result) {
      case Success(value: final frames):
        _frames = frames;
        _engine = PlaybackEngine([for (final frame in frames) frame.duration]);
        frameIndex.value = 0;
        _status = StudioStatus.ready;
        if (hasPlayback) _startTicker();
      case Err(:final failure):
        _status = StudioStatus.failure;
        _failure = failure;
    }
    notifyListeners();
  }

  void togglePlay() => _isPlaying ? pause() : play();

  void play() {
    if (!hasPlayback || _isPlaying) return;
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _pauseTicker();
    notifyListeners();
  }

  void seek(int index) {
    final engine = _engine;
    if (engine == null) return;
    pause();
    engine.seek(index);
    frameIndex.value = engine.currentIndex;
  }

  void stepForward() => _step((engine) => engine.stepForward());

  void stepBackward() => _step((engine) => engine.stepBackward());

  set speed(double value) {
    _engine?.speed = value;
    notifyListeners();
  }

  set loopMode(LoopMode value) {
    _engine?.mode = value;
    notifyListeners();
  }

  void _step(void Function(PlaybackEngine engine) move) {
    final engine = _engine;
    if (engine == null || _isPlaying) return;
    move(engine);
    frameIndex.value = engine.currentIndex;
  }

  void _startTicker() {
    _isPlaying = true;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _pauseTicker() {
    _isPlaying = false;
    _ticker.stop();
  }

  void _onTick(Duration elapsed) {
    final delta = elapsed - _lastTick;
    _lastTick = elapsed;
    final engine = _engine;
    if (engine != null) frameIndex.value = engine.advance(delta);
  }

  void _onAppHidden() {
    _resumeWhenShown = _isPlaying;
    pause();
  }

  void _onAppShown() {
    if (_resumeWhenShown) play();
    _resumeWhenShown = false;
  }

  void _disposeFrames() {
    _disposeAll(_frames);
    _frames = const [];
    _engine = null;
  }

  static void _disposeAll(List<GifFrame> frames) {
    for (final frame in frames) {
      frame.image.dispose();
    }
  }

  @override
  void dispose() {
    _loading?.cancel();
    _ticker.dispose();
    _lifecycleListener.dispose();
    frameIndex.dispose();
    _disposeFrames();
    super.dispose();
  }
}
