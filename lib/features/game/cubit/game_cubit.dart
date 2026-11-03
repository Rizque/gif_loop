import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/media/image_prefetcher.dart';
import 'package:gif_loop/features/game/cubit/game_round.dart';
import 'package:gif_loop/features/game/cubit/game_state.dart';
import 'package:gif_loop/features/game/data/best_score_store.dart';
import 'package:gif_loop/features/gifs/domain/content_rating.dart';
import 'package:gif_loop/features/gifs/domain/gif_repository.dart';

class GameCubit extends Cubit<GameState> {
  new({
    required this._repository,
    required BestScoreStore scoreStore,
    required this._imagePrefetcher,
    required List<String> terms,
    Random? random,
  }) : assert(terms.length >= optionsPerRound, 'Not enough terms'),
       _scoreStore = scoreStore,
       _terms = terms,
       _random = random ?? Random(),
       super(
         GameState(
           status: GameStatus.loading,
           roundNumber: 1,
           totalRounds: totalRounds,
           bestScore: scoreStore.bestScore,
         ),
       );

  static const int totalRounds = 10;
  static const int optionsPerRound = 4;
  static const int gifsPerTerm = 10;
  static const int maxRandomOffset = 20;
  static const int _attemptsPerRound = 3;

  final GifRepository _repository;
  final BestScoreStore _scoreStore;
  final ImagePrefetcher _imagePrefetcher;
  final List<String> _terms;
  final Random _random;
  final Set<String> _usedTerms = {};

  Future<Result<GameRound>>? _nextRound;
  Result<GameRound>? _nextRoundResult;

  Future<void> start() async {
    _usedTerms.clear();
    _discardPrefetchedRound();
    emit(
      GameState(
        status: GameStatus.loading,
        roundNumber: 1,
        totalRounds: totalRounds,
        bestScore: _scoreStore.bestScore,
      ),
    );
    _showRound(await _createRound(), roundNumber: 1);
  }

  void answer(String option) {
    final round = state.round;
    if (state.status != GameStatus.playing || round == null) return;
    if (state.hasAnswered) return;
    final isCorrect = option == round.answer;
    emit(
      _stateWith(
        status: GameStatus.playing,
        round: round,
        selectedOption: option,
        score: isCorrect ? state.score + 1 : state.score,
        streak: isCorrect ? state.streak + 1 : 0,
      ),
    );
  }

  Future<void> next() async {
    if (!state.hasAnswered) return;
    if (state.isLastRound) {
      await _finish();
      return;
    }
    final roundNumber = state.roundNumber + 1;
    final pending = _nextRound ?? _createRound();
    final ready = _nextRoundResult;
    _discardPrefetchedRound();
    if (ready != null) {
      _showRound(ready, roundNumber: roundNumber);
      return;
    }
    emit(_stateWith(status: GameStatus.loading, roundNumber: roundNumber));
    _showRound(await pending, roundNumber: roundNumber);
  }

  Future<void> retry() async {
    if (state.status != GameStatus.failure) return;
    emit(_stateWith(status: GameStatus.loading));
    _showRound(await _createRound(), roundNumber: state.roundNumber);
  }

  Future<void> reconnected() async {
    if (state.failure?.isTransient ?? false) await retry();
  }

  void _showRound(Result<GameRound> result, {required int roundNumber}) {
    if (isClosed) return;
    switch (result) {
      case Success(value: final round):
        emit(
          _stateWith(
            status: GameStatus.playing,
            roundNumber: roundNumber,
            round: round,
          ),
        );
        if (roundNumber < totalRounds) _prefetchNextRound();
      case Err(:final failure):
        emit(
          _stateWith(
            status: GameStatus.failure,
            roundNumber: roundNumber,
            failure: failure,
          ),
        );
    }
  }

  Future<void> _finish() async {
    final isNewBest = state.score > state.bestScore;
    if (isNewBest) await _scoreStore.save(state.score);
    if (isClosed) return;
    emit(
      _stateWith(
        status: GameStatus.finished,
        round: state.round,
        selectedOption: state.selectedOption,
        bestScore: isNewBest ? state.score : state.bestScore,
        isNewBest: isNewBest,
      ),
    );
  }

  void _prefetchNextRound() {
    final pending = _nextRound = _createRound();
    unawaited(
      pending.then((result) {
        if (identical(_nextRound, pending)) _nextRoundResult = result;
      }),
    );
  }

  void _discardPrefetchedRound() {
    _nextRound = null;
    _nextRoundResult = null;
  }

  Future<Result<GameRound>> _createRound() async {
    Result<GameRound> result = const Err(UnknownFailure());
    for (var attempt = 0; attempt < _attemptsPerRound; attempt++) {
      result = await _createRoundFor(_pickTerm());
      if (result is Success<GameRound>) return result;
      if (result case Err(:final failure) when failure is! NotFoundFailure) {
        return result;
      }
    }
    return result;
  }

  Future<Result<GameRound>> _createRoundFor(String term) async {
    final result = await _repository.search(
      term,
      offset: _random.nextInt(maxRandomOffset + 1),
      limit: gifsPerTerm,
      rating: ContentRating.g,
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final page) when page.items.isEmpty:
        return const Err(NotFoundFailure());
      case Success(value: final page):
        final gif = page.items[_random.nextInt(page.items.length)];
        await _imagePrefetcher.prefetch(gif.preview.url);
        return Success(
          GameRound(gif: gif, options: _optionsFor(term), answer: term),
        );
    }
  }

  String _pickTerm() {
    final unused = _terms.where((term) => !_usedTerms.contains(term)).toList();
    final candidates = unused.isEmpty ? _terms : unused;
    final term = candidates[_random.nextInt(candidates.length)];
    _usedTerms.add(term);
    return term;
  }

  List<String> _optionsFor(String answer) {
    final wrongOptions = [..._terms.where((term) => term != answer)]
      ..shuffle(_random);
    return [answer, ...wrongOptions.take(optionsPerRound - 1)]
      ..shuffle(_random);
  }

  // Score, streak and best score carry over between states; everything
  // describing the current round must be passed explicitly.
  GameState _stateWith({
    required GameStatus status,
    int? roundNumber,
    GameRound? round,
    String? selectedOption,
    int? score,
    int? streak,
    int? bestScore,
    bool isNewBest = false,
    Failure? failure,
  }) => GameState(
    status: status,
    roundNumber: roundNumber ?? state.roundNumber,
    totalRounds: totalRounds,
    round: round,
    selectedOption: selectedOption,
    score: score ?? state.score,
    streak: streak ?? state.streak,
    bestScore: bestScore ?? state.bestScore,
    isNewBest: isNewBest,
    failure: failure,
  );
}
