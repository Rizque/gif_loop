import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

const String _gifMimeType = 'image/gif';

// iPad presents the share sheet as a popover anchored to the tapped widget.
Future<void> shareGifFile(BuildContext context, File file) {
  final box = context.findRenderObject();
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: _gifMimeType)],
      sharePositionOrigin: box is RenderBox
          ? box.localToGlobal(Offset.zero) & box.size
          : null,
    ),
  );
}
