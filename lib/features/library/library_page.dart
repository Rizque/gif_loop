import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/message_view.dart';

class LibraryPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(Strings.libraryTab)),
    body: MessageView(
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
