/// Legally safe abstract symbol — never official crests or logos.
enum ClubSymbolType {
  abstractStripes,
  abstractCrown,
  abstractLion,
  abstractOrb,
  abstractChevron,
  abstractDiamond,
  abstractStar,
  abstractWaves,
  abstractCross,
  abstractFlame,
  abstractShield,
}

enum ClubBadgeStyle {
  vertical,
  horizontal,
  radial,
  metallic,
}

/// Visual identity metadata for a club badge (no trademarked assets).
class ClubIdentity {
  const ClubIdentity({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.symbolType,
    required this.shortCode,
    required this.badgeStyle,
  });

  final String primaryColor;
  final String secondaryColor;
  final String accentColor;
  final ClubSymbolType symbolType;
  final String shortCode;
  final ClubBadgeStyle badgeStyle;

  static ClubSymbolType parseSymbolType(String? raw) {
    if (raw == null || raw.isEmpty) return ClubSymbolType.abstractShield;
    final key = raw.toLowerCase().replaceAll('-', '_');
    return switch (key) {
      'abstract_stripes' || 'stripes' => ClubSymbolType.abstractStripes,
      'abstract_crown' || 'crown' => ClubSymbolType.abstractCrown,
      'abstract_lion' || 'lion' || 'lion_inspired' => ClubSymbolType.abstractLion,
      'abstract_orb' || 'orb' || 'circle' => ClubSymbolType.abstractOrb,
      'abstract_chevron' || 'chevron' => ClubSymbolType.abstractChevron,
      'abstract_diamond' || 'diamond' => ClubSymbolType.abstractDiamond,
      'abstract_star' || 'star' => ClubSymbolType.abstractStar,
      'abstract_waves' || 'waves' => ClubSymbolType.abstractWaves,
      'abstract_cross' || 'cross' => ClubSymbolType.abstractCross,
      'abstract_flame' || 'flame' => ClubSymbolType.abstractFlame,
      _ => ClubSymbolType.abstractShield,
    };
  }

  static ClubBadgeStyle parseBadgeStyle(String? raw) {
    if (raw == null || raw.isEmpty) return ClubBadgeStyle.vertical;
    return switch (raw.toLowerCase()) {
      'horizontal' => ClubBadgeStyle.horizontal,
      'radial' => ClubBadgeStyle.radial,
      'metallic' => ClubBadgeStyle.metallic,
      _ => ClubBadgeStyle.vertical,
    };
  }

  static String symbolTypeToStorage(ClubSymbolType type) => switch (type) {
        ClubSymbolType.abstractStripes => 'abstract_stripes',
        ClubSymbolType.abstractCrown => 'abstract_crown',
        ClubSymbolType.abstractLion => 'abstract_lion',
        ClubSymbolType.abstractOrb => 'abstract_orb',
        ClubSymbolType.abstractChevron => 'abstract_chevron',
        ClubSymbolType.abstractDiamond => 'abstract_diamond',
        ClubSymbolType.abstractStar => 'abstract_star',
        ClubSymbolType.abstractWaves => 'abstract_waves',
        ClubSymbolType.abstractCross => 'abstract_cross',
        ClubSymbolType.abstractFlame => 'abstract_flame',
        ClubSymbolType.abstractShield => 'abstract_shield',
      };
}
