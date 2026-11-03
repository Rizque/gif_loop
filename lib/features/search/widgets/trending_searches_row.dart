import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';

class TrendingSearchesRow extends StatelessWidget {
  const new({required this.onSearch, super.key});

  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final isVisible =
        context.select<FeedBloc, bool>((bloc) => bloc.state.query.isEmpty) &&
        context.select<ConnectivityCubit, bool>(
          (cubit) => cubit.state == ConnectivityStatus.online,
        );
    final terms = context.watch<TrendingSearchesCubit>().state;
    if (!isVisible || terms.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverToBoxAdapter(
      child: Semantics(
        label: Strings.trendingSearches,
        container: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            Spacing.l,
            0,
            Spacing.l,
            Spacing.m,
          ),
          child: Row(
            spacing: Spacing.s,
            children: [
              for (final term in terms)
                ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded),
                  label: Text(term),
                  onPressed: () => onSearch(term),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
