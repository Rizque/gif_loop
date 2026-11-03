import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/features/search/data/recent_searches_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/preferences.dart';

void main() {
  late SharedPreferencesAsync preferences;
  late RecentSearchesRepository repository;

  setUp(() {
    preferences = inMemoryPreferences();
    repository = RecentSearchesRepository(preferences);
  });

  group('RecentSearchesRepository', () {
    test('starts empty', () async {
      expect(await repository.load(), isEmpty);
    });

    test('keeps the most recent query first', () async {
      await repository.add('cats');
      await repository.add('dogs');

      expect(await repository.load(), ['dogs', 'cats']);
    });

    test(
      'de-duplicates case-insensitively keeping the newest spelling',
      () async {
        await repository.add('cats');
        await repository.add('dogs');
        await repository.add('CATS');

        expect(await repository.load(), ['CATS', 'dogs']);
      },
    );

    test('trims queries and ignores blank ones', () async {
      await repository.add('  cats ');
      await repository.add('   ');

      expect(await repository.load(), ['cats']);
    });

    test('keeps at most ten entries', () async {
      for (var i = 0; i < 15; i++) {
        await repository.add('query $i');
      }

      final entries = await repository.load();
      expect(entries, hasLength(RecentSearchesRepository.maxEntries));
      expect(entries.first, 'query 14');
      expect(entries.last, 'query 5');
    });

    test('removes a single entry', () async {
      await repository.add('cats');
      await repository.add('dogs');

      expect(await repository.remove('cats'), ['dogs']);
      expect(await repository.load(), ['dogs']);
    });

    test('clears all entries', () async {
      await repository.add('cats');

      expect(await repository.clear(), isEmpty);
      expect(await repository.load(), isEmpty);
    });

    test('persists across instances', () async {
      await repository.add('cats');

      final reopened = RecentSearchesRepository(preferences);

      expect(await reopened.load(), ['cats']);
    });

    test('reads previously stored values', () async {
      final stored = RecentSearchesRepository(
        inMemoryPreferences({
          'recent_searches': ['pizza', 'rain'],
        }),
      );

      expect(await stored.load(), ['pizza', 'rain']);
    });
  });
}
