import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// Debug-only tagged logs. Filter Xcode / Flutter console by tag, e.g. `[Daily]`.
///
/// Removal checklist: [docs/DEBUG_LOGS.md]
void cbDebug(String tag, String message, [Object? detail]) {
  if (!kDebugMode) return;
  final suffix = detail == null ? '' : ' | $detail';
  debugPrint('[$tag] $message$suffix');
}

void cbDebugError(
  String tag,
  String message,
  Object error, [
  StackTrace? stackTrace,
]) {
  if (!kDebugMode) return;
  debugPrint('[$tag] ERROR $message | $error');
  if (stackTrace != null) {
    debugPrint('[$tag] $stackTrace');
  }
}

/// One-line startup snapshot — helps diagnose missing `.env` on device builds.
void cbDebugConfigSnapshot() {
  if (!kDebugMode) return;
  final supabaseHost = _redactUrlHost(AppConfig.supabaseUrl);
  cbDebug('Config', 'startup snapshot', {
    'supabaseConfigured': AppConfig.isSupabaseConfigured,
    'supabaseHost': supabaseHost,
    'anonKeyPresent': AppConfig.supabaseAnonKey.isNotEmpty,
    'iapEnabled': AppConfig.isIapEnabled,
    'forceFreeTier': AppConfig.forceFreeTier,
    'adMobEnabled': AppConfig.isAdMobEnabled,
    'useTestAds': AppConfig.useTestAds,
    'remotePushEnabled': AppConfig.isRemotePushEnabled,
    'firebaseConfigured': AppConfig.isFirebaseConfigured,
  });
}

String _redactUrlHost(String url) {
  if (url.isEmpty) return '(empty)';
  try {
    return Uri.parse(url).host;
  } catch (_) {
    return '(invalid-url)';
  }
}

String _bodyPreview(String body, {int maxLen = 400}) {
  if (body.length <= maxLen) return body;
  return '${body.substring(0, maxLen)}…';
}

/// Shared HTTP response logging for edge-function calls.
void cbDebugHttpResponse(
  String tag,
  String label, {
  required int statusCode,
  required int elapsedMs,
  required String body,
  String? uri,
}) {
  cbDebug(tag, label, {
    'uri': ?uri,
    'status': statusCode,
    'elapsedMs': elapsedMs,
    'bodyPreview': _bodyPreview(body),
  });
}
