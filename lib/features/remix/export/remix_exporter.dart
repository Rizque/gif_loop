import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/result.dart';
import 'package:gif_loop/core/network/cancellation_token.dart';
import 'package:gif_loop/features/remix/engine/remix_limits.dart';
import 'package:gif_loop/features/remix/engine/remix_plan.dart';
import 'package:gif_loop/features/remix/export/caption_overlay.dart';
import 'package:gif_loop/features/remix/export/remix_encoder.dart';

class RemixExporter {
  const new();

  // Isolate.spawn instead of Isolate.run: the encoder reports progress per
  // frame through a SendPort, and the isolate can be killed on cancel.
  Future<Result<Uint8List>> export({
    required Uint8List sourceBytes,
    required RemixPlan plan,
    required RemixSize size,
    required String topText,
    required String bottomText,
    required ValueChanged<double> onProgress,
    required CancellationToken cancellation,
  }) async {
    final overlay = await renderCaptionOverlay(
      width: size.width,
      height: size.height,
      topText: topText,
      bottomText: bottomText,
    );
    if (cancellation.isCancelled) return const Err(UnknownFailure());
    final port = ReceivePort();
    final isolate = await Isolate.spawn(
      _encodeInIsolate,
      _EncodeMessage(
        sendPort: port.sendPort,
        source: TransferableTypedData.fromList([sourceBytes]),
        overlay: overlay == null
            ? null
            : TransferableTypedData.fromList([overlay]),
        frames: plan.frames,
        width: size.width,
        height: size.height,
      ),
      onError: port.sendPort,
      onExit: port.sendPort,
    );
    unawaited(
      cancellation.whenCancelled.then((_) {
        isolate.kill(priority: Isolate.immediate);
        port.close();
      }),
    );
    try {
      await for (final message in port) {
        switch (message) {
          case final double progress:
            onProgress(progress);
          case final TransferableTypedData result:
            return Success(result.materialize().asUint8List());
          default:
            return const Err(DecodingFailure());
        }
      }
      return const Err(UnknownFailure());
    } finally {
      port.close();
      isolate.kill();
    }
  }
}

class _EncodeMessage {
  const new({
    required this.sendPort,
    required this.source,
    required this.overlay,
    required this.frames,
    required this.width,
    required this.height,
  });

  final SendPort sendPort;
  final TransferableTypedData source;
  final TransferableTypedData? overlay;
  final List<RemixFrame> frames;
  final int width;
  final int height;
}

void _encodeInIsolate(_EncodeMessage message) {
  final output = encodeRemix(
    RemixEncodeJob(
      sourceBytes: message.source.materialize().asUint8List(),
      overlayRgba: message.overlay?.materialize().asUint8List(),
      frames: message.frames,
      width: message.width,
      height: message.height,
    ),
    onProgress: message.sendPort.send,
  );
  message.sendPort.send(TransferableTypedData.fromList([output]));
}
