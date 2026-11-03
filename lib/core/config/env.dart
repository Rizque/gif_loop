import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract final class Env {
  // Defaults to empty so a missing key shows the "Missing API key" screen
  // instead of failing code generation.
  @EnviedField(varName: 'GIPHY_API_KEY', defaultValue: '')
  static final String giphyApiKey = _Env.giphyApiKey;
}
