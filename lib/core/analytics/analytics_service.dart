import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Analytics abstraction — swap PostHog / Firebase without changing call sites.
abstract interface class AnalyticsService {
  Future<void> track(String event, {Map<String, dynamic>? properties});
  Future<void> identify(String userId, {Map<String, dynamic>? traits});
}

class ConsoleAnalyticsService implements AnalyticsService {
  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Analytics] $event ${properties ?? {}}');
    }
  }

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Analytics] identify $userId ${traits ?? {}}');
    }
  }
}

/// PostHog via HTTP capture API (no extra SDK dependency).
class PostHogAnalyticsService implements AnalyticsService {
  PostHogAnalyticsService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String? _distinctId;

  Uri get _captureUri => Uri.parse('${AppConfig.postHogHost}/capture/');

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    _distinctId = userId;
    if (!AppConfig.isPostHogConfigured) return;

    try {
      await _http.post(
        _captureUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': AppConfig.postHogApiKey,
          'event': '\$identify',
          'distinct_id': userId,
          'properties': {
            '\$set': traits ?? {},
          },
        }),
      );
    } catch (_) {}
  }

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    if (!AppConfig.isPostHogConfigured) return;

    try {
      await _http.post(
        _captureUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'api_key': AppConfig.postHogApiKey,
          'event': event,
          'distinct_id': _distinctId ?? 'anonymous',
          'properties': {
            ...?properties,
            'platform': defaultTargetPlatform.name,
          },
        }),
      );
    } catch (_) {}
  }
}

class CompositeAnalyticsService implements AnalyticsService {
  CompositeAnalyticsService(this._services);

  final List<AnalyticsService> _services;

  @override
  Future<void> track(String event, {Map<String, dynamic>? properties}) async {
    for (final service in _services) {
      await service.track(event, properties: properties);
    }
  }

  @override
  Future<void> identify(String userId, {Map<String, dynamic>? traits}) async {
    for (final service in _services) {
      await service.identify(userId, traits: traits);
    }
  }
}

AnalyticsService createAnalyticsService() {
  final services = <AnalyticsService>[ConsoleAnalyticsService()];
  if (AppConfig.isPostHogConfigured) {
    services.add(PostHogAnalyticsService());
  }
  return CompositeAnalyticsService(services);
}
