import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Compact club label chip for player search cards.
class ClubChip extends StatelessWidget {
  const ClubChip({
    super.key,
    required this.label,
    this.highlighted = false,
  });

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final bg = highlighted
        ? colors.primary.withValues(alpha: 0.22)
        : colors.surfaceElevated;
    final border = highlighted
        ? colors.primary.withValues(alpha: 0.55)
        : colors.cardBorder;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlighted ? colors.textPrimary : colors.textSecondary,
              fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
              fontSize: 11,
            ),
      ),
    );
  }
}
