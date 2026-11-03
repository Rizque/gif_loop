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
import 'package:gif_loop/features/library/domain/remix.dart';
import 'package:gif_loop/features/library/library_page.dart';
import 'package:gif_loop/features/library/library_segment.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/domain/remix_editor_args.dart';
import 'package:gif_loop/features/remix/remix_editor_page.dart';
import 'package:gif_loop/features/remix/remix_viewer_page.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
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
                builder: (context, state) => LibraryPage(
                  requestedSegment:
                      LibrarySegment.values.asNameMap()[state
                          .uri
                          .queryParameters[Routes.librarySegmentParam]],
                ),
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
      GoRoute(
        path: Routes.remixEditorPattern,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) => state.extra is RemixEditorArgs
            ? null
            : Routes.gifDetails(state.pathParameters[Routes.gifIdParam] ?? ''),
        builder: (context, state) => switch (state.extra) {
          final RemixEditorArgs args => BlocProvider(
            create: (_) => _getIt<RemixEditorCubit>(
              param1: args.gif,
              param2: args.initialSettings,
            ),
            child: RemixEditorPage(gif: args.gif),
          ),
          _ => const SizedBox.shrink(),
        },
      ),
      GoRoute(
        path: Routes.remixPattern,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RemixViewerPage(
          remixId: state.pathParameters[Routes.remixIdParam] ?? '',
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
  void showLibrary({LibrarySegment? segment}) => router.go(
    segment == null ? Routes.library : Routes.librarySegment(segment.name),
  );

  @override
  void showRemixEditor(Gif gif, StudioSettings initial) => unawaited(
    router.push(
      Routes.remixEditor(gif.id),
      extra: RemixEditorArgs(gif: gif, initialSettings: initial),
    ),
  );

  @override
  void showRemix(Remix remix) => unawaited(router.push(Routes.remix(remix.id)));

  @override
  void back() {
    if (router.canPop()) router.pop();
  }
}
