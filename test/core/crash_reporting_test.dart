import 'package:crossball/core/analytics/analytics_service.dart';
import 'package:crossball/core/crash/crash_reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingAnalytics implements AnalyticsService {
  final events = <String>[];

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {}

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    events.add(event);
  }
}

void main() {
  test('records platform errors to analytics', () async {
    final analytics = _RecordingAnalytics();
    final crash = AnalyticsCrashReportingService(analytics);

    await crash.recordError(Exception('test failure'), StackTrace.current);

    expect(analytics.events, contains('app_error'));
  });
}
