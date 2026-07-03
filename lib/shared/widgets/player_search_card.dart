import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/country_flags.dart';
import '../../core/utils/position_labels.dart';
import '../../features/search/domain/search.dart';
import 'club_chip.dart';
import 'player_avatar.dart';

/// Premium scouting-style player result card for search modal.
class PlayerSearchCard extends StatefulWidget {
  const PlayerSearchCard({
    super.key,
    required this.player,
    required this.onTap,
    this.highlightClubs = const {},
    this.showRelevanceBadge = false,
  });

  final Player player;
  final VoidCallback onTap;
  final Set<String> highlightClubs;
  final bool showRelevanceBadge;

  @override
  State<PlayerSearchCard> createState() => _PlayerSearchCardState();
}

class _PlayerSearchCardState extends State<PlayerSearchCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final player = widget.player;
    final flag = CountryFlags.emoji(player.nationalityCode);
    final country = CountryFlags.name(player.nationalityCode);
    final position = PositionLabels.abbreviate(player.primaryPosition);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: AppDuration.fast,
        curve: Curves.easeOutCubic,
        child: Material(
          color: colors.surfaceElevated,
          elevation: _pressed ? AppElevation.level0 : AppElevation.level1,
          shadowColor: colors.accent.withValues(alpha: 0.12),
          borderRadius: AppRadius.lgBorder,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: AppRadius.lgBorder,
            splashColor: colors.accent.withValues(alpha: 0.12),
            highlightColor: colors.primary.withValues(alpha: 0.08),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgBorder,
                border: Border.all(
                  color: widget.showRelevanceBadge
                      ? colors.accent.withValues(alpha: 0.45)
                      : colors.cardBorder,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PlayerAvatar(
                      seed: player.id,
                      size: 56,
                      nationalityCode: player.nationalityCode,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  player.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.showRelevanceBadge)
                                Container(
                                  margin: const EdgeInsets.only(left: AppSpacing.xs),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colors.accent.withValues(alpha: 0.18),
                                    borderRadius: AppRadius.smBorder,
                                  ),
                                  child: Icon(Icons.bolt, size: 14, color: colors.accent),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$flag $country • $position',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.2,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (player.clubsPreview.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: player.clubsPreview.map((club) {
                                final normalized = club.toLowerCase();
                                final highlight = widget.highlightClubs.any(
                                  (h) => normalized.contains(h.toLowerCase()) || h.toLowerCase().contains(normalized),
                                );
                                return ClubChip(label: club, highlighted: highlight);
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.chevron_right, size: 18, color: colors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
