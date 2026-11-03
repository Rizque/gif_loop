import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/app.dart';
import 'package:gif_loop/app/di.dart';
import 'package:gif_loop/app/missing_api_key_app.dart';
import 'package:gif_loop/app/router/go_router_coordinator.dart';
import 'package:gif_loop/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Env.hasGiphyApiKey) {
    runApp(const MissingApiKeyApp());
    return;
  }
  final getIt = GetIt.instance;
  await configureDependencies(getIt);
  runApp(GifLoopApp(coordinator: getIt<GoRouterCoordinator>()));
}
