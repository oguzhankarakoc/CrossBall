import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/routing/deep_link_service.dart';

void main() {
  test('crossball://challenge/abc123 opens challenge puzzle', () {
    final route = DeepLinkService.routeFromUri(Uri.parse('crossball://challenge/abc123'));
    expect(route, '/puzzle?mode=challenge&id=abc123');
  });

  test('crossball://challenge?id=xyz789 opens challenge puzzle', () {
    final route = DeepLinkService.routeFromUri(Uri.parse('crossball://challenge?id=xyz789'));
    expect(route, '/puzzle?mode=challenge&id=xyz789');
  });

  test('unknown scheme returns null', () {
    expect(DeepLinkService.routeFromUri(Uri.parse('https://example.com')), isNull);
  });
}
