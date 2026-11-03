import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/network/giphy_dio.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/gifs/data/gif_repository_impl.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/search/cubit/recent_searches_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/trending_searches_cubit.dart';
import 'package:gif_loop/features/search/data/recent_searches_repository.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> configureDependencies(
  GetIt getIt, {
  required String giphyApiKey,
}) async {
  final connectivityCubit = ConnectivityCubit(Connectivity());
  await connectivityCubit.start();
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
      ),
    )
    ..registerLazySingleton(() => GoRouterCoordinator(getIt));
}
