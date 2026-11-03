import 'package:flutter/material.dart';
import 'package:gif_loop/core/config/breakpoints.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/shimmer.dart';

class FeedSkeleton extends StatelessWidget {
  const new({super.key});

  static const List<double> _tileHeights = [180, 120, 220, 150, 200, 130];
  static const int _tilesPerColumn = 4;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) {
        final columns = Breakpoints.gridColumnCount(
          constraints.crossAxisExtent,
        );
        return SliverToBoxAdapter(
          child: Semantics(
            label: Strings.loadingGifs,
            child: Shimmer(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Spacing.s,
                children: [
                  for (var column = 0; column < columns; column++)
                    Expanded(child: _SkeletonColumn(offset: column)),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _SkeletonColumn extends StatelessWidget {
  const new({required this.offset});

  final int offset;

  @override
  Widget build(BuildContext context) => Column(
    spacing: Spacing.s,
    children: [
      for (var row = 0; row < FeedSkeleton._tilesPerColumn; row++)
        Container(
          height:
              FeedSkeleton._tileHeights[(row + offset * 2) %
                  FeedSkeleton._tileHeights.length],
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Radii.tile),
          ),
        ),
    ],
  );
}
