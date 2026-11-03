import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class GameHeader extends StatelessWidget {
  const new({
    required this.roundNumber,
    required this.totalRounds,
    required this.score,
    required this.streak,
    super.key,
  });

  final int roundNumber;
  final int totalRounds;
  final int score;
  final int streak;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Spacing.s,
    runSpacing: Spacing.s,
    children: [
      _StatChip(
        icon: Icons.flag_rounded,
        label: Strings.round(roundNumber, totalRounds),
      ),
      _StatChip(icon: Icons.star_rounded, label: Strings.score(score)),
      _StatChip(
        icon: Icons.local_fire_department_rounded,
        label: Strings.streak(streak),
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  const new({required this.icon, required this.label});

  static const double _iconSize = 18;

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(Radii.tile),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.m,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: Spacing.xs,
          children: [
            Icon(icon, size: _iconSize, color: colors.onSecondaryContainer),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: colors.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
