import 'package:crossball/core/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators.nickname', () {
    const error = 'invalid';

    test('accepts valid nickname', () {
      expect(AppValidators.nickname('MessiFan42', emptyError: error), isNull);
    });

    test('rejects too short', () {
      expect(AppValidators.nickname('ab', emptyError: error), error);
    });

    test('allows empty to clear nickname', () {
      expect(AppValidators.nickname('', emptyError: error), isNull);
      expect(AppValidators.nickname('   ', emptyError: error), isNull);
    });
  });
}
