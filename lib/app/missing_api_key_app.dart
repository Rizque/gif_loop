import 'package:flutter/material.dart';
import 'package:gif_loop/core/strings.dart';
import 'package:gif_loop/core/theme/app_theme.dart';
import 'package:gif_loop/core/widgets/message_view.dart';

class MissingApiKeyApp extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: Strings.appName,
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    debugShowCheckedModeBanner: false,
    home: const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MessageView(
            icon: Icons.key_rounded,
            title: Strings.missingApiKeyTitle,
            message: Strings.missingApiKeyMessage,
          ),
        ),
      ),
    ),
  );
}
