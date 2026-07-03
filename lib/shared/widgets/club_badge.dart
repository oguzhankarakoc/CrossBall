import 'package:flutter/material.dart';

import '../../core/club_identity/club_identity_registry.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/puzzle/domain/puzzle.dart';
import 'club_badge/club_shield_painter.dart';
import 'club_badge/club_symbol_painter.dart';

/// Premium legal-safe club badge — abstract symbols, no official logos.
class ClubBadge extends StatefulWidget {
  const ClubBadge({
    super.key,
    required this.club,
    this.size = 52,
    this.compact = false,
    this.interactive = true,
    this.showLabel = true,
  });

  final Club club;
  final double size;
  final bool compact;
  final bool interactive;
  final bool showLabel;

  @override
  State<ClubBadge> createState() => _ClubBadgeState();
}

class _ClubBadgeState extends State<ClubBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: AppDuration.medium,
    );
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onHighlightChanged(bool value) {
    setState(() => _pressed = value);
    if (value) {
      _glowController.forward(from: 0);
    } else {
      _glowController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = ClubIdentityRegistry.resolve(widget.club);
    final primary = _parseColor(identity.primaryColor);
    final secondary = _parseColor(identity.secondaryColor);
    final accent = _parseColor(identity.accentColor);
    final shieldH = widget.size * 1.18;

    final badge = AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        final glow = _glowAnim.value + (_pressed ? 0.35 : 0.0);
        return SizedBox(
          width: widget.size,
          height: shieldH,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
              CustomPaint(
                painter: ClubShieldPainter(
                  primary: primary,
                  secondary: secondary,
                  accent: accent,
                  badgeStyle: identity.badgeStyle.name,
                  glowStrength: glow.clamp(0.0, 1.0),
                ),
              ),
              CustomPaint(
                painter: ClubSymbolPainter(
                  symbolType: identity.symbolType,
                  primary: primary,
                  secondary: secondary,
                  accent: accent,
                  shortCode: identity.shortCode,
                ),
              ),
            ],
          ),
          ),
        );
      },
    );

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        widget.interactive
            ? GestureDetector(
                onTapDown: (_) => _onHighlightChanged(true),
                onTapUp: (_) => _onHighlightChanged(false),
                onTapCancel: () => _onHighlightChanged(false),
                child: badge,
              )
            : badge,
        if (!widget.compact && widget.showLabel) ...[
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: widget.size * 1.55,
            child: Text(
              widget.club.shortLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    height: 1.0,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );

    return content;
  }

  Color _parseColor(String hex) {
    final value = hex.replaceFirst('#', '');
    if (value.length == 6) {
      return Color(int.parse('FF$value', radix: 16));
    }
    return Colors.grey;
  }
}

Color parseClubColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  final value = hex.replaceFirst('#', '');
  if (value.length == 6) {
    return Color(int.parse('FF$value', radix: 16));
  }
  return fallback;
}
