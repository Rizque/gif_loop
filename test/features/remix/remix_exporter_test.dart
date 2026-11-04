import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/remix/export/remix_exporter.dart';
import 'package:image/image.dart' as img;

import '../../helpers/fixture.dart';
import '../../helpers/test_gif.dart';

void main() {
  const exporter = RemixExporter();
  final plan = RemixPlan([
    for (var i = 0; i < 3; i++)
      RemixFrame(i, const Duration(milliseconds: 100)),
  ]);

  Future<Result<Uint8List>> export({
    required CancellationToken cancellation,
    Uint8List? source,
    void Function(double)? onProgress,
  }) => exporter.export(
    sourceBytes: source ?? buildTestGif(),
    plan: plan,
    size: (width: 10, height: 5),
    topText: '',
    bottomText: '',
    onProgress: onProgress ?? (_) {},
    cancellation: cancellation,
  );

  group('RemixExporter', () {
    test('encodes in a background isolate with progress', () async {
      final progress = <double>[];

      final result = await export(
        cancellation: CancellationToken(),
        onProgress: progress.add,
      );

      final decoded = img.GifDecoder().decode(
        (result as Success<Uint8List>).value,
      )!;
      expect(decoded.frames, hasLength(3));
      expect(progress.last, 1);
    });

    test('exports a captioned single-frame GIF', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      final result = await exporter.export(
        sourceBytes: singleFrameGif(),
        plan: const RemixPlan([RemixFrame(0, Duration(milliseconds: 100))]),
        size: (width: 20, height: 10),
        topText: 'Top',
        bottomText: '',
        onProgress: (_) {},
        cancellation: CancellationToken(),
      );

      final decoded = img.GifDecoder().decode(
        (result as Success<Uint8List>).value,
      )!;
      expect(decoded.frames, hasLength(1));
      expect(decoded.width, 20);
    });

    test('a cancelled export returns without output', () async {
      final cancellation = CancellationToken();

      final exporting = export(cancellation: cancellation);
      cancellation.cancel();

      expect(await exporting, isA<Err<Uint8List>>());
    });

    test('an isolate error becomes a decoding failure', () async {
      final result = await export(
        cancellation: CancellationToken(),
        source: Uint8List.fromList([0, 1, 2]),
      );

      expect((result as Err<Uint8List>).failure, const DecodingFailure());
    });
  });
}
