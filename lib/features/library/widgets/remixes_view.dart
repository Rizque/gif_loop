import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/widgets/message_view.dart';

class RemixesView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const SingleChildScrollView(
    child: MessageView(
      icon: Icons.auto_fix_high_rounded,
      title: Strings.noRemixesTitle,
      message: Strings.noRemixesMessage,
    ),
  );
}
