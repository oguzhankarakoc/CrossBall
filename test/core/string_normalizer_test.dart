import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/string_normalizer.dart';

void main() {
  group('StringNormalizer', () {
    test('normalize removes accents', () {
      expect(StringNormalizer.normalize('Mesut Özil'), 'mesut ozil');
      expect(StringNormalizer.normalize('Cesc Fàbregas'), 'cesc fabregas');
    });

    test('normalize is case insensitive', () {
      expect(StringNormalizer.normalize('PEDRO'), 'pedro');
    });

    test('fuzzyMatch handles typos', () {
      expect(StringNormalizer.fuzzyMatch('ozil', 'Mesut Özil'), isTrue);
      expect(StringNormalizer.fuzzyMatch('pedro', 'Pedro'), isTrue);
      expect(StringNormalizer.fuzzyMatch('xyz', 'Pedro'), isFalse);
    });

    test('empty query matches all', () {
      expect(StringNormalizer.fuzzyMatch('', 'Anyone'), isTrue);
    });
  });
}
