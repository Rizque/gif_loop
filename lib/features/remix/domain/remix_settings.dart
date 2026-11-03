import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/studio/engine/playback_engine.dart';

class RemixSettings extends Equatable {
  const new({
    required this.trimStart,
    required this.trimEnd,
    this.speed = 1,
    this.loopMode = LoopMode.forward,
    this.topText = '',
    this.bottomText = '',
  });

  final int trimStart;
  final int trimEnd;
  final double speed;
  final LoopMode loopMode;
  final String topText;
  final String bottomText;

  bool get hasCaptions =>
      topText.trim().isNotEmpty || bottomText.trim().isNotEmpty;

  RemixSettings copyWith({
    int? trimStart,
    int? trimEnd,
    double? speed,
    LoopMode? loopMode,
    String? topText,
    String? bottomText,
  }) => RemixSettings(
    trimStart: trimStart ?? this.trimStart,
    trimEnd: trimEnd ?? this.trimEnd,
    speed: speed ?? this.speed,
    loopMode: loopMode ?? this.loopMode,
    topText: topText ?? this.topText,
    bottomText: bottomText ?? this.bottomText,
  );

  @override
  List<Object?> get props => [
    trimStart,
    trimEnd,
    speed,
    loopMode,
    topText,
    bottomText,
  ];
}
