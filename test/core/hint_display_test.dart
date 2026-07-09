import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/hint_display.dart';
import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:crossball/l10n/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('HintDisplayFormatter', () {
    test('caps first-letter underscore slots', () {
      final raw = 'C _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _';
      expect(
        HintDisplayFormatter.formatFirstLetter(raw),
        'C _ _ _ _ _ _ _ _',
      );
    });

    test('localizes unknown nationality and position', () {
      expect(
        HintDisplayFormatter.formatValue(
          type: HintType.nationality,
          raw: 'Unknown',
          l10n: l10n,
        ),
        'Unknown',
      );
      expect(
        HintDisplayFormatter.formatValue(
          type: HintType.position,
          raw: 'Unknown',
          l10n: l10n,
        ),
        'Unknown',
      );
    });

    test('localizes retired status', () {
      expect(
        HintDisplayFormatter.formatValue(
          type: HintType.retiredStatus,
          raw: 'Active',
          l10n: l10n,
        ),
        'Active',
      );
      expect(
        HintDisplayFormatter.formatValue(
          type: HintType.retiredStatus,
          raw: 'Retired',
          l10n: l10n,
        ),
        'Retired',
      );
    });

    test('abbreviates known position', () {
      expect(
        HintDisplayFormatter.formatValue(
          type: HintType.position,
          raw: 'Goalkeeper',
          l10n: l10n,
        ),
        'GK',
      );
    });
  });
}
