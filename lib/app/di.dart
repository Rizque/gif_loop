import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/media/file_download.dart';
import 'package:gif_loop/core/network/giphy_dio.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/gifs/data/gif_repository_impl.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/cubit/remixes_cubit.dart';
import 'package:gif_loop/features/library/data/local_library_repository.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:gif_loop/features/remix/cubit/remix_editor_cubit.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:gif_loop/features/search/data/recent_searches_repository.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:gif_loop/features/studio/engine/studio_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> configureDependencies(
  GetIt getIt, {
  required String giphyApiKey,
}) async {
  final connectivityCubit = ConnectivityCubit(Connectivity());
  await connectivityCubit.start();
  final documents = await getApplicationDocumentsDirectory();
  getIt
    ..registerSingleton(connectivityCubit)
    ..registerLazySingleton<Dio>(() => createGiphyDio(apiKey: giphyApiKey))
    ..registerLazySingleton<GifRepository>(
      () => GifRepositoryImpl(GiphyApi(getIt())),
    )
    ..registerLazySingleton<BaseCacheManager>(DefaultCacheManager.new)
    ..registerLazySingleton(() => GifFrameLoader(getIt()))
    ..registerLazySingleton(() => DominantColorExtractor(getIt()))
    ..registerLazySingleton(SharedPreferencesAsync.new)
    ..registerLazySingleton(() => RecentSearchesRepository(getIt()))
    ..registerLazySingleton<LibraryRepository>(
      () => LocalLibraryRepository(
        preferences: getIt(),
        documents: documents,
        download: cacheManagerDownload(getIt()),
      ),
    )
    ..registerLazySingleton(() => FavoritesCubit(getIt()))
    ..registerLazySingleton(() => RemixesCubit(getIt()))
    ..registerLazySingleton(() => const RemixExporter())
    ..registerFactoryParam<RemixEditorCubit, Gif, StudioSettings>(
      (gif, initialSettings) => RemixEditorCubit(
        gif: gif,
        initialSettings: initialSettings,
        frameLoader: getIt(),
        exporter: getIt(),
        libraryRepository: getIt(),
      ),
    )
    ..registerFactory(() => FeedBloc(repository: getIt()))
    ..registerFactory(() => SuggestionsCubit(repository: getIt()))
    ..registerFactory(() => RecentSearchesCubit(getIt()))
    ..registerFactory(() => TrendingSearchesCubit(getIt()))
    ..registerFactoryParam<GifDetailsCubit, String, Gif?>(
      (gifId, initialGif) => GifDetailsCubit(
        gifId: gifId,
        initialGif: initialGif,
        repository: getIt(),
        colorExtractor: getIt(),
        libraryRepository: getIt(),
      ),
    )
    ..registerLazySingleton(() => GoRouterCoordinator(getIt));
  unawaited(getIt<FavoritesCubit>().load());
  unawaited(getIt<RemixesCubit>().load());
}
