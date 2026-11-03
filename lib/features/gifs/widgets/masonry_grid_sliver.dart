import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gif_loop/core/config/breakpoints.dart';
import 'package:gif_loop/core/theme/spacing.dart';

class MasonryGridSliver extends StatelessWidget {
  const new({required this.itemCount, required this.itemBuilder, super.key});

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.m),
    sliver: SliverLayoutBuilder(
      builder: (context, constraints) => SliverMasonryGrid.count(
        crossAxisCount: Breakpoints.gridColumnCount(
          constraints.crossAxisExtent,
        ),
        mainAxisSpacing: Spacing.s,
        crossAxisSpacing: Spacing.s,
        childCount: itemCount,
        itemBuilder: itemBuilder,
      ),
    ),
  );
}
