import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/country_flags.dart';
import 'country_flag_badge.dart';

/// Legal-safe procedural player silhouette — no real photos.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.seed,
    this.size = 52,
    this.nationalityCode,
  });

  final String seed;
  final double size;
  final String? nationalityCode;

  @override
  Widget build(BuildContext context) {
    final hash = seed.hashCode.abs();
    final hue = hash % 360;
    final primary = HSLColor.fromAHSL(1, hue.toDouble(), 0.42, 0.38).toColor();
    final accent = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.35, 0.55).toColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: 0.92),
            accent.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        boxShadow: AppElevation.cardShadow(Theme.of(context).brightness == Brightness.dark),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        painter: _PlayerSilhouettePainter(
          variant: hash % 5,
          skinTone: HSLColor.fromAHSL(1, (hue + 18) % 360, 0.28, 0.62).toColor(),
        ),
        child: nationalityCode != null && CountryFlags.hasKnownNationality(nationalityCode)
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CountryFlagBadge(
                    code: nationalityCode,
                    size: CountryFlagSize.xs,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _PlayerSilhouettePainter extends CustomPainter {
  _PlayerSilhouettePainter({required this.variant, required this.skinTone});

  final int variant;
  final Color skinTone;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final silhouette = Paint()..color = Colors.black.withValues(alpha: 0.22);
    final highlight = Paint()..color = Colors.white.withValues(alpha: 0.08);

    final headR = w * 0.17;
    final headCenter = Offset(w * 0.5, h * (0.28 + variant * 0.01));
    canvas.drawCircle(headCenter, headR, Paint()..color = skinTone.withValues(alpha: 0.85));
    canvas.drawCircle(headCenter, headR, silhouette..style = PaintingStyle.stroke..strokeWidth = 1);

    final bodyPath = Path();
    final lean = (variant - 2) * 0.03;
    bodyPath.moveTo(w * (0.32 + lean), h * 0.48);
    bodyPath.quadraticBezierTo(w * 0.5, h * 0.42, w * (0.68 + lean), h * 0.48);
    bodyPath.lineTo(w * (0.74 + lean), h * 0.88);
    bodyPath.quadraticBezierTo(w * 0.5, h * 0.94, w * (0.26 + lean), h * 0.88);
    bodyPath.close();
    canvas.drawPath(bodyPath, silhouette);

    if (variant.isEven) {
      canvas.drawArc(
        Rect.fromCircle(center: headCenter, radius: headR * 1.15),
        math.pi * 0.15,
        math.pi * 0.7,
        false,
        highlight..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerSilhouettePainter oldDelegate) =>
      oldDelegate.variant != variant || oldDelegate.skinTone != skinTone;
}
