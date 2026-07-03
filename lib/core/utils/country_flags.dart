/// ISO 3166-1 alpha-2 country flags and display names for player search.
abstract final class CountryFlags {
  static const _names = {
    'AR': 'Argentina',
    'AT': 'Austria',
    'BE': 'Belgium',
    'BR': 'Brazil',
    'CM': 'Cameroon',
    'CH': 'Switzerland',
    'CI': 'Ivory Coast',
    'CO': 'Colombia',
    'CZ': 'Czechia',
    'DE': 'Germany',
    'DK': 'Denmark',
    'EG': 'Egypt',
    'ES': 'Spain',
    'FI': 'Finland',
    'FR': 'France',
    'GB': 'England',
    'GH': 'Ghana',
    'GR': 'Greece',
    'HR': 'Croatia',
    'IE': 'Ireland',
    'IT': 'Italy',
    'JP': 'Japan',
    'KR': 'South Korea',
    'MA': 'Morocco',
    'MX': 'Mexico',
    'NG': 'Nigeria',
    'NL': 'Netherlands',
    'NO': 'Norway',
    'PL': 'Poland',
    'PT': 'Portugal',
    'RO': 'Romania',
    'RS': 'Serbia',
    'RU': 'Russia',
    'SA': 'Saudi Arabia',
    'SE': 'Sweden',
    'SN': 'Senegal',
    'TR': 'Turkey',
    'UA': 'Ukraine',
    'US': 'United States',
    'UY': 'Uruguay',
    'WAL': 'Wales',
    'ENG': 'England',
    'SCO': 'Scotland',
  };

  static String emoji(String? code) {
    if (code == null || code.length != 2) return '🏳️';
    final upper = code.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([first, second]);
  }

  static String name(String? code) {
    if (code == null || code.isEmpty) return 'Unknown';
    return _names[code.toUpperCase()] ?? code.toUpperCase();
  }
}
