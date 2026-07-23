import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../widgets/crossball_ui.dart';

/// Shimmer-style loading placeholder using theme surfaces (no extra package).
class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              colors.surfaceElevated.withValues(alpha: 0.45),
              colors.surfaceElevated.withValues(alpha: 0.75),
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}

/// List row skeleton for leaderboards and stats.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.itemCount = 6,
    this.showAvatar = true,
  });

  final int itemCount;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, __) => CrossBallGlassPanel(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (showAvatar) ...[
              const AppSkeletonBox(width: 36, height: 36, borderRadius: 18),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeletonBox(width: 120, height: 14),
                  SizedBox(height: AppSpacing.xs),
                  AppSkeletonBox(width: 180, height: 12),
                ],
              ),
            ),
            const AppSkeletonBox(width: 40, height: 18),
          ],
        ),
      ),
    );
  }
}

/// Stats grid skeleton.
class AppStatsSkeleton extends StatelessWidget {
  const AppStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          children: const [
            Expanded(child: AppSkeletonBox(width: null, height: 88)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: AppSkeletonBox(width: null, height: 88)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppSkeletonBox(width: double.infinity, height: 140),
        const SizedBox(height: AppSpacing.lg),
        const AppSkeletonBox(width: double.infinity, height: 200),
      ],
    );
  }
}

/// 3×3 puzzle grid placeholder — prefer over a lone spinner on load.
class AppPuzzleSkeleton extends StatelessWidget {
  const AppPuzzleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const AppSkeletonBox(width: 160, height: 22),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Column(
              children: [
                for (var row = 0; row < 3; row++) ...[
                  if (row > 0) const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: Row(
                      children: [
                        for (var col = 0; col < 3; col++) ...[
                          if (col > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return AppSkeletonBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  borderRadius: AppRadius.md,
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSkeletonBox(width: double.infinity, height: 48),
        ],
      ),
    );
  }
}
