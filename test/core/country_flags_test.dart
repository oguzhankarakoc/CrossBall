import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/country_flags.dart';

void main() {
  group('CountryFlags', () {
    test('emoji for ISO alpha-2 codes', () {
      expect(CountryFlags.emoji('DE'), '🇩🇪');
      expect(CountryFlags.emoji('tr'), '🇹🇷');
      expect(CountryFlags.emoji('PT'), '🇵🇹');
    });

    test('emoji for football federation codes', () {
      expect(CountryFlags.emoji('ENG'), '🇬🇧');
      expect(CountryFlags.emoji('SCO'), '🇬🇧');
      expect(CountryFlags.emoji('WAL'), '🇬🇧');
    });

    test('displayName resolves codes and federation aliases', () {
      expect(CountryFlags.displayName('DE'), 'Germany');
      expect(CountryFlags.displayName('ENG'), 'England');
      expect(CountryFlags.displayName('SCO'), 'Scotland');
      expect(CountryFlags.displayName('TR'), 'Turkey');
    });

    test('normalizeCode handles country names', () {
      expect(CountryFlags.normalizeCode('Germany'), 'DE');
      expect(CountryFlags.normalizeCode('Turkey'), 'TR');
    });

    test('unknown values return empty emoji', () {
      expect(CountryFlags.emoji(null), '');
      expect(CountryFlags.emoji(''), '');
      expect(CountryFlags.emoji('Unknown'), '');
    });

    test('hasKnownNationality', () {
      expect(CountryFlags.hasKnownNationality('DE'), isTrue);
      expect(CountryFlags.hasKnownNationality('ENG'), isTrue);
      expect(CountryFlags.hasKnownNationality('XX'), isFalse);
      expect(CountryFlags.hasKnownNationality(null), isFalse);
    });
  });
}
