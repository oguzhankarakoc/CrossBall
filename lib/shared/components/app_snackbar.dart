import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Consistent snackbar helper — never show raw exceptions.
abstract final class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: duration,
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, icon: Icons.error_outline_rounded);
  }
}
