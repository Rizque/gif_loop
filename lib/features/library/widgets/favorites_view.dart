import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/core/widgets/adaptive_loader.dart';
import 'package:gif_loop/core/widgets/message_view.dart';
import 'package:gif_loop/features/gifs/widgets/gif_masonry_grid.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/favorites_state.dart';

class FavoritesView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FavoritesCubit, FavoritesState>(
        buildWhen: (previous, current) =>
            previous.favorites != current.favorites ||
            previous.isLoaded != current.isLoaded,
        builder: (context, state) {
          if (!state.isLoaded) return const AdaptiveLoader();
          if (state.favorites.isEmpty) return const _EmptyFavorites();
          final coordinator = context.read<AppCoordinator>();
          return CustomScrollView(
            slivers: [
              GifMasonryGrid(
                items: [for (final favorite in state.favorites) favorite.gif],
                previewFileOf: (gif) => state.favoriteOf(gif.id)?.previewFile,
                onGifTap: coordinator.showGifDetails,
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.l)),
            ],
          );
        },
      );
}

class _EmptyFavorites extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: MessageView(
      icon: Icons.favorite_border_rounded,
      title: Strings.noFavoritesTitle,
      message: Strings.noFavoritesMessage,
      action: FilledButton.icon(
        onPressed: context.read<AppCoordinator>().showFeed,
        icon: const Icon(Icons.explore_rounded),
        label: const Text(Strings.exploreGifs),
      ),
    ),
  );
}
