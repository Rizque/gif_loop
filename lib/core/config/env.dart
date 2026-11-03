abstract final class Env {
  static const String giphyApiKey = String.fromEnvironment('GIPHY_API_KEY');

  static bool get hasGiphyApiKey => giphyApiKey.isNotEmpty;
}
