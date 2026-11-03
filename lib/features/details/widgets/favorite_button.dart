import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';

class FavoriteButton extends StatelessWidget {
  const new({required this.gif, super.key});

  static const double _popFromScale = 0.6;

  final Gif gif;

  Future<void> _toggle(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    unawaited(HapticFeedback.lightImpact());
    final failure = await context.read<FavoritesCubit>().toggle(gif);
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('${Strings.favoriteFailed} ${failure.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesCubit, bool>(
      (cubit) => cubit.state.isFavorite(gif.id),
    );
    return IconButton(
      tooltip: isFavorite ? Strings.removeFavorite : Strings.addFavorite,
      onPressed: () => _toggle(context),
      icon: TweenAnimationBuilder<double>(
        key: ValueKey(isFavorite),
        tween: Tween(begin: _popFromScale, end: 1),
        duration: AppDurations.medium,
        curve: Curves.elasticOut,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        ),
      ),
    );
  }
}
