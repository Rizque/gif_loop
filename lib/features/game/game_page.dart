import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/reconnect_listener.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/adaptive_loader.dart';
import 'package:gif_loop/core/widgets/error_view.dart';
import 'package:gif_loop/features/game/cubit/game_cubit.dart';
import 'package:gif_loop/features/game/cubit/game_state.dart';
import 'package:gif_loop/features/game/widgets/game_over_view.dart';
import 'package:gif_loop/features/game/widgets/game_round_view.dart';

class GamePage extends StatelessWidget {
  const new({super.key});

  void _onAnswered(BuildContext context, GameState state) {
    final isCorrect = state.selectedOption == state.round?.answer;
    unawaited(
      isCorrect ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    return ReconnectListener(
      onReconnected: cubit.reconnected,
      child: BlocListener<GameCubit, GameState>(
        listenWhen: (previous, current) =>
            !previous.hasAnswered && current.hasAnswered,
        listener: _onAnswered,
        child: Scaffold(
          appBar: AppBar(title: const Text(Strings.gameTitle)),
          body: SafeArea(
            top: false,
            child: BlocBuilder<GameCubit, GameState>(
              builder: (context, state) => switch (state) {
                GameState(status: GameStatus.playing, round: final round?) =>
                  GameRoundView(state: state, round: round),
                GameState(status: GameStatus.failure) => ErrorView(
                  failure: state.failure ?? const UnknownFailure(),
                  onRetry: cubit.retry,
                ),
                GameState(status: GameStatus.finished) => GameOverView(
                  score: state.score,
                  totalRounds: state.totalRounds,
                  bestScore: state.bestScore,
                  isNewBest: state.isNewBest,
                  onPlayAgain: cubit.start,
                ),
                GameState() => const AdaptiveLoader(),
              },
            ),
          ),
        ),
      ),
    );
  }
}
