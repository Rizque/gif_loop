import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/bootstrap.dart';
import 'package:gif_loop/core/config/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await bootstrap(giphyApiKey: Env.giphyApiKey, getIt: GetIt.instance));
}
