import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/adaptive_loader.dart';
import 'package:gif_loop/core/widgets/message_view.dart';
import 'package:gif_loop/features/gifs/widgets/masonry_grid_sliver.dart';
import 'package:gif_loop/features/gifs/widgets/tappable_tile.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/library/cubit/remixes_state.dart';
import 'package:gif_loop/features/library/widgets/remix_hero_tag.dart';

class RemixesView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<RemixesCubit, RemixesState>(
    builder: (context, state) {
      if (!state.isLoaded) return const AdaptiveLoader();
      if (state.remixes.isEmpty) {
        return const SingleChildScrollView(
          child: MessageView(
            icon: Icons.auto_fix_high_rounded,
            title: Strings.noRemixesTitle,
            message: Strings.noRemixesMessage,
          ),
        );
      }
      final coordinator = context.read<AppCoordinator>();
      return CustomScrollView(
        slivers: [
          MasonryGridSliver(
            itemCount: state.remixes.length,
            itemBuilder: (context, index) {
              final remix = state.remixes[index];
              return TappableTile(
                key: ValueKey(remix.id),
                aspectRatio: remix.aspectRatio,
                semanticLabel: Strings.remixOf(remix.sourceTitle),
                heroTag: remixHeroTag(remix.id),
                onTap: () => coordinator.showRemix(remix),
                child: Image.file(
                  remix.file,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              );
            },
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.l)),
        ],
      );
    },
  );
}
