import 'dart:ui';

import 'package:flutter/material.dart';

export '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// Stadium atmosphere — radial pitch glow + subtle line art.
class PitchBackground extends StatelessWidget {
  const PitchBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.5, -0.35),
              radius: 1.35,
              colors: isLight
                  ? [
                      AppColors.lightBackgroundAlt,
                      colors.background,
                      AppColors.lightBackground,
                    ]
                  : [
                      AppColors.footballGreenDeep.withValues(alpha: 0.45),
                      colors.background,
                      AppColors.darkBackground,
                    ],
            ),
          ),
        ),
        if (!isLight)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors.primary.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
        CustomPaint(
          painter: _PitchLinesPainter(
            lineColor: isLight
                ? colors.primary.withValues(alpha: 0.06)
                : colors.primary.withValues(alpha: 0.05),
            centerColor: isLight
                ? colors.lime.withValues(alpha: 0.04)
                : colors.lime.withValues(alpha: 0.03),
          ),
        ),
        child,
      ],
    );
  }
}

class _PitchLinesPainter extends CustomPainter {
  _PitchLinesPainter({required this.lineColor, required this.centerColor});

  final Color lineColor;
  final Color centerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final midY = size.height * 0.16;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawLine(Offset(0, size.height - midY), Offset(size.width, size.height - midY), paint);

    final center = Offset(size.width / 2, size.height * 0.38);
    canvas.drawCircle(center, size.width * 0.2, paint..color = centerColor);
  }

  @override
  bool shouldRepaint(covariant _PitchLinesPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// Frosted top bar with brand accent.
class CrossBallAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CrossBallAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.tabBar,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? tabBar;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (tabBar?.preferredSize.height ?? 1),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final appBar = AppBar(
      leading: leading,
      title: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
              color: colors.primary,
              fontSize: 15,
            ),
      ),
      actions: actions,
      backgroundColor: colors.surface.withValues(alpha: isDark ? 0.72 : 0.96),
      surfaceTintColor: Colors.transparent,
      bottom: tabBar ??
          PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colors.primary.withValues(alpha: 0.35),
                    colors.lime.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
    );

    if (!isDark) return appBar;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: appBar,
      ),
    );
  }
}

/// Glass morphism panel — cards, sheets, bento tiles.
class CrossBallGlassPanel extends StatelessWidget {
  const CrossBallGlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = AppRadius.xl,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark
                ? colors.surface.withValues(alpha: 0.72)
                : colors.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: highlight ? colors.lime.withValues(alpha: 0.35) : colors.glassBorder,
            ),
            boxShadow: AppElevation.cardShadow(isDark, tint: colors.primary),
          ),
          child: DefaultTextStyle.merge(
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  color: colors.textPrimary,
                ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: colors.lime.withValues(alpha: 0.12),
        child: content,
      ),
    );
  }
}

/// Shared empty-state block for glass panels and list screens.
class CrossBallEmptyState extends StatelessWidget {
  const CrossBallEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.subtitle,
  });

  final String message;
  final IconData icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.12),
              border: Border.all(color: colors.glassBorder),
            ),
            child: Icon(icon, size: 40, color: colors.primary.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// Premium card with icon badge — home, stats, settings.
class CrossBallCard extends StatelessWidget {
  const CrossBallCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);
    final accent = accentColor ?? colors.lime;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: CrossBallGlassPanel(
        onTap: onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm + 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primary.withValues(alpha: 0.35),
                    colors.surfaceElevated.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: AppRadius.lgBorder,
                border: Border.all(color: colors.glassBorder),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Daily challenge hero — gradient overlay + CTA.
class CrossBallHeroCard extends StatelessWidget {
  const CrossBallHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
    this.badge,
    this.badgeIcon,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;
  final String? badge;
  final IconData? badgeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: CrossBallGlassPanel(
        padding: EdgeInsets.zero,
        highlight: true,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      colors.primary.withValues(alpha: 0.22),
                      colors.surface.withValues(alpha: 0.1),
                      colors.background.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm + 4,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.2),
                        borderRadius: AppRadius.pillBorder,
                        border: Border.all(color: colors.primary.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (badgeIcon != null) ...[
                            Icon(badgeIcon, size: 14, color: colors.primary),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            badge!.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(onPressed: onTap, child: Text(actionLabel.toUpperCase())),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Caps label — section headers matching Stadium spec.
class CrossBallLabelCaps extends StatelessWidget {
  const CrossBallLabelCaps(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color ?? colors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 11,
          ),
    );
  }
}

/// XP / level progress strip for dashboard header.
class CrossBallLevelStrip extends StatelessWidget {
  const CrossBallLevelStrip({
    super.key,
    required this.level,
    required this.progress,
    this.label,
    this.isLoading = false,
  });

  final int level;
  final double progress;
  final String? label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final clamped = isLoading ? 0.0 : progress.clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.primary.withValues(alpha: 0.45), width: 2),
            gradient: RadialGradient(
              colors: [
                colors.primary.withValues(alpha: 0.25),
                colors.surfaceElevated,
              ],
            ),
          ),
          child: Icon(Icons.person_rounded, color: colors.primary, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CrossBallLabelCaps(
                isLoading ? '…' : (label ?? 'Level $level'),
                color: colors.textSecondary,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: AppRadius.pillBorder,
                child: SizedBox(
                  height: 6,
                  child: isLoading
                      ? ColoredBox(color: colors.surfaceElevated)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(color: colors.surfaceElevated),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: clamped,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [colors.primary, colors.lime],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Quick navigation dock — visual bottom nav without changing router shell.
class CrossBallQuickNav extends StatelessWidget {
  const CrossBallQuickNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<CrossBallNavItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: isDark ? 0.9 : 0.94),
            border: Border(top: BorderSide(color: colors.glassBorder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  borderRadius: AppRadius.lgBorder,
                  child: AnimatedContainer(
                    duration: AppDuration.medium,
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selected ? colors.primary.withValues(alpha: 0.18) : Colors.transparent,
                      borderRadius: AppRadius.lgBorder,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 22,
                          color: selected ? colors.lime : colors.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: selected ? colors.lime : colors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class CrossBallNavItem {
  const CrossBallNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// App logo — same asset as iOS/Android launcher icon.
class CrossBallLogo extends StatelessWidget {
  const CrossBallLogo({super.key, this.size = 88, this.showBrandRing = false});

  final double size;
  final bool showBrandRing;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final radius = size * 0.22;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: showBrandRing
            ? Border.all(color: colors.lime.withValues(alpha: 0.55), width: 2)
            : null,
        boxShadow: [
          ...AppElevation.limeGlow(colors.lime),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icon/app_icon.png',
        fit: BoxFit.cover,
        width: size,
        height: size,
      ),
    );
  }
}
