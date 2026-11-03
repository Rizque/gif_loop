abstract final class GiphyConfig {
  static const String baseUrl = 'https://api.giphy.com/v1/';
  static const String language = 'en';
  static const String rating = 'pg';
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const int pageSize = 30;

  // GIPHY rejects requests with an offset above these values.
  static const int maxSearchOffset = 4999;
  static const int maxTrendingOffset = 499;
}
