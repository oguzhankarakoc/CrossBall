import 'package:crossball/core/responsive/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoint', () {
    test('compact below 600', () {
      expect(AppBreakpoint.fromWidth(390), AppBreakpoint.compact);
    });

    test('medium at 600', () {
      expect(AppBreakpoint.fromWidth(600), AppBreakpoint.medium);
    });

    test('expanded at 840', () {
      expect(AppBreakpoint.fromWidth(900), AppBreakpoint.expanded);
    });
  });

  group('ResponsiveData', () {
    test('scales spacing on tablet', () {
      final phone = ResponsiveData(390);
      final tablet = ResponsiveData(800);
      expect(tablet.spacingScale, greaterThan(phone.spacingScale));
      expect(tablet.maxContentWidth, greaterThan(phone.maxContentWidth));
    });
  });
}
