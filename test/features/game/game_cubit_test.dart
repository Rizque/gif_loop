import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/game/cubit/game_cubit.dart';
import 'package:gif_loop/features/game/cubit/game_round.dart';
import 'package:gif_loop/features/game/cubit/game_state.dart';
import 'package:gif_loop/features/game/data/best_score_store.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';

const _terms = ['cat', 'dog', 'pizza', 'rain', 'snow', 'wave'];

void main() {
  late MockGifRepository repository;
  late MockImagePrefetcher imagePrefetcher;

  setUpAll(registerTestFallbacks);

  setUp(() {
    repository = MockGifRepository();
    imagePrefetcher = MockImagePrefetcher();
    when(() => imagePrefetcher.prefetch(any())).thenAnswer((_) async {});
  });

  void stubSearch(Result<GifPage> Function(String term) answer) =>
      when(
        () => repository.search(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          rating: any(named: 'rating'),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer(
        (invocation) async =>
            answer(invocation.positionalArguments.first as String),
      );

  void stubGifsForEveryTerm() => stubSearch(
    (term) => Success(makePage(makeGifs([1, 2, 3], prefix: '$term-'))),
  );

  Future<GameCubit> buildCubit({
    int seed = 7,
    Map<String, Object> preferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues(preferences);
    return GameCubit(
      repository: repository,
      scoreStore: BestScoreStore(await SharedPreferences.getInstance()),
      imagePrefetcher: imagePrefetcher,
      terms: _terms,
      random: Random(seed),
    );
  }

  GameRound roundOf(GameCubit cubit) {
    final round = cubit.state.round;
    expect(round, isNotNull);
    return round!;
  }

  String wrongOptionOf(GameRound round) =>
      round.options.firstWhere((option) => option != round.answer);

  Future<void> playRound(GameCubit cubit, {required bool correctly}) async {
    final round = roundOf(cubit);
    cubit.answer(correctly ? round.answer : wrongOptionOf(round));
    await cubit.next();
  }

  group('rounds', () {
    test('starts with a playable first round', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();

      await cubit.start();

      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.roundNumber, 1);
      expect(cubit.state.totalRounds, GameCubit.totalRounds);
    });

    test('has four unique options with the answer exactly once', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();

      for (var i = 0; i < 5; i++) {
        final round = roundOf(cubit);
        expect(round.options, hasLength(GameCubit.optionsPerRound));
        expect(round.options.toSet(), hasLength(GameCubit.optionsPerRound));
        expect(round.options.where((o) => o == round.answer), hasLength(1));
        expect(_terms, containsAll(round.options));
        expect(round.gif.id, startsWith('${round.answer}-'));
        await playRound(cubit, correctly: true);
      }
    });

    test('is deterministic for a seeded Random', () async {
      stubGifsForEveryTerm();
      final first = await buildCubit(seed: 3);
      final second = await buildCubit(seed: 3);

      await first.start();
      await second.start();

      expect(roundOf(first), roundOf(second));
    });

    test('searches the term with a G rating and a small offset', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();

      await cubit.start();

      final offsets = verify(
        () => repository.search(
          roundOf(cubit).answer,
          offset: captureAny(named: 'offset'),
          limit: GameCubit.gifsPerTerm,
          rating: ContentRating.g,
          cancellation: any(named: 'cancellation'),
        ),
      ).captured;
      expect(
        offsets.single,
        isA<int>().having(
          (offset) => offset,
          'offset',
          inInclusiveRange(0, GameCubit.maxRandomOffset),
        ),
      );
    });

    test('caches the GIF image before showing a round', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();

      await cubit.start();

      verify(() => imagePrefetcher.prefetch(roundOf(cubit).gif.preview.url))
          .called(1);
    });

    test('prefetches the next round while the current one is shown', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();
      await pumpEventQueue();

      verify(
        () => repository.search(
          any(),
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
          rating: any(named: 'rating'),
          cancellation: any(named: 'cancellation'),
        ),
      ).called(2);

      cubit.answer(roundOf(cubit).answer);
      final states = <GameState>[];
      final subscription = cubit.stream.listen(states.add);
      await cubit.next();
      await subscription.cancel();

      expect(states.map((state) => state.status), [GameStatus.playing]);
      expect(cubit.state.roundNumber, 2);
    });

    test('tries another term when a search has no results', () async {
      stubSearch(
        (term) => term == 'cat'
            ? Success(makePage(const []))
            : Success(makePage(makeGifs([1], prefix: '$term-'))),
      );
      final cubit = await buildCubit();

      for (var game = 0; game < 3; game++) {
        await cubit.start();
        expect(cubit.state.status, GameStatus.playing);
        expect(roundOf(cubit).answer, isNot('cat'));
      }
    });
  });

  group('answers', () {
    test('a correct answer scores and extends the streak', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();

      cubit.answer(roundOf(cubit).answer);

      expect(cubit.state.score, 1);
      expect(cubit.state.streak, 1);
      expect(cubit.state.selectedOption, roundOf(cubit).answer);
    });

    test('a wrong answer resets the streak', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();
      await playRound(cubit, correctly: true);
      await playRound(cubit, correctly: true);

      cubit.answer(wrongOptionOf(roundOf(cubit)));

      expect(cubit.state.score, 2);
      expect(cubit.state.streak, 0);
    });

    test('only the first answer of a round counts', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();
      final round = roundOf(cubit);

      cubit
        ..answer(wrongOptionOf(round))
        ..answer(round.answer);

      expect(cubit.state.score, 0);
      expect(cubit.state.selectedOption, wrongOptionOf(round));
    });

    test('next does nothing before answering', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();

      await cubit.next();

      expect(cubit.state.roundNumber, 1);
    });
  });

  group('end of game', () {
    test('finishes after ten rounds and saves a new best score', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit(preferences: {'game_best_score': 4});
      await cubit.start();

      for (var round = 1; round <= GameCubit.totalRounds; round++) {
        expect(cubit.state.roundNumber, round);
        await playRound(cubit, correctly: round != 3);
      }

      expect(cubit.state.status, GameStatus.finished);
      expect(cubit.state.score, 9);
      expect(cubit.state.bestScore, 9);
      expect(cubit.state.isNewBest, isTrue);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getInt('game_best_score'), 9);
    });

    test('keeps a higher previous best score', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit(preferences: {'game_best_score': 10});
      await cubit.start();

      for (var round = 1; round <= GameCubit.totalRounds; round++) {
        await playRound(cubit, correctly: false);
      }

      expect(cubit.state.status, GameStatus.finished);
      expect(cubit.state.bestScore, 10);
      expect(cubit.state.isNewBest, isFalse);
    });

    test('play again resets score and rounds', () async {
      stubGifsForEveryTerm();
      final cubit = await buildCubit();
      await cubit.start();
      for (var round = 1; round <= GameCubit.totalRounds; round++) {
        await playRound(cubit, correctly: true);
      }

      await cubit.start();

      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.roundNumber, 1);
      expect(cubit.state.score, 0);
      expect(cubit.state.streak, 0);
      expect(cubit.state.bestScore, 10);
    });
  });

  group('failures', () {
    test('shows the failure and recovers on retry', () async {
      stubSearch((_) => const Err(TimeoutFailure()));
      final cubit = await buildCubit();

      await cubit.start();
      expect(cubit.state.status, GameStatus.failure);
      expect(cubit.state.failure, const TimeoutFailure());

      stubGifsForEveryTerm();
      await cubit.retry();
      expect(cubit.state.status, GameStatus.playing);
    });

    test(
      'retries automatically on reconnect after a network failure',
      () async {
        stubSearch((_) => const Err(NoConnectionFailure()));
        final cubit = await buildCubit();
        await cubit.start();

        stubGifsForEveryTerm();
        await cubit.reconnected();

        expect(cubit.state.status, GameStatus.playing);
      },
    );

    test('does not retry on reconnect after a rate limit', () async {
      stubSearch((_) => const Err(RateLimitedFailure()));
      final cubit = await buildCubit();
      await cubit.start();

      await cubit.reconnected();

      expect(cubit.state.status, GameStatus.failure);
    });
  });
}
