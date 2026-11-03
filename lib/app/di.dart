import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/config/env.dart';
import 'package:gif_loop/core/network/giphy_dio.dart';
import 'package:gif_loop/features/feed/bloc/feed_bloc.dart';
import 'package:gif_loop/features/gifs/data/gif_repository_impl.dart';
import 'package:gif_loop/features/gifs/data/giphy_api.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';

Future<void> configureDependencies(GetIt getIt) async {
  getIt
    ..registerLazySingleton<Dio>(() => createGiphyDio(apiKey: Env.giphyApiKey))
    ..registerLazySingleton<GifRepository>(
      () => GifRepositoryImpl(GiphyApi(getIt())),
    )
    ..registerFactory(() => FeedBloc(repository: getIt()))
    ..registerLazySingleton(() => GoRouterCoordinator(getIt));
}
