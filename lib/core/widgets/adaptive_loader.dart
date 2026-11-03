import 'package:flutter/material.dart';

class AdaptiveLoader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator.adaptive());
}
