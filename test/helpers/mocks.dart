import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/library/domain/library_repository.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:mocktail/mocktail.dart';

class MockGifRepository extends Mock implements GifRepository;

class MockDominantColorExtractor extends Mock implements DominantColorExtractor;

class MockLibraryRepository extends Mock implements LibraryRepository;

class MockGifFrameLoader extends Mock implements GifFrameLoader;

class MockCacheManager extends Mock implements BaseCacheManager;

void registerTestFallbacks() {
  registerFallbackValue(File(''));
  registerFallbackValue(CancellationToken());
}
