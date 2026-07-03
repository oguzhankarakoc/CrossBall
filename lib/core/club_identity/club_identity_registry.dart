import '../../features/puzzle/domain/puzzle.dart';
import 'club_identity.dart';
import 'club_identity_data.dart';

/// Resolves [ClubIdentity] from registry + API overrides + deterministic fallback.
abstract final class ClubIdentityRegistry {
  static ClubIdentity resolve(Club club) {
    final slugKey = club.slug.toLowerCase();
    final base = ClubIdentityData.bySlug[slugKey] ?? _generatedFallback(club);

    return ClubIdentity(
      primaryColor: _or(club.badgePrimaryColor, base.primaryColor),
      secondaryColor: _or(club.badgeSecondaryColor, base.secondaryColor),
      accentColor: _or(club.badgeAccentColor, base.accentColor),
      symbolType: _hasCustomSymbol(club.badgeIconType)
          ? ClubIdentity.parseSymbolType(club.badgeIconType)
          : base.symbolType,
      shortCode: _or(club.shortCode ?? club.badgeInitials, base.shortCode),
      badgeStyle: club.badgeGradientStyle != null && club.badgeGradientStyle!.isNotEmpty
          ? ClubIdentity.parseBadgeStyle(club.badgeGradientStyle)
          : base.badgeStyle,
    );
  }

  static String _or(String? value, String fallback) =>
      value != null && value.isNotEmpty ? value : fallback;

  static bool _hasCustomSymbol(String? raw) {
    if (raw == null || raw.isEmpty) return false;
    return raw != 'shield' && raw != 'abstract_shield';
  }

  static ClubIdentity _generatedFallback(Club club) {
    final hash = club.slug.hashCode.abs();
    const symbols = ClubSymbolType.values;
    const styles = ClubBadgeStyle.values;
    final hue = hash % 360;

    return ClubIdentity(
      primaryColor: '#${((hue * 7) % 180 + 50).toRadixString(16).padLeft(2, '0')}'
          '${((hue * 3) % 140 + 60).toRadixString(16).padLeft(2, '0')}AA',
      secondaryColor: '#${((hue + 120) % 180 + 40).toRadixString(16).padLeft(2, '0')}'
          '${((hue + 60) % 140 + 50).toRadixString(16).padLeft(2, '0')}77',
      accentColor: '#FFD700',
      symbolType: symbols[hash % symbols.length],
      shortCode: _shortCodeFromName(club.name),
      badgeStyle: styles[hash % styles.length],
    );
  }

  static String _shortCodeFromName(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '???';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length.clamp(0, 3)).toUpperCase();
    }
    return (parts.first[0] + parts[1][0] + (parts.length > 2 ? parts[2][0] : parts[1][1]))
        .toUpperCase();
  }
}
