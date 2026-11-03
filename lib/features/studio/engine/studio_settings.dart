import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

class StudioSettings extends Equatable {
  const new({this.speed = 1, this.loopMode = LoopMode.forward});

  static const List<double> speeds = [0.25, 0.5, 1, 2];

  final double speed;
  final LoopMode loopMode;

  @override
  List<Object?> get props => [speed, loopMode];
}
