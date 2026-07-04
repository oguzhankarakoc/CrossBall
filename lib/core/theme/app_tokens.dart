import 'package:flutter/material.dart';

/// CrossBall design system tokens — synced with `design/stitch/DESIGN.md`.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double containerMargin = 20;
  static const double gutter = 16;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get xxlBorder => BorderRadius.circular(xxl);
  static BorderRadius get pillBorder => BorderRadius.circular(full);
}

abstract final class AppElevation {
  static const double level0 = 0;
  static const double level1 = 2;
  static const double level2 = 6;
  static const double level3 = 12;

  static List<BoxShadow> cardShadow(bool isDark, {Color? tint}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
          blurRadius: isDark ? 16 : 12,
          offset: Offset(0, isDark ? 6 : 3),
        ),
        if (tint != null)
          BoxShadow(
            color: tint.withValues(alpha: isDark ? 0.12 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
      ];

  static List<BoxShadow> limeGlow(Color lime) => [
        BoxShadow(
          color: lime.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];
}

abstract final class AppDuration {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 500);
  static const spring = Duration(milliseconds: 420);
}

abstract final class AppTypography {
  // Stitch type scale — Inter
  static const displayLg = TextStyle(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -0.96, height: 56 / 48);
  static const headlineLg = TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.32, height: 40 / 32);
  static const headlineLgMobile = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, height: 36 / 28);
  static const titleMd = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20);
  static const bodyLg = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16);
  static const bodySm = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14);
  static const labelCaps = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, height: 16 / 12);

  static const display = displayLg;
  static const heading = headlineLgMobile;
  static const title = titleMd;
  static const body = bodyLg;
  static const caption = labelCaps;
}
