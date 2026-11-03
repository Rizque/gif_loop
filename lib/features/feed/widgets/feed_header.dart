import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/giphy_attribution.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';

class FeedHeader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.select<FeedBloc, String>((bloc) => bloc.state.query);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.l,
        Spacing.s,
        Spacing.l,
        Spacing.m,
      ),
      sliver: SliverToBoxAdapter(
        child: Row(
          spacing: Spacing.m,
          children: [
            Expanded(
              child: Text(
                query.isEmpty ? Strings.trending : Strings.resultsFor(query),
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const GiphyAttribution(),
          ],
        ),
      ),
    );
  }
}
