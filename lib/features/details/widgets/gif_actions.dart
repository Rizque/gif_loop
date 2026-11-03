import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/spacing.dart';
import 'package:gif_loop/features/gifs/domain/gif.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class GifActions extends StatelessWidget {
  const new({required this.gif, super.key});

  final Gif gif;

  Future<void> _copyLink(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(ClipboardData(text: gif.shareUrl));
    unawaited(HapticFeedback.lightImpact());
    messenger.showSnackBar(const SnackBar(content: Text(Strings.linkCopied)));
  }

  Future<void> _openInGiphy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await launchUrl(
      Uri.parse(gif.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      messenger.showSnackBar(const SnackBar(content: Text(Strings.openFailed)));
    }
  }

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Spacing.s,
    runSpacing: Spacing.s,
    children: [
      FilledButton.tonalIcon(
        onPressed: () => _copyLink(context),
        icon: const Icon(Icons.link_rounded),
        label: const Text(Strings.copyLink),
      ),
      _ShareButton(gif: gif),
      FilledButton.tonalIcon(
        onPressed: () => _openInGiphy(context),
        icon: const Icon(Icons.open_in_new_rounded),
        label: const Text(Strings.openInGiphy),
      ),
    ],
  );
}

class _ShareButton extends StatelessWidget {
  const new({required this.gif});

  final Gif gif;

  // iPad presents the share sheet as a popover anchored to this rectangle.
  Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    return box is RenderBox ? box.localToGlobal(Offset.zero) & box.size : null;
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => unawaited(
      SharePlus.instance.share(
        ShareParams(
          uri: Uri.parse(gif.shareUrl),
          subject: gif.title,
          sharePositionOrigin: _origin(context),
        ),
      ),
    ),
    icon: const Icon(Icons.share_rounded),
    label: const Text(Strings.share),
  );
}
