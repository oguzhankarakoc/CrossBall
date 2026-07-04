import 'dart:async';

import 'package:flutter/foundation.dart';

import '../analytics/analytics_service.dart';

/// Lightweight crash/error reporting — forwards to analytics; swap for Crashlytics/Sentry later.
abstract interface class CrashReportingService {
  Future<void> recordFlutterError(FlutterErrorDetails details);
  Future<void> recordError(Object error, StackTrace stack, {String? reason});
}

class AnalyticsCrashReportingService implements CrashReportingService {
  AnalyticsCrashReportingService(this._analytics);

  final AnalyticsService _analytics;

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      reason: details.context?.toDescription(),
    );
  }

  @override
  Future<void> recordError(Object error, StackTrace stack, {String? reason}) async {
    if (kDebugMode) {
      debugPrint('CrashReporting: $error\n$stack');
    }
    unawaited(
      _analytics.track(
        'app_error',
        properties: {
          'message': error.toString(),
          if (reason != null) 'reason': reason,
          'stack': stack.toString().split('\n').take(8).join('\n'),
          'platform': defaultTargetPlatform.name,
        },
      ),
    );
  }
}

CrashReportingService createCrashReportingService(AnalyticsService analytics) {
  return AnalyticsCrashReportingService(analytics);
}

void installCrashHandlers(CrashReportingService crashReporting) {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(crashReporting.recordFlutterError(details));
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(crashReporting.recordError(error, stack, reason: 'platform'));
    return true;
  };
}
