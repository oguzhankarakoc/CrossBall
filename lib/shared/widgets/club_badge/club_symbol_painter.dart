import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/club_identity/club_identity.dart';
import 'club_shield_painter.dart';

/// Abstract geometric symbols — inspired by football culture, not official logos.
class ClubSymbolPainter extends CustomPainter {
  ClubSymbolPainter({
    required this.symbolType,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.shortCode,
  });

  final ClubSymbolType symbolType;
  final Color primary;
  final Color secondary;
  final Color accent;
  final String shortCode;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final clip = ClubShieldPainter.shieldPath(size);
    canvas.save();
    canvas.clipPath(clip);

    switch (symbolType) {
      case ClubSymbolType.abstractStripes:
        _drawStripes(canvas, size);
      case ClubSymbolType.abstractCrown:
        _drawCrown(canvas, center, size);
      case ClubSymbolType.abstractLion:
        _drawLionInspired(canvas, center, size);
      case ClubSymbolType.abstractOrb:
        _drawOrb(canvas, center, size);
      case ClubSymbolType.abstractChevron:
        _drawChevrons(canvas, center, size);
      case ClubSymbolType.abstractDiamond:
        _drawDiamond(canvas, center, size);
      case ClubSymbolType.abstractStar:
        _drawStar(canvas, center, size);
      case ClubSymbolType.abstractWaves:
        _drawWaves(canvas, size);
      case ClubSymbolType.abstractCross:
        _drawCross(canvas, center, size);
      case ClubSymbolType.abstractFlame:
        _drawFlame(canvas, center, size);
      case ClubSymbolType.abstractShield:
        _drawShortCode(canvas, center, size);
    }

