enum LoopMode { forward, reverse, pingPong }

class PlaybackEngine {
  new(List<Duration> frameDurations)
    : assert(frameDurations.isNotEmpty, 'A GIF has at least one frame'),
      _durations = [
        for (final duration in frameDurations)
          if (duration < minFrameDuration) fallbackFrameDuration else duration,
      ];

  // Browsers play GIF frames shorter than 20 ms at 100 ms, and many GIFs
  // are authored with that behaviour in mind.
  static const Duration minFrameDuration = Duration(milliseconds: 20);
  static const Duration fallbackFrameDuration = Duration(milliseconds: 100);

  final List<Duration> _durations;
  int _index = 0;
  int _direction = 1;
  Duration _accumulated = Duration.zero;
  double _speed = 1;
  LoopMode _mode = LoopMode.forward;

  int get frameCount => _durations.length;

  int get currentIndex => _index;

  double get speed => _speed;

  set speed(double value) {
    assert(value > 0, 'Speed must be positive');
    _speed = value;
  }

  LoopMode get mode => _mode;

  set mode(LoopMode value) {
    _mode = value;
    _direction = value == LoopMode.reverse ? -1 : 1;
  }

  int advance(Duration elapsed) {
    if (frameCount < 2 || elapsed <= Duration.zero) return _index;
    _accumulated += elapsed * _speed;
    final cycle = _cycleDuration.inMicroseconds;
    if (_accumulated.inMicroseconds >= cycle) {
      _accumulated = Duration(
        microseconds: _accumulated.inMicroseconds % cycle,
      );
    }
    while (_accumulated >= _durations[_index]) {
      _accumulated -= _durations[_index];
      _index = _nextIndex();
    }
    return _index;
  }

  void seek(int index) {
    _index = index.clamp(0, frameCount - 1);
    _accumulated = Duration.zero;
  }

  void stepForward() => seek((_index + 1) % frameCount);

  void stepBackward() => seek((_index - 1 + frameCount) % frameCount);

  // Time after which playback returns to the same frame and direction, so
  // long pauses (e.g. a backgrounded app) are skipped in constant time.
  Duration get _cycleDuration {
    final total = _durations.fold(Duration.zero, (sum, d) => sum + d);
    return _mode == LoopMode.pingPong
        ? total * 2 - _durations.first - _durations.last
        : total;
  }

  int _nextIndex() => switch (_mode) {
    LoopMode.forward => (_index + 1) % frameCount,
    LoopMode.reverse => (_index - 1 + frameCount) % frameCount,
    LoopMode.pingPong => _bounce(),
  };

  int _bounce() {
    final next = _index + _direction;
    if (next >= 0 && next < frameCount) return next;
    _direction = -_direction;
    return _index + _direction;
  }
}
