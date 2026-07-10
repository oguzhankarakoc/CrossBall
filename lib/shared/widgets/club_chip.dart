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
        ? colors.lime.withValues(alpha: 0.18)
        : colors.surfaceElevated.withValues(alpha: 0.55);
    final border = highlighted ? colors.lime : colors.cardBorder.withValues(alpha: 0.55);
    final textColor = highlighted ? colors.lime : colors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.smBorder,
        border: Border.all(color: border, width: highlighted ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (highlighted) ...[
            Icon(Icons.check_rounded, size: 12, color: colors.lime),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
}
