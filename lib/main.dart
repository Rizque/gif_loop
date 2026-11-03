import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/app.dart';
import 'package:gif_loop/app/di.dart';
import 'package:gif_loop/app/missing_api_key_app.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/config/env.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.hasGiphyApiKey) {
    runApp(const MissingApiKeyApp());
    return;
  }
  final getIt = GetIt.instance;
  await configureDependencies(getIt);
  runApp(
    GifLoopApp(
      coordinator: getIt<GoRouterCoordinator>(),
      frameLoader: getIt<GifFrameLoader>(),
    ),
  );
}
