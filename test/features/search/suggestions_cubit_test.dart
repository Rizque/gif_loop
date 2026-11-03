import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/features/search/cubit/suggestions_cubit.dart';
import 'package:gif_loop/features/search/cubit/suggestions_state.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

const _debounce = Duration(milliseconds: 20);
const _afterDebounce = Duration(milliseconds: 60);

void main() {
  late MockGifRepository repository;

  setUpAll(registerTestFallbacks);

  setUp(() => repository = MockGifRepository());

  SuggestionsCubit buildCubit() =>
      SuggestionsCubit(repository: repository, debounce: _debounce);

  void stubSuggestions(Result<List<String>> Function(String query) answer) =>
      when(
        () => repository.searchSuggestions(
          any(),
          limit: any(named: 'limit'),
          cancellation: any(named: 'cancellation'),
        ),
      ).thenAnswer(
        (invocation) async =>
            answer(invocation.positionalArguments.first as String),
      );

  void verifyRequests(String query, int times) => verify(
    () => repository.searchSuggestions(
      query,
      limit: SuggestionsCubit.maxSuggestions,
      cancellation: any(named: 'cancellation'),
    ),
  ).called(times);

  group('SuggestionsCubit', () {
    blocTest<SuggestionsCubit, SuggestionsState>(
      'ignores queries shorter than two characters',
      build: buildCubit,
      act: (cubit) async {
        cubit.queryChanged(' c ');
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [const SuggestionsState()],
      verify: (_) => verifyZeroInteractions(repository),
    );

    blocTest<SuggestionsCubit, SuggestionsState>(
      'debounces rapid typing into one request for the last query',
      setUp: () => stubSuggestions((query) => Success(['$query one'])),
      build: buildCubit,
      act: (cubit) async {
        cubit
          ..queryChanged('ca')
          ..queryChanged('cat')
          ..queryChanged('cats');
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [
        const SuggestionsState(query: 'cats', suggestions: ['cats one']),
      ],
      verify: (_) {
        verifyRequests('cats', 1);
        verifyNoMoreInteractions(repository);
      },
    );

    blocTest<SuggestionsCubit, SuggestionsState>(
      'keeps at most six suggestions',
      setUp: () => stubSuggestions(
        (query) => Success([for (var i = 0; i < 10; i++) '$query $i']),
      ),
      build: buildCubit,
      act: (cubit) async {
        cubit.queryChanged('dog');
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [
        isA<SuggestionsState>().having(
          (state) => state.suggestions,
          'suggestions',
          hasLength(SuggestionsCubit.maxSuggestions),
        ),
      ],
    );

    blocTest<SuggestionsCubit, SuggestionsState>(
      'serves a repeated query from the cache without a request',
      setUp: () => stubSuggestions((query) => Success(['$query gif'])),
      build: buildCubit,
      act: (cubit) async {
        cubit.queryChanged('cats');
        await Future<void>.delayed(_afterDebounce);
        cubit.queryChanged('dogs');
        await Future<void>.delayed(_afterDebounce);
        cubit.queryChanged('CATS');
      },
      expect: () => [
        const SuggestionsState(query: 'cats', suggestions: ['cats gif']),
        const SuggestionsState(query: 'dogs', suggestions: ['dogs gif']),
        const SuggestionsState(query: 'CATS', suggestions: ['cats gif']),
      ],
      verify: (_) {
        verifyRequests('cats', 1);
        verifyRequests('dogs', 1);
      },
    );

    blocTest<SuggestionsCubit, SuggestionsState>(
      'shows nothing when the request fails',
      setUp: () => stubSuggestions((_) => const Err(RateLimitedFailure())),
      build: buildCubit,
      seed: () => const SuggestionsState(query: 'ca', suggestions: ['cat']),
      act: (cubit) async {
        cubit.queryChanged('cats');
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [const SuggestionsState(query: 'cats')],
    );

    blocTest<SuggestionsCubit, SuggestionsState>(
      'clearing drops suggestions and cancels a pending request',
      setUp: () => stubSuggestions((query) => Success([query])),
      build: buildCubit,
      seed: () => const SuggestionsState(query: 'ca', suggestions: ['cat']),
      act: (cubit) async {
        cubit
          ..queryChanged('cats')
          ..clear();
        await Future<void>.delayed(_afterDebounce);
      },
      expect: () => [const SuggestionsState()],
      verify: (_) => verifyZeroInteractions(repository),
    );
  });
}
