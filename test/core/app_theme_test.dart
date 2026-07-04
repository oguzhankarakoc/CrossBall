import 'package:crossball/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('dark theme headlineSmall uses light text for contrast', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkStadium(),
        home: Builder(
          builder: (context) {
            final color = Theme.of(context).textTheme.headlineSmall!.color!;
            expect(color.computeLuminance(), greaterThan(0.5));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('light theme headlineSmall uses dark text for contrast', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightPitch(),
        home: Builder(
          builder: (context) {
            final color = Theme.of(context).textTheme.headlineSmall!.color!;
            expect(color.computeLuminance(), lessThan(0.35));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
