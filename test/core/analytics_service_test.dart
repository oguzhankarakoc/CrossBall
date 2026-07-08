import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:crossball/core/analytics/analytics_service.dart';
import 'package:crossball/core/config/app_config.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '''
POSTHOG_API_KEY=phc_test_key
POSTHOG_HOST=https://eu.i.posthog.com
ANALYTICS_ENABLED=true
''');
  });

  test('PostHog track sends capture payload when active', () async {
    http.Request? captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response('{}', 200);
    });

    final service = PostHogAnalyticsService(httpClient: client);
    await service.identify('user-123', traits: {'is_premium': false});
    await service.track('puzzle_started', properties: {'mode': 'daily'});

    expect(captured, isNotNull);
    expect(captured!.url.toString(), 'https://eu.i.posthog.com/capture/');

    final body = jsonDecode(captured!.body) as Map<String, dynamic>;
    expect(body['api_key'], 'phc_test_key');
    expect(body['event'], 'puzzle_started');
    expect(body['distinct_id'], 'user-123');
    expect(body['properties'], containsPair('mode', 'daily'));
  });

  test('PostHog track is skipped when analytics disabled', () async {
    dotenv.testLoad(fileInput: '''
POSTHOG_API_KEY=phc_test_key
POSTHOG_HOST=https://eu.i.posthog.com
ANALYTICS_ENABLED=false
''');

    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('{}', 200);
    });

    final service = PostHogAnalyticsService(httpClient: client);
    await service.track('app_opened');

    expect(called, isFalse);
    expect(AppConfig.isPostHogActive, isFalse);
  });

  test('createAnalyticsService includes PostHog when active', () {
    final service = createAnalyticsService();
    expect(service, isA<CompositeAnalyticsService>());
  });
}
