import 'package:flutter/material.dart';

import '../../core/utils/player_display_name.dart';
import '../widgets/crossball_ui.dart';

/// Accessible avatar with minimum 44dp touch semantics when tappable.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.label,
    this.radius = 18,
    this.onTap,
  });

  final String label;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final anonymous = isResolvedAnonymousLabel(label);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: anonymous
          ? colors.surfaceElevated.withValues(alpha: 0.65)
          : colors.primary.withValues(alpha: 0.25),
      child: Text(
        playerAvatarInitial(label),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: anonymous ? colors.textSecondary : colors.accent,
            ),
      ),
    );

    if (onTap == null) {
      return Semantics(label: label, child: avatar);
    }

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      ),
    );
  }
}
