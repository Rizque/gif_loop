import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class GameOverView extends StatelessWidget {
  const new({
    required this.score,
    required this.totalRounds,
    required this.bestScore,
    required this.isNewBest,
    required this.onPlayAgain,
    super.key,
  });

  static const double _iconSize = 64;

  final int score;
  final int totalRounds;
  final int bestScore;
  final bool isNewBest;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.m,
          children: [
            Icon(
              Icons.emoji_events_rounded,
              size: _iconSize,
              color: theme.colorScheme.primary,
            ),
            Text(Strings.gameOver, style: theme.textTheme.titleLarge),
            Text(
              Strings.finalScore(score, totalRounds),
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              isNewBest ? Strings.newBestScore : Strings.bestScore(bestScore),
              style: theme.textTheme.titleMedium?.copyWith(
                color: isNewBest
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.s),
            FilledButton.icon(
              onPressed: onPlayAgain,
              icon: const Icon(Icons.replay_rounded),
              label: const Text(Strings.playAgain),
            ),
          ],
        ),
      ),
    );
  }
}
