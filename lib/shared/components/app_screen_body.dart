import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../widgets/crossball_ui.dart';

/// Standard screen body with SafeArea + pitch background + optional scroll.
class AppScreenBody extends StatelessWidget {
  const AppScreenBody({
    super.key,
    required this.child,
    this.padding,
    this.scrollable = false,
    this.bottom = true,
    this.top = true,
    this.left = true,
    this.right = true,
    this.includeBottomNavInset = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  /// When true, adds extra bottom padding for shell bottom navigation.
  final bool includeBottomNavInset;

  @override
  Widget build(BuildContext context) {
    final bottomInset = includeBottomNavInset
        ? MediaQuery.paddingOf(context).bottom + AppSpacing.md
        : 0.0;

    Widget content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content,
      );
    }

    return PitchBackground(
      child: SafeArea(
        top: top,
        bottom: bottom,
        left: left,
        right: right,
        minimum: EdgeInsets.only(bottom: bottomInset),
        child: content,
      ),
    );
  }
}
