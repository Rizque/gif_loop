import 'package:equatable/equatable.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';

class GameRound extends Equatable {
  const new({required this.gif, required this.options, required this.answer});

  final Gif gif;
  final List<String> options;
  final String answer;

  @override
  List<Object?> get props => [gif, options, answer];
}
