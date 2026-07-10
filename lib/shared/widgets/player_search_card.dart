import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/country_flags.dart';
import '../../core/utils/position_labels.dart';
import '../../features/search/domain/search.dart';
import 'club_chip.dart';
import 'country_flag_badge.dart';
import 'player_avatar.dart';

/// Premium scouting-style player result card for search modal.
class PlayerSearchCard extends StatefulWidget {
  const PlayerSearchCard({
    super.key,
    required this.player,
    required this.onTap,
    this.highlightClubs = const {},
    this.showRelevanceBadge = false,
    this.animationDelay = 0,
  });

  final Player player;
  final VoidCallback onTap;
  final Set<String> highlightClubs;
  final bool showRelevanceBadge;
  final int animationDelay;

  @override
  State<PlayerSearchCard> createState() => _PlayerSearchCardState();
}

class _PlayerSearchCardState extends State<PlayerSearchCard> {
  bool _pressed = false;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final player = widget.player;
    final position = PositionLabels.abbreviate(player.primaryPosition);
    final hasNationality = CountryFlags.hasKnownNationality(player.nationalityCode);
    final hasPosition =
        player.primaryPosition != null && player.primaryPosition!.trim().isNotEmpty;
    final orderedClubs = prioritizeClubsForCell(
      player.clubsPreview,
      widget.highlightClubs,
    );
    final careerPreview = orderedClubs.take(4).join(', ');

    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: AppDuration.medium,
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.04),
        duration: AppDuration.medium,
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: AppDuration.fast,
            curve: Curves.easeOutCubic,
            child: Material(
              color: colors.surfaceElevated.withValues(alpha: 0.85),
              elevation: _pressed ? AppElevation.level0 : AppElevation.level1,
              shadowColor: colors.lime.withValues(alpha: 0.1),
              borderRadius: AppRadius.xlBorder,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                borderRadius: AppRadius.xlBorder,
                splashColor: colors.lime.withValues(alpha: 0.12),
                highlightColor: colors.primary.withValues(alpha: 0.08),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.xlBorder,
                    border: Border.all(
                      color: widget.showRelevanceBadge
                          ? colors.lime.withValues(alpha: 0.45)
                          : colors.glassBorder,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PlayerAvatar(
                          seed: player.id,
                          size: 64,
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
                                        color: colors.lime.withValues(alpha: 0.18),
                                        borderRadius: AppRadius.smBorder,
                                      ),
                                      child: Icon(Icons.bolt_rounded, size: 14, color: colors.lime),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (hasNationality || hasPosition)
                                NationalityLabel(
                                  nationalityCode: player.nationalityCode,
                                  position: hasPosition ? position : null,
                                ),
                              if (careerPreview.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  careerPreview,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colors.textSecondary.withValues(alpha: 0.85),
                                        fontSize: 12,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (orderedClubs.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: orderedClubs.take(4).map((club) {
                                      final highlight = _clubMatchesCell(
                                        club,
                                        widget.highlightClubs,
                                      );
                                      return ClubChip(label: club, highlighted: highlight);
                                    }).toList(),
                                  ),
                                ],
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, size: 20, color: colors.lime),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _clubMatchesCell(String club, Set<String> highlightClubs) {
  final normalized = _normalizeClubToken(club);
  if (normalized.isEmpty || highlightClubs.isEmpty) return false;
  for (final raw in highlightClubs) {
    final target = _normalizeClubToken(raw);
    if (target.isEmpty) continue;
    if (normalized == target) return true;
    if (normalized.contains(target) || target.contains(normalized)) return true;
    // Short codes like ARS / SCP vs full names.
    if (target.length <= 4 &&
        normalized.split(RegExp(r'[^a-z0-9]+')).any((p) => p.startsWith(target))) {
      return true;
    }
  }
  return false;
}

/// Puzzle axis clubs first, then the rest of the career preview.
List<String> prioritizeClubsForCell(List<String> clubs, Set<String> highlightClubs) {
  if (clubs.isEmpty || highlightClubs.isEmpty) return clubs;
  final matched = <String>[];
  final used = <String>{};
  for (final preferred in highlightClubs) {
    for (final club in clubs) {
      if (used.contains(club)) continue;
      if (_clubMatchesCell(club, {preferred})) {
        matched.add(club);
        used.add(club);
        break;
      }
    }
  }
  final rest = clubs.where((club) => !used.contains(club));
  return [...matched, ...rest];
}

String _normalizeClubToken(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
