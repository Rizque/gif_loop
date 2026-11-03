import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImagePrefetcher {
  const new(this._cacheManager);

  final BaseCacheManager _cacheManager;

  // Prefetching is an optimisation: on failure the image simply loads when
  // it is displayed.
  Future<void> prefetch(String url) async {
    try {
      await _cacheManager.getSingleFile(url);
    } on Exception {
      return;
    }
  }
}