    canvas.restore();
  }

  void _drawStripes(Canvas canvas, Size size) {
    final stripeW = size.width / 5;
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeW, 0, stripeW * 0.85, size.height),
        Paint()..color = i.isEven ? accent.withValues(alpha: 0.55) : Colors.transparent,
      );
    }
    _drawShortCode(canvas, Offset(size.width / 2, size.height * 0.62), size, scale: 0.85);
  }

  void _drawCrown(Canvas canvas, Offset center, Size size) {
    final r = size.width * 0.22;
    final path = Path()
      ..moveTo(center.dx - r * 1.6, center.dy + r * 0.4)
      ..lineTo(center.dx - r, center.dy - r * 0.8)
      ..lineTo(center.dx, center.dy + r * 0.1)
      ..lineTo(center.dx + r, center.dy - r * 0.8)
      ..lineTo(center.dx + r * 1.6, center.dy + r * 0.4)
      ..close();
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.9));
    canvas.drawCircle(center, r * 0.35, Paint()..color = secondary.withValues(alpha: 0.8));
    _drawShortCode(canvas, Offset(center.dx, center.dy + r * 1.1), size, scale: 0.75);
  }

  void _drawLionInspired(Canvas canvas, Offset center, Size size) {
    // Geometric mane rays — NOT a lion crest
    final paint = Paint()..color = accent.withValues(alpha: 0.75);
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final inner = center + Offset(math.cos(angle) * 4, math.sin(angle) * 4);
      final outer = center + Offset(math.cos(angle) * size.width * 0.28, math.sin(angle) * size.width * 0.28);
      canvas.drawLine(inner, outer, paint..strokeWidth = size.width * 0.04);
    }
    canvas.drawCircle(center, size.width * 0.12, Paint()..color = secondary.withValues(alpha: 0.9));
    _drawShortCode(canvas, Offset(center.dx, center.dy + size.width * 0.22), size, scale: 0.8);
  }

  void _drawOrb(Canvas canvas, Offset center, Size size) {
    canvas.drawCircle(
      center,
      size.width * 0.2,
      Paint()
        ..shader = RadialGradient(
          colors: [accent, secondary.withValues(alpha: 0.6)],
        ).createShader(Rect.fromCircle(center: center, radius: size.width * 0.2)),
    );
    canvas.drawCircle(
      center,
      size.width * 0.28,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.025
        ..color = accent.withValues(alpha: 0.8),
    );
    _drawShortCode(canvas, Offset(center.dx, center.dy + size.width * 0.32), size, scale: 0.72);
  }

  void _drawChevrons(Canvas canvas, Offset center, Size size) {
    final w = size.width * 0.35;
    for (var i = 0; i < 3; i++) {
      final y = center.dy - size.height * 0.08 + i * size.height * 0.1;
      final path = Path()
        ..moveTo(center.dx - w, y)
        ..lineTo(center.dx, y - size.height * 0.06)
        ..lineTo(center.dx + w, y);
      canvas.drawPath(
        path,
        Paint()
          ..color = accent.withValues(alpha: 0.7 - i * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }
    _drawShortCode(canvas, Offset(center.dx, center.dy + size.height * 0.18), size, scale: 0.78);
  }

  void _drawDiamond(Canvas canvas, Offset center, Size size) {
    final r = size.width * 0.18;
    final path = Path()
      ..moveTo(center.dx, center.dy - r * 1.4)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r * 1.4)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.85));
    _drawShortCode(canvas, Offset(center.dx, center.dy + r * 1.6), size, scale: 0.75);
  }

  void _drawStar(Canvas canvas, Offset center, Size size) {
    final path = Path();
    final outer = size.width * 0.22;
    final inner = outer * 0.45;
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (i * math.pi / 5) - math.pi / 2;
      final point = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.85));
    _drawShortCode(canvas, Offset(center.dx, center.dy + outer * 1.4), size, scale: 0.72);
  }

  void _drawWaves(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.035;
    for (var row = 0; row < 3; row++) {
      final path = Path();
      final y = size.height * (0.35 + row * 0.12);
      for (var x = 0.0; x <= size.width; x += 2) {
        final dy = math.sin((x / size.width) * math.pi * 3 + row) * size.height * 0.04;
        if (x == 0) {
          path.moveTo(x, y + dy);
        } else {
          path.lineTo(x, y + dy);
        }
      }
      canvas.drawPath(path, paint);
    }
    _drawShortCode(canvas, Offset(size.width / 2, size.height * 0.72), size, scale: 0.78);
  }

  void _drawCross(Canvas canvas, Offset center, Size size) {
    final arm = size.width * 0.22;
    final thick = size.width * 0.07;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: thick, height: arm * 2),
        Radius.circular(thick / 2),
      ),
      Paint()..color = accent.withValues(alpha: 0.8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: arm * 2, height: thick),
        Radius.circular(thick / 2),
      ),
      Paint()..color = accent.withValues(alpha: 0.8),
    );
    _drawShortCode(canvas, Offset(center.dx, center.dy + arm * 1.2), size, scale: 0.72);
  }

  void _drawFlame(Canvas canvas, Offset center, Size size) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.2)
      ..quadraticBezierTo(
        center.dx + size.width * 0.15,
        center.dy,
        center.dx,
        center.dy + size.height * 0.18,
      )
      ..quadraticBezierTo(
        center.dx - size.width * 0.15,
        center.dy,
        center.dx,
        center.dy - size.height * 0.2,
      );
    canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.85));
    _drawShortCode(canvas, Offset(center.dx, center.dy + size.height * 0.22), size, scale: 0.78);
  }

  void _drawShortCode(Canvas canvas, Offset center, Size size, {double scale = 1.0}) {
    final fontSize = size.width * 0.22 * scale;
    final textPainter = TextPainter(
      text: TextSpan(
        text: shortCode,
        style: TextStyle(
          color: _contrastingTextColor(primary, secondary),
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          letterSpacing: 0.8,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 2, offset: const Offset(0, 1)),
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  Color _contrastingTextColor(Color a, Color b) {
    final lum = a.computeLuminance() * 0.6 + b.computeLuminance() * 0.4;
    return lum > 0.45 ? Colors.black87 : Colors.white;
  }

  @override
  bool shouldRepaint(covariant ClubSymbolPainter oldDelegate) =>
      oldDelegate.symbolType != symbolType || oldDelegate.shortCode != shortCode;
}
