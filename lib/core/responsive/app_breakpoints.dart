import 'package:flutter/material.dart';

/// Breakpoint tiers for responsive layout.
enum AppBreakpoint {
  compact,
  medium,
  expanded,
  large;

  static AppBreakpoint fromWidth(double width) {
    if (width >= 1200) return AppBreakpoint.large;
    if (width >= 840) return AppBreakpoint.expanded;
    if (width >= 600) return AppBreakpoint.medium;
    return AppBreakpoint.compact;
  }
}

/// Responsive metrics derived from screen width.
class ResponsiveData {
  const ResponsiveData(this.width);

  final double width;

  AppBreakpoint get breakpoint => AppBreakpoint.fromWidth(width);

  bool get isCompact => breakpoint == AppBreakpoint.compact;
  bool get isTablet => breakpoint.index >= AppBreakpoint.medium.index;
  bool get isDesktop => breakpoint.index >= AppBreakpoint.expanded.index;

  /// Scale spacing tokens for larger screens.
  double get spacingScale => switch (breakpoint) {
        AppBreakpoint.compact => 1,
        AppBreakpoint.medium => 1.05,
        AppBreakpoint.expanded => 1.12,
        AppBreakpoint.large => 1.18,
      };

  double spacing(double base) => base * spacingScale;

  double get containerMargin => switch (breakpoint) {
        AppBreakpoint.compact => 20,
        AppBreakpoint.medium => 24,
        AppBreakpoint.expanded => 32,
        AppBreakpoint.large => 40,
      };

  double get maxContentWidth => switch (breakpoint) {
        AppBreakpoint.compact => width,
        AppBreakpoint.medium => 640,
        AppBreakpoint.expanded => 840,
        AppBreakpoint.large => 960,
      };

  double get iconSize => switch (breakpoint) {
        AppBreakpoint.compact => 24,
        AppBreakpoint.medium => 26,
        AppBreakpoint.expanded => 28,
        AppBreakpoint.large => 30,
      };

  TextStyle scaleTextStyle(TextStyle base) {
    final factor = switch (breakpoint) {
      AppBreakpoint.compact => 1.0,
      AppBreakpoint.medium => 1.02,
      AppBreakpoint.expanded => 1.05,
      AppBreakpoint.large => 1.08,
    };
    return base.copyWith(fontSize: (base.fontSize ?? 14) * factor);
  }
}

extension ResponsiveContext on BuildContext {
  ResponsiveData get responsive {
    final width = MediaQuery.sizeOf(this).width;
    return ResponsiveData(width);
  }
}

/// Centers content with a max width on tablets/desktop.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final data = context.responsive;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: data.maxContentWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.symmetric(horizontal: data.containerMargin),
          child: child,
        ),
      ),
    );
  }
}
