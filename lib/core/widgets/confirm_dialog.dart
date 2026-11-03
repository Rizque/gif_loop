import 'package:flutter/material.dart';
import 'package:gif_loop/core/platform/adaptive_dialog_action.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showAdaptiveDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog.adaptive(
      title: Text(title),
      content: Text(message),
      actions: [
        AdaptiveDialogAction(
          label: cancelLabel,
          isDefault: true,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        AdaptiveDialogAction(
          label: confirmLabel,
          isDestructive: true,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
