import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/game/cubit/game_cubit.dart';
import 'package:gif_loop/features/game/cubit/game_round.dart';
import 'package:gif_loop/features/game/cubit/game_state.dart';
import 'package:gif_loop/features/game/game_page.dart';
import 'package:gif_loop/features/game/widgets/game_gif_card.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/pump_app.dart';

class _MockGameCubit extends MockCubit<GameState> implements GameCubit;

void main() {
  late _MockGameCubit cubit;
  late MockAppCoordinator coordinator;

  final round = GameRound(
    gif: makeGif('cat-1'),
    options: const ['dog', 'cat', 'pizza', 'rain'],
    answer: 'cat',
  );
  final playing = GameState(
    status: GameStatus.playing,
    roundNumber: 3,
    totalRounds: 10,
    round: round,
    score: 2,
    streak: 1,
  );
  final answered = GameState(
    status: GameStatus.playing,
    roundNumber: 3,
    totalRounds: 10,
    round: round,
    selectedOption: 'dog',
    score: 2,
  );

  setUpAll(() => registerFallbackValue(makeGif('fallback')));

  setUp(() {
    cubit = _MockGameCubit();
    coordinator = MockAppCoordinator();
    when(cubit.start).thenAnswer((_) async {});
    when(cubit.next).thenAnswer((_) async {});
    when(cubit.retry).thenAnswer((_) async {});
  });

  Future<void> pumpGame(
    WidgetTester tester,
    GameState state, {
    TestScreen screen = TestScreen.phonePortrait,
    double textScale = 1,
  }) {
    when(() => cubit.state).thenReturn(state);
    return tester.pumpApp(
      BlocProvider<GameCubit>.value(value: cubit, child: const GamePage()),
      coordinator: coordinator,
      screen: screen,
      textScale: textScale,
    );
  }

  testWidgets('shows round progress and four options', (tester) async {
    await pumpGame(tester, playing);

    expect(find.text(Strings.round(3, 10)), findsOneWidget);
    expect(find.text(Strings.score(2)), findsOneWidget);
    expect(find.text(Strings.streak(1)), findsOneWidget);
    for (final option in round.options) {
      expect(find.text(option), findsOneWidget);
    }
  });

  testWidgets('selecting an option answers the round', (tester) async {
    await pumpGame(tester, playing);

    await tester.tap(find.text('pizza'));

    verify(() => cubit.answer('pizza')).called(1);
  });

  testWidgets('the GIF does not open details before answering', (tester) async {
    await pumpGame(tester, playing);

    await tester.tap(find.byType(GameGifCard));

    verifyNever(() => coordinator.showGifDetails(any()));
  });

  testWidgets('the GIF opens details after answering', (tester) async {
    await pumpGame(tester, answered);

    await tester.tap(find.byType(GameGifCard));

    verify(() => coordinator.showGifDetails(round.gif)).called(1);
  });

  testWidgets('shows Next after answering', (tester) async {
    await pumpGame(tester, answered);

    await tester.tap(find.text(Strings.next));

    verify(cubit.next).called(1);
  });

  testWidgets('shows the final score and plays again', (tester) async {
    await pumpGame(
      tester,
      const GameState(
        status: GameStatus.finished,
        roundNumber: 10,
        totalRounds: 10,
        score: 8,
        bestScore: 8,
        isNewBest: true,
      ),
    );

    expect(find.text(Strings.finalScore(8, 10)), findsOneWidget);
    expect(find.text(Strings.newBestScore), findsOneWidget);
    await tester.tap(find.text(Strings.playAgain));
    verify(cubit.start).called(1);
  });

  testWidgets('shows an error with Retry', (tester) async {
    await pumpGame(
      tester,
      const GameState(
        status: GameStatus.failure,
        roundNumber: 1,
        totalRounds: 10,
        failure: NoConnectionFailure(),
      ),
    );

    await tester.tap(find.text(Strings.retry));
    verify(cubit.retry).called(1);
  });

  group('layout', () {
    for (final screen in TestScreen.values) {
      testWidgets('fits ${screen.name} at 1.5x text scale', (tester) async {
        await pumpGame(tester, answered, screen: screen, textScale: 1.5);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
