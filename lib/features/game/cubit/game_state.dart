import 'package:equatable/equatable.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/features/game/cubit/game_round.dart';

enum GameStatus { loading, playing, failure, finished }

class GameState extends Equatable {
  const new({
    required this.status,
    required this.roundNumber,
    required this.totalRounds,
    this.round,
    this.selectedOption,
    this.score = 0,
    this.streak = 0,
    this.bestScore = 0,
    this.isNewBest = false,
    this.failure,
  });

  final GameStatus status;
  final int roundNumber;
  final int totalRounds;
  final GameRound? round;
  final String? selectedOption;
  final int score;
  final int streak;
  final int bestScore;
  final bool isNewBest;
  final Failure? failure;

  bool get hasAnswered => selectedOption != null;

  bool get isLastRound => roundNumber >= totalRounds;

  @override
  List<Object?> get props => [
    status,
    roundNumber,
    totalRounds,
    round,
    selectedOption,
    score,
    streak,
    bestScore,
    isNewBest,
    failure,
  ];
}
