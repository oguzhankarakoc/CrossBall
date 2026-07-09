import '../../features/puzzle/domain/puzzle.dart';
import '../../l10n/app_localizations.dart';
import 'country_flags.dart';
import 'position_labels.dart';

/// Formats server hint payloads for compact, localized UI chips.
abstract final class HintDisplayFormatter {
  static const _unknownTokens = {
    'unknown',
    'unknown club',
    'unknown league',
  };

  static const int firstLetterMinSlots = 3;
  static const int firstLetterMaxSlots = 8;

  static bool isUnknown(String value) {
    final lower = value.trim().toLowerCase();
    return lower.isEmpty || _unknownTokens.contains(lower);
  }

  /// Caps underscore slots so long player names do not blow up chip width.
  static String formatFirstLetter(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '—';

    final match = RegExp(r'^(\S+)\s+(.*)$').firstMatch(trimmed);
    if (match == null) {
      return trimmed.length > 14 ? '${trimmed.substring(0, 14)}…' : trimmed;
    }

    final letter = match.group(1)!;
    final rest = match.group(2)!;
    final slotCount = '_'.allMatches(rest).length;
    final capped = slotCount.clamp(firstLetterMinSlots, firstLetterMaxSlots);
    return '$letter ${List.filled(capped, '_').join(' ')}';
  }

  static String formatValue({
    required HintType type,
    required String raw,
    required AppLocalizations l10n,
  }) {
    if (isUnknown(raw)) return l10n.hintValueUnknown;

    switch (type) {
      case HintType.nationality:
        if (CountryFlags.hasKnownNationality(raw)) {
          return CountryFlags.displayName(raw);
        }
        return l10n.hintValueUnknown;
      case HintType.position:
        final abbr = PositionLabels.abbreviate(raw);
        return abbr == '—' ? l10n.hintValueUnknown : abbr;
      case HintType.firstLetter:
        return formatFirstLetter(raw);
      case HintType.retiredStatus:
        return switch (raw.trim().toLowerCase()) {
          'active' => l10n.hintStatusActive,
          'retired' => l10n.hintStatusRetired,
          _ => raw,
        };
      case HintType.careerLeague:
      case HintType.careerClub:
        return raw;
    }
  }
}
