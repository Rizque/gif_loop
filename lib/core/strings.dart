abstract final class Strings {
  static const String appName = 'GifLoop';
  static const String poweredByGiphy = 'Powered by GIPHY';
  static const String retry = 'Retry';

  static const String exploreTab = 'Explore';
  static const String gameTab = 'Game';

  static const String missingApiKeyTitle = 'Missing API key';
  static const String missingApiKeyMessage =
      'Copy env.example.json to env.json, put your GIPHY API key in it and '
      'run:\n\nflutter run --dart-define-from-file=env.json';

  static const String offlineBanner =
      "You're offline. Showing what's already loaded.";

  static const String searchHint = 'Search GIPHY';
  static const String clearSearch = 'Clear search';
  static const String trending = 'Trending';
  static const String loadingGifs = 'Loading GIFs';
  static String resultsFor(String query) => 'Results for "$query"';
  static const String noResultsTitle = 'No GIFs found';
  static String noResultsFor(String query) => 'No GIFs found for "$query".';
  static const String noTrending = 'Nothing is trending right now.';
  static const String endOfResults = "That's all";
  static const String loadMoreFailed = "Couldn't load more GIFs.";
  static const String refreshFailed = "Couldn't refresh the feed.";
  static const String untitled = 'Untitled';

  static const String back = 'Back';
  static const String copyLink = 'Copy link';
  static const String share = 'Share';
  static const String openInGiphy = 'Open in GIPHY';
  static const String linkCopied = 'Link copied to clipboard';
  static const String openFailed = "Couldn't open GIPHY.";
  static const String rating = 'Rating';
  static const String imported = 'Imported';
  static const String dimensions = 'Dimensions';
  static const String fileSize = 'File size';
  static const String frames = 'Frames';

  static const String play = 'Play';
  static const String pause = 'Pause';
  static const String previousFrame = 'Previous frame';
  static const String nextFrame = 'Next frame';
  static const String frameScrubber = 'Frame';
  static const String speed = 'Speed';
  static String speedLabel(double speed) =>
      '${speed == speed.truncateToDouble() ? speed.toInt() : speed}×';
  static const String loopMode = 'Loop';
  static const String loopForward = 'Forward';
  static const String loopReverse = 'Reverse';
  static const String loopPingPong = 'Ping-pong';
  static const String downloadingGif = 'Downloading GIF…';
  static String decodingFrames(int percent) => 'Decoding frames… $percent%';
  static String frameCounter(int current, int total) => '$current / $total';

  static const String gameTitle = 'Guess the GIF';
  static const String mysteryGif = 'Mystery GIF';
  static const String gameQuestion = 'Which search term found this GIF?';
  static String round(int current, int total) => 'Round $current / $total';
  static String score(int value) => 'Score $value';
  static String streak(int value) => 'Streak $value';
  static const String next = 'Next';
  static const String seeResults = 'See results';
  static const String gameOver = 'Game over';
  static String finalScore(int score, int total) => '$score / $total';
  static String bestScore(int value) => 'Best: $value';
  static const String newBestScore = 'New best score!';
  static const String playAgain = 'Play again';
  static const String tapGifForDetails = 'Tap the GIF to see its details';

  static const String noConnectionTitle = 'No connection';
  static const String noConnectionMessage =
      'Check your internet connection and try again.';
  static const String timeoutTitle = 'Taking too long';
  static const String timeoutMessage =
      'GIPHY did not respond in time. Try again.';
  static const String rateLimitedTitle = 'Slow down';
  static const String rateLimitedMessage =
      'GIPHY request limit reached, try again later.';
  static const String unauthorizedTitle = 'Invalid API key';
  static const String unauthorizedMessage =
      'GIPHY rejected the API key. Check GIPHY_API_KEY in env.json.';
  static const String notFoundTitle = 'Not found';
  static const String notFoundMessage = "This GIF doesn't exist anymore.";
  static const String serverTitle = 'GIPHY is having trouble';
  static const String serverMessage = 'Something went wrong on their side.';
  static const String parsingTitle = 'Unexpected response';
  static const String parsingMessage = "GIPHY's response couldn't be read.";
  static const String decodingTitle = "Can't play this GIF";
  static const String decodingMessage = "The GIF's frames couldn't be decoded.";
  static const String unknownTitle = 'Something went wrong';
  static const String unknownMessage = 'Please try again.';
}
