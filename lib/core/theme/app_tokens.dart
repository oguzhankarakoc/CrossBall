import 'package:flutter/material.dart';

/// CrossBall design system tokens — use instead of magic numbers.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
}

abstract final class AppElevation {
  static const double level0 = 0;
  static const double level1 = 2;
  static const double level2 = 4;
  static const double level3 = 8;

  static List<BoxShadow> cardShadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: isDark ? 12 : 8,
          offset: Offset(0, isDark ? 4 : 2),
        ),
      ];
}

abstract final class AppTypography {
  static const display = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8);
  static const heading = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5);
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w500);
}
