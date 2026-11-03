import 'package:gif_loop/core/media/image_prefetcher.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/details/color/dominant_color_extractor.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:gif_loop/features/studio/decoder/gif_frame_loader.dart';
import 'package:mocktail/mocktail.dart';

class MockGifRepository extends Mock implements GifRepository;

class MockDominantColorExtractor extends Mock implements DominantColorExtractor;

class MockGifFrameLoader extends Mock implements GifFrameLoader;

class MockImagePrefetcher extends Mock implements ImagePrefetcher;

void registerTestFallbacks() {
  registerFallbackValue(CancellationToken());
  registerFallbackValue(ContentRating.pg);
}
