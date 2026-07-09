import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../widgets/crossball_ui.dart';

/// Thin wrapper over [CrossBallGlassPanel] for list/card content.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return CrossBallGlassPanel(
      onTap: onTap,
      highlight: highlight,
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}
