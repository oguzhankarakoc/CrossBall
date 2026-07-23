import 'package:flutter/material.dart';

import '../../../core/club_identity/club_badge_tokens.dart';
import '../../../core/club_identity/club_display_resolver.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../features/puzzle/domain/puzzle.dart';
import '../club_badge.dart';
import '../club_header_cell.dart';

export '../club_badge.dart';
export '../club_header_cell.dart';

/// Compact horizontal club pill — search, lists, chips.
class ClubIdentityChip extends StatelessWidget {
  const ClubIdentityChip({
    super.key,
    required this.club,
    this.visualState = ClubBadgeVisualState.normal,
    this.showCountry = false,
  });

  final Club club;
  final ClubBadgeVisualState visualState;
  final bool showCountry;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final info = ClubDisplayResolver.resolve(club);
    final country = showCountry ? ClubDisplayResolver.countryName(club) : '';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ClubBadgeTokens.chipPaddingH,
        vertical: ClubBadgeTokens.chipPaddingV,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.85),
        borderRadius: ClubBadgeTokens.chipRadius,
        border: Border.all(
          color: visualState == ClubBadgeVisualState.selected
              ? colors.lime.withValues(alpha: 0.6)
              : colors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClubBadge(
            club: club,
            size: 28,
            compact: true,
            showLabel: false,
            interactive: false,
            visualState: visualState,
          ),
          const SizedBox(width: ClubBadgeTokens.chipGap),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  info.shortLabel,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (country.isNotEmpty)
                  Text(
                    country,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 10,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge + name row for cards, stats, profiles.
class ClubIdentityTile extends StatelessWidget {
  const ClubIdentityTile({
    super.key,
    required this.club,
    this.badgeSize = 40,
    this.subtitle,
    this.visualState = ClubBadgeVisualState.normal,
    this.onTap,
  });

  final Club club;
  final double badgeSize;
  final String? subtitle;
  final ClubBadgeVisualState visualState;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final info = ClubDisplayResolver.resolve(club);
    final colors = context.cb;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: ClubBadgeTokens.tileRadius,
        child: Padding(
          padding: const EdgeInsets.all(ClubBadgeTokens.tilePadding),
          child: Row(
            children: [
              ClubBadge(
                club: club,
                size: badgeSize,
                showLabel: false,
                interactive: false,
                visualState: visualState,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      )
                    else if (info.leagueName != null)
                      Text(
                        info.leagueName!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.textSecondary,
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Puzzle board header tile — always shows badge + club name.
class PuzzleClubTile extends StatelessWidget {
  const PuzzleClubTile({
    super.key,
    required this.club,
    required this.badgeSize,
    required this.maxLabelWidth,
    this.axis = Axis.vertical,
    this.labelAbove = false,
    this.visualState = ClubBadgeVisualState.normal,
  });

  final Club club;
  final double badgeSize;
  final double maxLabelWidth;
  final Axis axis;
  final bool labelAbove;
  final ClubBadgeVisualState visualState;

  @override
  Widget build(BuildContext context) {
    return ClubHeaderCell(
      club: club,
      badgeSize: badgeSize,
      maxLabelWidth: maxLabelWidth,
      axis: axis,
      labelAbove: labelAbove,
      visualState: visualState,
    );
  }
}

/// Small badge for search result rows.
typedef SearchClubIcon = ClubBadge;

/// Leaderboard / profile badge at standard size.
class LeaderboardClubIcon extends StatelessWidget {
  const LeaderboardClubIcon({super.key, required this.club, this.size = 36});

  final Club club;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClubBadge(
      club: club,
      size: size,
      showLabel: false,
      interactive: false,
    );
  }
}

typedef ProfileClubBadge = ClubIdentityTile;
