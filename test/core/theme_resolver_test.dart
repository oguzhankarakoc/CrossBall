import 'package:crossball/shared/providers/theme_mode_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('premium theme modes are flagged', () {
    expect(AppThemeMode.darkGold.isPremiumOnly, isTrue);
    expect(AppThemeMode.lightClassic.isPremiumOnly, isTrue);
    expect(AppThemeMode.dark.isPremiumOnly, isFalse);
  });
}
