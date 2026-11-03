import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/app.dart';
import 'package:gif_loop/app/di.dart';
import 'package:gif_loop/app/missing_api_key_app.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';

Future<Widget> bootstrap({
  required String giphyApiKey,
  required GetIt getIt,
}) async {
  if (giphyApiKey.trim().isEmpty) return const MissingApiKeyApp();
  await configureDependencies(getIt, giphyApiKey: giphyApiKey);
  return GifLoopApp(
    coordinator: getIt<GoRouterCoordinator>(),
    connectivityCubit: getIt<ConnectivityCubit>(),
    favoritesCubit: getIt<FavoritesCubit>(),
    frameLoader: getIt<GifFrameLoader>(),
  );
}
