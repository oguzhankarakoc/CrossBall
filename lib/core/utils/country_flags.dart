/// ISO 3166-1 alpha-2 country flags and display names for player search.
///
/// Uses Unicode regional indicator symbols (emoji flags) — no image assets,
/// no third-party flag packs, no copyright concerns for country flags in UI.
abstract final class CountryFlags {
  static const _names = {
    'AR': 'Argentina',
    'AT': 'Austria',
    'AU': 'Australia',
    'BE': 'Belgium',
    'BG': 'Bulgaria',
    'BR': 'Brazil',
    'CA': 'Canada',
    'CH': 'Switzerland',
    'CI': 'Ivory Coast',
    'CL': 'Chile',
    'CM': 'Cameroon',
    'CO': 'Colombia',
    'CR': 'Costa Rica',
    'CZ': 'Czechia',
    'DE': 'Germany',
    'DK': 'Denmark',
    'DZ': 'Algeria',
    'EC': 'Ecuador',
    'EG': 'Egypt',
    'ENG': 'England',
    'ES': 'Spain',
    'FI': 'Finland',
    'FR': 'France',
    'GB': 'England',
    'GH': 'Ghana',
    'GR': 'Greece',
    'HR': 'Croatia',
    'HU': 'Hungary',
    'IE': 'Ireland',
    'IS': 'Iceland',
    'IT': 'Italy',
    'JP': 'Japan',
    'KR': 'South Korea',
    'MA': 'Morocco',
    'MX': 'Mexico',
    'NG': 'Nigeria',
    'NL': 'Netherlands',
    'NO': 'Norway',
    'PE': 'Peru',
    'PL': 'Poland',
    'PT': 'Portugal',
    'RO': 'Romania',
    'RS': 'Serbia',
    'RU': 'Russia',
    'SA': 'Saudi Arabia',
    'SCO': 'Scotland',
    'SE': 'Sweden',
    'SN': 'Senegal',
    'TR': 'Turkey',
    'UA': 'Ukraine',
    'US': 'United States',
    'UY': 'Uruguay',
    'WAL': 'Wales',
  };

  /// FIFA / football federation codes mapped to ISO alpha-2 for emoji flags.
  static const _emojiAliases = {
    'ENG': 'GB',
    'SCO': 'GB',
    'WAL': 'GB',
    'NIR': 'GB',
    'UK': 'GB',
  };

  /// Returns a normalized ISO alpha-2 code when possible.
  static String? normalizeCode(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') return null;

    final upper = trimmed.toUpperCase();
    if (_emojiAliases.containsKey(upper)) return _emojiAliases[upper];
    if (upper.length == 2 && _isAlphaPair(upper)) return upper;

    for (final entry in _names.entries) {
      if (entry.value.toLowerCase() == trimmed.toLowerCase()) {
        if (entry.key.length == 2) return entry.key;
        return _emojiAliases[entry.key];
      }
    }
    return null;
  }

  static bool hasKnownNationality(String? code) {
    if (code == null) return false;
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty || upper == 'UNKNOWN') return false;
    if (_names.containsKey(upper)) return true;
    final normalized = normalizeCode(code);
    return normalized != null && _names.containsKey(normalized);
  }

  /// Unicode flag emoji for ISO alpha-2 or football federation codes.
  static String emoji(String? code) {
    final normalized = normalizeCode(code);
    if (normalized == null || normalized.length != 2) return '';
    return _emojiFromAlpha2(normalized);
  }

  static String displayName(String? code) {
    if (code == null) return '';
    final trimmed = code.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown') return '';

    final upper = trimmed.toUpperCase();
    if (_names.containsKey(upper)) return _names[upper]!;

    for (final entry in _names.entries) {
      if (entry.value.toLowerCase() == trimmed.toLowerCase()) return entry.value;
    }

    final normalized = normalizeCode(code);
    if (normalized != null && _names.containsKey(normalized)) {
      return _names[normalized]!;
    }
    return upper;
  }

  @Deprecated('Use displayName instead')
  static String name(String? code) => displayName(code);

  static String _emojiFromAlpha2(String upper) {
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  static bool _isAlphaPair(String value) {
    final a = value.codeUnitAt(0);
    final b = value.codeUnitAt(1);
    return a >= 65 && a <= 90 && b >= 65 && b <= 90;
  }
}
