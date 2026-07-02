import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crossball/app.dart';

void main() {
  testWidgets('CrossBall app smoke test', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: CrossBallApp()),
    );
    expect(find.byType(CrossBallApp), findsOneWidget);
  });
}
