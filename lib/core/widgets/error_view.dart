import 'package:flutter/material.dart';
import 'package:gif_loop/core/errors/failure.dart';
import 'package:gif_loop/core/errors/failure_presentation.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/message_view.dart';

class ErrorView extends StatelessWidget {
  const new({required this.failure, required this.onRetry, super.key});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => MessageView(
    icon: failure.icon,
    title: failure.title,
    message: failure.message,
    action: FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text(Strings.retry),
    ),
  );
}
