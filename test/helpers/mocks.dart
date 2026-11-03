import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockGifRepository extends Mock implements GifRepository;

void registerTestFallbacks() {
  registerFallbackValue(CancellationToken());
  registerFallbackValue(ContentRating.pg);
}
