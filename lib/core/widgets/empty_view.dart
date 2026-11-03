import 'package:flutter/material.dart';
import 'package:gif_loop/core/widgets/message_view.dart';

class EmptyView extends StatelessWidget {
  const new({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: Icons.sentiment_dissatisfied_rounded,
    title: title,
    message: message,
  );
}
