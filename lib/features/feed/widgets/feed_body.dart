import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/empty_view.dart';
import 'package:gif_loop/core/widgets/error_view.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';
import 'package:gif_loop/features/feed/widgets/feed_footer.dart';
import 'package:gif_loop/features/feed/widgets/feed_skeleton.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/widgets/gif_masonry_grid.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';

class FeedBody extends StatelessWidget {
  const new({super.key});

  // Opening a result is a commitment to the query, so it becomes a recent.
  void _openGif(BuildContext context, Gif gif, String query) {
    if (query.isNotEmpty) {
      unawaited(context.read<RecentSearchesCubit>().add(query));
    }
    context.read<AppCoordinator>().showGifDetails(gif);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<FeedBloc, FeedState>(
    buildWhen: (previous, current) =>
        previous.items != current.items ||
        previous.status != current.status ||
        previous.query != current.query,
    builder: (context, state) {
      if (state.items.isNotEmpty) {
        return SliverMainAxisGroup(
          slivers: [
            GifMasonryGrid(
              items: state.items,
              onGifTap: (gif) => _openGif(context, gif, state.query),
            ),
            const FeedFooter(),
          ],
        );
      }
      return switch (state.status) {
        FeedStatus.initial || FeedStatus.loading => const FeedSkeleton(),
        FeedStatus.failure => SliverFillRemaining(
          hasScrollBody: false,
          child: ErrorView(
            failure: state.failure ?? const UnknownFailure(),
            onRetry: () => context.read<FeedBloc>().add(const FeedRetried()),
          ),
        ),
        FeedStatus.success => SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            title: Strings.noResultsTitle,
            message: state.query.isEmpty
                ? Strings.noTrending
                : Strings.noResultsFor(state.query),
          ),
        ),
      };
    },
  );
}
