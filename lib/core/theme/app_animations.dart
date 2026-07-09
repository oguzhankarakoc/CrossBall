import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Centralized motion curves and transitions.
abstract final class AppAnimations {
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;
  static const Curve decelerate = Curves.decelerate;
  static const Curve spring = Curves.elasticOut;

  static Animation<double> fadeIn(AnimationController controller) {
    return CurvedAnimation(parent: controller, curve: standard);
  }

  static Animation<Offset> slideUp(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: standard));
  }
}

/// Shadow presets — consume via theme brightness.
abstract final class AppShadows {
  static List<BoxShadow> card(bool isDark, {Color? tint}) =>
      AppElevation.cardShadow(isDark, tint: tint);

  static List<BoxShadow> glow(Color color) => AppElevation.limeGlow(color);

  static List<BoxShadow> subtle(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
}
