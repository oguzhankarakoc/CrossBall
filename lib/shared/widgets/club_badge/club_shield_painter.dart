import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Football shield silhouette with metallic rim — no official crest shapes.
class ClubShieldPainter extends CustomPainter {
  ClubShieldPainter({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.badgeStyle,
    required this.glowStrength,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final String badgeStyle;
  final double glowStrength;

  static Path shieldPath(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..lineTo(w * 0.92, h * 0.14)
      ..lineTo(w * 0.88, h * 0.58)
      ..quadraticBezierTo(w * 0.5, h * 0.98, w * 0.12, h * 0.58)
      ..lineTo(w * 0.08, h * 0.14)
      ..close();
    return path;
  }

  Gradient _fillGradient(Rect rect) {
    return switch (badgeStyle) {
      'horizontal' => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [primary, secondary],
        ),
      'radial' => RadialGradient(
          center: Alignment.topCenter,
          radius: 1.1,
          colors: [primary, secondary, secondary.withValues(alpha: 0.85)],
        ),
      'metallic' => LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(primary, Colors.white, 0.25)!,
            primary,
            secondary,
            Color.lerp(secondary, Colors.black, 0.15)!,
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ),
      _ => LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [primary, secondary],
        ),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = shieldPath(size);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    if (glowStrength > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.35 * glowStrength)
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, 8 * glowStrength),
      );
    }

    canvas.drawPath(
      path,
      Paint()..shader = _fillGradient(rect).createShader(rect),
    );

    // Inner glass highlight
    canvas.save();
    canvas.clipPath(path);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.45),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height * 0.45),
          [
            Colors.white.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
    );
    canvas.restore();

    // Metallic border
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.045
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(size.width, size.height),
          [
            Colors.white.withValues(alpha: 0.85),
            accent.withValues(alpha: 0.9),
            Colors.white.withValues(alpha: 0.5),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..color = Colors.black.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant ClubShieldPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.glowStrength != glowStrength;
}
