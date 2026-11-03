import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/app/router/routes.dart';
import 'package:gif_loop/app/shell/app_shell.dart';
import 'package:gif_loop/app/shell/app_tab.dart';
import 'package:gif_loop/app/shell/shell_branch_container.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/details/gif_details_page.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/feed/bloc/feed_event.dart';
import 'package:gif_loop/features/feed/feed_page.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/library/library_page.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:go_router/go_router.dart';

class GoRouterCoordinator implements AppCoordinator {
  new(this._getIt);

  final GetIt _getIt;
  final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.feed,
    routes: [
      StatefulShellRoute(
        builder: (context, state, navigationShell) => AppShell(
          currentTab: AppTab.values[navigationShell.currentIndex],
          onTabSelected: _showTab,
          child: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            ShellBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.feed,
                builder: (context, state) => MultiBlocProvider(
                  providers: [
                    BlocProvider(
                      create: (_) =>
                          _getIt<FeedBloc>()..add(const FeedStarted()),
                    ),
                    BlocProvider(create: (_) => _getIt<SuggestionsCubit>()),
                    BlocProvider(create: (_) => _createRecentSearchesCubit()),
                    BlocProvider(create: (_) => _createTrendingSearchesCubit()),
                  ],
                  child: const FeedPage(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.library,
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.gifDetailsPattern,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => BlocProvider(
          create: (_) => _createDetailsCubit(state),
          child: const GifDetailsPage(),
        ),
      ),
    ],
  );

  RecentSearchesCubit _createRecentSearchesCubit() {
    final cubit = _getIt<RecentSearchesCubit>();
    unawaited(cubit.load());
    return cubit;
  }

  TrendingSearchesCubit _createTrendingSearchesCubit() {
    final cubit = _getIt<TrendingSearchesCubit>();
    unawaited(cubit.load());
    return cubit;
  }

  GifDetailsCubit _createDetailsCubit(GoRouterState state) {
    final cubit = _getIt<GifDetailsCubit>(
      param1: state.pathParameters[Routes.gifIdParam] ?? '',
      param2: switch (state.extra) {
        final Gif gif => gif,
        _ => null,
      },
    );
    unawaited(cubit.load());
    return cubit;
  }

  void _showTab(AppTab tab) => switch (tab) {
    AppTab.explore => showFeed(),
    AppTab.library => showLibrary(),
  };

  @override
  void showGifDetails(Gif gif) =>
      unawaited(router.push(Routes.gifDetails(gif.id), extra: gif));

  @override
  void showGifDetailsById(String id) =>
      unawaited(router.push(Routes.gifDetails(id)));

  @override
  void showFeed() => router.go(Routes.feed);

  @override
  void showLibrary() => router.go(Routes.library);

  @override
  void back() {
    if (router.canPop()) router.pop();
  }
}
