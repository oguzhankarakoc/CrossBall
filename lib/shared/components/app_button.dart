import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Primary action button with consistent padding and minimum touch target.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.style,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : (icon == null
            ? Text(label)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              ));

    final button = icon == null
        ? FilledButton(
            onPressed: loading ? null : onPressed,
            style: style,
            child: child,
          )
        : FilledButton.icon(
            onPressed: loading ? null : onPressed,
            style: style,
            icon: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 20),
            label: Text(label),
          );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
