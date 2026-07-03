import 'package:flutter/material.dart';

import '../../core/club_identity/club_display_resolver.dart';
import '../../core/club_identity/club_identity_registry.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../features/puzzle/domain/puzzle.dart';
import 'club_badge.dart';

/// Puzzle header cell: premium badge + human-readable short label.
class ClubHeaderCell extends StatelessWidget {
  const ClubHeaderCell({
    super.key,
    required this.club,
    required this.badgeSize,
    required this.maxLabelWidth,
    this.axis = Axis.vertical,
  });

  final Club club;
  final double badgeSize;
  final double maxLabelWidth;
  final Axis axis;

  void _showClubDetail(BuildContext context) {
    final info = ClubDisplayResolver.resolve(club);
    final country = ClubDisplayResolver.countryName(club);
    final code = ClubIdentityRegistry.resolve(club).shortCode;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.cb;
        return Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: colors.accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClubBadge(club: club, size: 48, showLabel: false, interactive: false),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.displayName,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          code,
                          style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (country.isNotEmpty)
                _DetailRow(icon: Icons.public, label: country),
              if (info.leagueName != null && info.leagueName!.isNotEmpty)
                _DetailRow(icon: Icons.emoji_events_outlined, label: info.leagueName!),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = ClubDisplayResolver.resolve(club);
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: badgeSize < 46 ? 9 : 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          height: 1.0,
        );

    final label = SizedBox(
      width: maxLabelWidth,
      child: Text(
        info.shortLabel,
        style: labelStyle,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    final badge = ClubBadge(
      club: club,
      size: badgeSize,
      showLabel: false,
      interactive: false,
    );

    final content = axis == Axis.vertical
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              SizedBox(height: AppSpacing.xs),
              label,
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              const SizedBox(width: AppSpacing.xs),
              Flexible(child: label),
            ],
          );

    return GestureDetector(
      onTap: () => _showClubDetail(context),
      onLongPress: () => _showClubDetail(context),
      child: content,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
