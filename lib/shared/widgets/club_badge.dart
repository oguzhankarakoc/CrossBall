import 'package:flutter/material.dart';

import '../../core/club_identity/club_badge_tokens.dart';
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
    this.visualState = ClubBadgeVisualState.normal,
  });

  final Club club;
  final double size;
  final bool compact;
  final bool interactive;
  final bool showLabel;
  final ClubBadgeVisualState visualState;

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
      duration: ClubBadgeTokens.stateDuration,
    );
    _glowAnim = CurvedAnimation(parent: _glowController, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(covariant ClubBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visualState != widget.visualState) {
      if (widget.visualState != ClubBadgeVisualState.normal) {
        _glowController.forward(from: 0);
      } else {
        _glowController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _onHighlightChanged(bool value) {
    if (!widget.interactive) return;
    setState(() => _pressed = value);
    if (value) {
      _glowController.forward(from: 0);
    } else if (widget.visualState == ClubBadgeVisualState.normal) {
      _glowController.reverse();
    }
  }

  double _stateGlow() => switch (widget.visualState) {
        ClubBadgeVisualState.selected => ClubBadgeTokens.selectedGlowBoost,
        ClubBadgeVisualState.solved => ClubBadgeTokens.solvedGlowBoost,
        ClubBadgeVisualState.highlighted => ClubBadgeTokens.selectedGlowBoost * 0.75,
        ClubBadgeVisualState.normal => 0,
      };

  double _stateScale() => switch (widget.visualState) {
        ClubBadgeVisualState.selected => ClubBadgeTokens.scaleSelected,
        ClubBadgeVisualState.solved => ClubBadgeTokens.scaleSolved,
        _ => 1.0,
      };

  @override
  Widget build(BuildContext context) {
    final identity = ClubIdentityRegistry.resolve(widget.club);
    final primary = parseClubColor(identity.primaryColor, Colors.grey);
    final secondary = parseClubColor(identity.secondaryColor, Colors.grey.shade700);
    final accent = parseClubColor(identity.accentColor, Colors.amber);
    final shieldH = widget.size * ClubBadgeTokens.shapeAspectRatio;
    final glowMult = ClubBadgeTokens.glowMultiplier(context);

    final badge = AnimatedBuilder(
      animation: _glowAnim,
      builder: (context, _) {
        final glow = (_glowAnim.value + (_pressed ? 0.35 : 0.0) + _stateGlow()) *
            glowMult.clamp(0.0, 1.0);
        return Transform.scale(
          scale: _stateScale(),
          child: SizedBox(
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
                      accent: ClubBadgeTokens.rimColor(context, accent),
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
          ),
        );
      },
    );

    final labelSize = (widget.size * 0.22)
        .clamp(ClubBadgeTokens.labelMinFontSize, ClubBadgeTokens.labelMaxFontSize);

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
            width: widget.size * ClubBadgeTokens.labelMaxWidthFactor,
            child: Text(
              widget.club.shortLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: ClubBadgeTokens.labelLetterSpacing,
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

    return Semantics(
      label: widget.club.fullDisplayName,
      child: content,
    );
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
