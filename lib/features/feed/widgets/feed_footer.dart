import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/adaptive_loader.dart';
import 'package:gif_loop/core/widgets/giphy_attribution.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/bloc/feed_state.dart';

class FeedFooter extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final (loadMore, failure, hasReachedEnd) = context
        .select<FeedBloc, (LoadMoreStatus, Failure?, bool)>(
          (bloc) => (
            bloc.state.loadMore,
            bloc.state.loadMoreFailure,
            bloc.state.hasReachedEnd,
          ),
        );
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.l,
        vertical: Spacing.xl,
      ),
      sliver: SliverToBoxAdapter(
        child: switch (loadMore) {
          LoadMoreStatus.loading => const AdaptiveLoader(),
          LoadMoreStatus.failure => _LoadMoreError(
            failure: failure ?? const UnknownFailure(),
          ),
          LoadMoreStatus.idle when hasReachedEnd => const _EndOfResults(),
          LoadMoreStatus.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}

class _LoadMoreError extends StatelessWidget {
  const new({required this.failure});

  final Failure failure;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: Spacing.s,
      children: [
        Icon(failure.icon, color: theme.colorScheme.error),
        Text(
          '${Strings.loadMoreFailed} ${failure.message}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
        TextButton.icon(
          onPressed: () =>
              context.read<FeedBloc>().add(const FeedLoadMoreRetried()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text(Strings.retry),
        ),
      ],
    );
  }
}

class _EndOfResults extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Column(
    spacing: Spacing.xs,
    children: [
      Text(
        Strings.endOfResults,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const GiphyAttribution(),
    ],
  );
}
