import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

typedef FileDownload = Future<void> Function(String url, File destination);

FileDownload cacheManagerDownload(BaseCacheManager cacheManager) =>
    (url, destination) async {
      final file = await cacheManager.getSingleFile(url);
      await file.copy(destination.path);
    };
