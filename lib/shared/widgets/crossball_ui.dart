import 'package:flutter/material.dart';

export '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors.dart';

/// Subtle pitch-line background matching the app icon aesthetic.
class PitchBackground extends StatelessWidget {
  const PitchBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.background,
                colors.surface,
                colors.background,
              ],
            ),
          ),
        ),
        CustomPaint(
          painter: _PitchLinesPainter(
            lineColor: colors.accent.withValues(alpha: 0.06),
            centerColor: colors.secondaryAccent.withValues(alpha: 0.04),
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

    final midY = size.height * 0.18;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), paint);
    canvas.drawLine(Offset(0, size.height - midY), Offset(size.width, size.height - midY), paint);

    final center = Offset(size.width / 2, size.height * 0.42);
    canvas.drawCircle(center, size.width * 0.22, paint..color = centerColor);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint..color = lineColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PitchLinesPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

/// Branded app bar with optional copper accent underline.
class CrossBallAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CrossBallAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 2);

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return AppBar(
      title: Text(title),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 48),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                colors.accent.withValues(alpha: 0.7),
                Colors.transparent,
              ],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

/// Premium card with icon badge — used across home, stats, settings.
class CrossBallCard extends StatelessWidget {
  const CrossBallCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.5),
                      colors.surfaceElevated,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Icon(icon, color: colors.accent, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// App logo from assets — used in splash, onboarding, home header.
class CrossBallLogo extends StatelessWidget {
  const CrossBallLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: context.cb.accent.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/icon/app_icon.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
