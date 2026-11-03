import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/features/details/widgets/favorite_button.dart';
import 'package:gif_loop/features/library/cubit/favorites_cubit.dart';
import 'package:gif_loop/features/library/domain/favorite_gif.dart';
import 'package:gif_loop/features/library/library_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/gif_factory.dart';
import '../../helpers/mocks.dart';
import '../../helpers/pump_app.dart';

void main() {
  late MockLibraryRepository repository;
  late FavoritesCubit favorites;
  late MockAppCoordinator coordinator;

  final gif = makeGif('abc');

  setUpAll(() => registerFallbackValue(makeGif('fallback')));

  setUp(() {
    repository = MockLibraryRepository();
    favorites = FavoritesCubit(repository);
    coordinator = MockAppCoordinator();
    when(repository.favorites).thenAnswer((_) async => const []);
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpApp(
    BlocProvider.value(value: favorites, child: child),
    coordinator: coordinator,
  );

  group('FavoriteButton', () {
    Widget heart() => Scaffold(
      appBar: AppBar(actions: [FavoriteButton(gif: gif)]),
    );

    testWidgets('fills the heart when favorited', (tester) async {
      when(() => repository.addFavorite(gif)).thenAnswer(
        (_) async => Success(
          FavoriteGif(
            gif: gif,
            previewFile: File('p.webp'),
            fullFile: File('f.gif'),
            addedAt: DateTime(2026),
          ),
        ),
      );

      await pump(tester, heart());
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byTooltip(Strings.addFavorite));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(favorites.state.favoriteOf(gif.id), isNotNull);
    });

    testWidgets('rolls back and shows a snackbar when saving fails', (
      tester,
    ) async {
      final saving = Completer<Result<FavoriteGif>>();
      when(() => repository.addFavorite(gif)).thenAnswer((_) => saving.future);

      await pump(tester, heart());
      await tester.tap(find.byTooltip(Strings.addFavorite));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      saving.complete(const Err(NoConnectionFailure()));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(
        find.textContaining(const NoConnectionFailure().message),
        findsOneWidget,
      );
    });
  });

  group('LibraryPage', () {
    testWidgets('shows the favorites empty state with a way to explore', (
      tester,
    ) async {
      await favorites.load();

      await pump(tester, const LibraryPage());

      expect(find.text(Strings.favorites), findsOneWidget);
      expect(find.text(Strings.noFavoritesTitle), findsOneWidget);
      await tester.tap(find.text(Strings.exploreGifs));
      verify(coordinator.showFeed).called(1);
    });

    testWidgets('switches to the remixes segment', (tester) async {
      await favorites.load();

      await pump(tester, const LibraryPage());
      await tester.tap(find.text(Strings.myRemixes));
      await tester.pump();

      expect(find.text(Strings.noRemixesTitle), findsOneWidget);
    });
  });
}
