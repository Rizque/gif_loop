import 'package:flutter/material.dart';
import 'package:gif_loop/features/remix/export/caption_fit.dart';

// Shared by the live preview and the export overlay, so the exported GIF
// looks exactly like the preview (sizes are relative to the canvas width).
class CaptionPainter extends CustomPainter {
  const new({required this.topText, required this.bottomText});

  static const double _maxFontFactor = 0.11;
  static const double _minFontFactor = 0.045;
  static const double _strokeFactor = 0.14;
  static const double _paddingFactor = 0.03;
  static const double _lineHeight = 1.1;
  static const int _maxLines = 2;

  final String topText;
  final String bottomText;

  @override
  void paint(Canvas canvas, Size size) {
    _paintCaption(canvas, size, topText.trim(), atTop: true);
    _paintCaption(canvas, size, bottomText.trim(), atTop: false);
  }

  void _paintCaption(
    Canvas canvas,
    Size size,
    String text, {
    required bool atTop,
  }) {
    if (text.isEmpty || size.isEmpty) return;
    final padding = size.width * _paddingFactor;
    final maxWidth = size.width - padding * 2;
    final fontSize = fitCaptionFontSize(
      maxSize: size.width * _maxFontFactor,
      minSize: size.width * _minFontFactor,
      fits: (fontSize) {
        final painter = _layout(text, fontSize, maxWidth, Paint());
        final fits = !painter.didExceedMaxLines;
        painter.dispose();
        return fits;
      },
    );
    final stroke = _layout(
      text,
      fontSize,
      maxWidth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = fontSize * _strokeFactor
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.black,
    );
    final fill = _layout(
      text,
      fontSize,
      maxWidth,
      Paint()..color = Colors.white,
    );
    final offset = Offset(
      padding,
      atTop ? padding : size.height - padding - fill.height,
    );
    stroke.paint(canvas, offset);
    fill.paint(canvas, offset);
    stroke.dispose();
    fill.dispose();
  }

  TextPainter _layout(
    String text,
    double fontSize,
    double maxWidth,
    Paint foreground,
  ) => TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: _lineHeight,
        foreground: foreground,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: _maxLines,
    ellipsis: '…',
  )..layout(minWidth: maxWidth, maxWidth: maxWidth);

  @override
  bool shouldRepaint(CaptionPainter oldDelegate) =>
      oldDelegate.topText != topText || oldDelegate.bottomText != bottomText;
}
