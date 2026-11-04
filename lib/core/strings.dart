abstract final class Strings {
  static const String appName = 'GifLoop';
  static const String poweredByGiphy = 'Powered by GIPHY';
  static const String retry = 'Retry';

  static const String exploreTab = 'Explore';
  static const String libraryTab = 'Library';

  static const String missingApiKeyTitle = 'Missing API key';
  static const String missingApiKeyMessage =
      'Copy .env.example to .env, put your GIPHY API key in it, then run:'
      '\n\ndart run build_runner build\nflutter run';

  static const String offlineBanner =
      "You're offline. Showing what's already loaded.";

  static const String searchHint = 'Search GIPHY';
  static const String clearSearch = 'Clear search';
  static const String recentSearches = 'Recent';
  static const String clearAll = 'Clear all';
  static String removeRecentSearch(String query) => 'Remove "$query"';
  static const String trendingSearches = 'Trending searches';
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

  static const String noFavoritesTitle = 'No favorites yet';
  static const String noFavoritesMessage =
      'Tap the heart on any GIF to keep it here, even offline.';
  static const String exploreGifs = 'Explore GIFs';
  static const String favorites = 'Favorites';
  static const String myRemixes = 'My remixes';
  static const String noRemixesTitle = 'No remixes yet';
  static const String noRemixesMessage = 'Open any GIF and tap Remix.';

  static const String remix = 'Remix';
  static const String remixEditorTitle = 'Remix';
  static const String trim = 'Trim';
  static String trimRange(int first, int last) => 'Frames $first–$last';
  static const String topText = 'Top text';
  static const String bottomText = 'Bottom text';
  static const String singleFrameRemixHint =
      'This GIF is a single still frame, so you can only add captions.';
  static String remixInfo(int width, int height, int frames, String seconds) =>
      '$width×$height · $frames ${frames == 1 ? 'frame' : 'frames'} · '
      '$seconds s';
  static const String exportGif = 'Export GIF';
  static const String frameLimitExceeded =
      'Shorten the selection (max 150 frames)';
  static String exporting(int percent) => 'Exporting… $percent%';
  static const String cancel = 'Cancel';
  static const String savedToLibrary = 'Saved to Library';
  static const String viewInLibrary = 'View in Library';
  static const String done = 'Done';
  static const String close = 'Close';
  static const String discardChangesTitle = 'Discard changes?';
  static const String discardChangesMessage =
      'Your remix settings will be lost.';
  static const String keepEditing = 'Keep editing';
  static const String discard = 'Discard';
  static const String delete = 'Delete';
  static const String deleteRemixTitle = 'Delete this remix?';
  static const String deleteRemixMessage =
      'The GIF file will be removed from this device.';
  static const String remixNotFoundTitle = 'Remix not found';
  static const String remixNotFoundMessage =
      'It may have been deleted from your Library.';
  static String remixOf(String title) => 'Remix of $title';
  static const String remixedFrom = 'Remixed from';
  static const String created = 'Created';
  static const String duration = 'Duration';
  static String seconds(String value) => '$value s';
  static const String addFavorite = 'Add to favorites';
  static const String removeFavorite = 'Remove from favorites';
  static const String favoriteFailed = "Couldn't save the favorite.";

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
      'GIPHY rejected the API key. Check GIPHY_API_KEY in .env.';
  static const String notFoundTitle = 'Not found';
  static const String notFoundMessage = "This GIF doesn't exist anymore.";
  static const String serverTitle = 'GIPHY is having trouble';
  static const String serverMessage = 'Something went wrong on their side.';
  static const String parsingTitle = 'Unexpected response';
  static const String parsingMessage = "GIPHY's response couldn't be read.";
  static const String decodingTitle = "Can't play this GIF";
  static const String decodingMessage = "The GIF's frames couldn't be decoded.";
  static const String storageTitle = "Couldn't save the file";
  static const String storageMessage =
      'Check that your device has enough free space.';
  static const String unknownTitle = 'Something went wrong';
  static const String unknownMessage = 'Please try again.';
}
