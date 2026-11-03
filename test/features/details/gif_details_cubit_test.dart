import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/details/cubit/gif_details_cubit.dart';
import 'package:gif_loop/features/details/cubit/gif_details_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';

void main() {
  late MockGifRepository repository;
  late MockDominantColorExtractor colorExtractor;

  const color = Color(0xFF7E57C2);
  final gif = makeGif('abc');

  setUp(() {
    repository = MockGifRepository();
    colorExtractor = MockDominantColorExtractor();
    when(() => colorExtractor.extract(any())).thenAnswer((_) async => color);
  });

  GifDetailsCubit buildCubit({bool withGif = false}) => GifDetailsCubit(
    gifId: 'abc',
    initialGif: withGif ? gif : null,
    repository: repository,
    colorExtractor: colorExtractor,
  );

  group('with a GIF passed from the grid', () {
    test('starts in success without a request', () {
      expect(
        buildCubit(withGif: true).state,
        GifDetailsState(status: GifDetailsStatus.success, gif: gif),
      );
    });

    blocTest<GifDetailsCubit, GifDetailsState>(
      'only extracts the dominant color from the preview',
      build: () => buildCubit(withGif: true),
      act: (cubit) => cubit.load(),
      expect: () => [
        GifDetailsState(
          status: GifDetailsStatus.success,
          gif: gif,
          dominantColor: color,
        ),
      ],
      verify: (_) {
        verify(() => colorExtractor.extract(gif.preview.url)).called(1);
        verifyZeroInteractions(repository);
      },
    );

    blocTest<GifDetailsCubit, GifDetailsState>(
      'keeps the theme color when extraction fails',
      setUp: () =>
          when(() => colorExtractor.extract(any()))
              .thenAnswer((_) async => null),
      build: () => buildCubit(withGif: true),
      act: (cubit) => cubit.load(),
      expect: () => <GifDetailsState>[],
    );
  });

  group('opened by id', () {
    blocTest<GifDetailsCubit, GifDetailsState>(
      'fetches the GIF by id',
      setUp: () =>
          when(() => repository.gifById('abc'))
              .thenAnswer((_) async => Success(gif)),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GifDetailsState(status: GifDetailsStatus.loading),
        GifDetailsState(status: GifDetailsStatus.success, gif: gif),
        GifDetailsState(
          status: GifDetailsStatus.success,
          gif: gif,
          dominantColor: color,
        ),
      ],
    );

    blocTest<GifDetailsCubit, GifDetailsState>(
      'emits failure when the request fails',
      setUp: () =>
          when(() => repository.gifById('abc'))
              .thenAnswer((_) async => const Err(NotFoundFailure())),
      build: buildCubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const GifDetailsState(status: GifDetailsStatus.loading),
        const GifDetailsState(
          status: GifDetailsStatus.failure,
          failure: NotFoundFailure(),
        ),
      ],
    );

    blocTest<GifDetailsCubit, GifDetailsState>(
      'reloads on reconnect after a connection failure',
      setUp: () =>
          when(() => repository.gifById('abc'))
              .thenAnswer((_) async => Success(gif)),
      seed: () => const GifDetailsState(
        status: GifDetailsStatus.failure,
        failure: NoConnectionFailure(),
      ),
      build: buildCubit,
      act: (cubit) => cubit.reconnected(),
      skip: 1,
      expect: () => [
        GifDetailsState(status: GifDetailsStatus.success, gif: gif),
        GifDetailsState(
          status: GifDetailsStatus.success,
          gif: gif,
          dominantColor: color,
        ),
      ],
    );

    blocTest<GifDetailsCubit, GifDetailsState>(
      'does not reload on reconnect after a non-network failure',
      seed: () => const GifDetailsState(
        status: GifDetailsStatus.failure,
        failure: NotFoundFailure(),
      ),
      build: buildCubit,
      act: (cubit) => cubit.reconnected(),
      expect: () => <GifDetailsState>[],
      verify: (_) => verifyZeroInteractions(repository),
    );
  });
}
