import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gif_loop/app/bootstrap.dart';
import 'package:gif_loop/app/missing_api_key_app.dart';
import 'package:gif_loop/core/strings.dart';

void main() {
  group('bootstrap', () {
    for (final key in ['', '   ']) {
      test('shows the missing key screen for "$key"', () async {
        final getIt = GetIt.asNewInstance();

        final app = await bootstrap(giphyApiKey: key, getIt: getIt);

        expect(app, isA<MissingApiKeyApp>());
        expect(getIt.allReadySync(), isTrue);
      });
    }

    testWidgets('the missing key screen explains how to add a key', (
      tester,
    ) async {
      await tester.pumpWidget(const MissingApiKeyApp());

      expect(find.text(Strings.missingApiKeyTitle), findsOneWidget);
      expect(find.text(Strings.missingApiKeyMessage), findsOneWidget);
    });
  });
}
