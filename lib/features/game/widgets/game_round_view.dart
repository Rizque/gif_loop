import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/game/cubit/game_cubit.dart';
import 'package:gif_loop/features/game/cubit/game_round.dart';
import 'package:gif_loop/features/game/cubit/game_state.dart';
import 'package:gif_loop/features/game/widgets/answer_options.dart';
import 'package:gif_loop/features/game/widgets/game_gif_card.dart';
import 'package:gif_loop/features/game/widgets/game_header.dart';

class GameRoundView extends StatelessWidget {
  const new({required this.state, required this.round, super.key});

  static const double _landscapeMinWidth = 520;

  final GameState state;
  final GameRound round;

  @override
  Widget build(BuildContext context) {
    final header = GameHeader(
      roundNumber: state.roundNumber,
      totalRounds: state.totalRounds,
      score: state.score,
      streak: state.streak,
    );
    final gifCard = GameGifCard(
      gif: round.gif,
      isRevealed: state.hasAnswered,
      onOpenDetails: () =>
          context.read<AppCoordinator>().showGifDetails(round.gif),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape =
            constraints.maxWidth > constraints.maxHeight &&
            constraints.maxWidth >= _landscapeMinWidth;
        if (isLandscape) {
          return Row(
            spacing: Spacing.l,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: Spacing.m,
                    children: [
                      header,
                      Expanded(child: Center(child: gifCard)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Spacing.l),
                  child: _AnswerPanel(state: state, round: round, columns: 1),
                ),
              ),
            ],
          );
        }
        return CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.m,
                  children: [
                    header,
                    Expanded(child: Center(child: gifCard)),
                    _AnswerPanel(state: state, round: round, columns: 2),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AnswerPanel extends StatelessWidget {
  const new({required this.state, required this.round, required this.columns});

  final GameState state;
  final GameRound round;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Spacing.m,
      children: [
        Text(
          state.hasAnswered ? Strings.tapGifForDetails : Strings.gameQuestion,
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        AnswerOptions(
          options: round.options,
          answer: round.answer,
          selectedOption: state.selectedOption,
          columns: columns,
          onSelected: cubit.answer,
        ),
        Visibility.maintain(
          visible: state.hasAnswered,
          child: FilledButton.icon(
            onPressed: state.hasAnswered ? cubit.next : null,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(state.isLastRound ? Strings.seeResults : Strings.next),
          ),
        ),
      ],
    );
  }
}
