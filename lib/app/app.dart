import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/app/router/app_coordinator.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/connectivity/connectivity_cubit.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/app_theme.dart';
import 'package:gif_loop/core/widgets/offline_banner.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';

class GifLoopApp extends StatelessWidget {
  const new({
    required this.coordinator,
    required this.connectivityCubit,
    required this.favoritesCubit,
    required this.frameLoader,
    super.key,
  });

  final GoRouterCoordinator coordinator;
  final ConnectivityCubit connectivityCubit;
  final FavoritesCubit favoritesCubit;
  final GifFrameLoader frameLoader;

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AppCoordinator>.value(value: coordinator),
      RepositoryProvider.value(value: frameLoader),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: connectivityCubit),
        BlocProvider.value(value: favoritesCubit),
      ],
      child: MaterialApp.router(
        title: Strings.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        debugShowCheckedModeBanner: false,
        routerConfig: coordinator.router,
        builder: (context, child) =>
            OfflineBanner(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}
