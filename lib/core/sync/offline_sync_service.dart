import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../cache/offline_cache.dart';
import '../network/api_config.dart';
import '../network/api_http_client.dart';

/// Flushes offline queues when connectivity returns.
class OfflineSyncService {
  OfflineSyncService({
    required OfflineCache cache,
    Connectivity? connectivity,
    ApiHttpClient? httpClient,
  })  : _cache = cache,
        _connectivity = connectivity ?? Connectivity(),
        _http = httpClient ?? ApiHttpClient();

  final OfflineCache _cache;
  final Connectivity _connectivity;
  final ApiHttpClient _http;

  void startListening() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        flushPendingSessions();
      }
    });
    flushPendingSessions();
  }

  Future<void> flushPendingSessions() async {
    if (!ApiConfig.isConfigured) return;

    final pending = await _cache.flushPendingAnswers();
    if (pending.isEmpty) return;

    for (final session in pending) {
      try {
        final userUuid = session['user_uuid'] as String?;
        final json = await _http.postJson(
          'complete-session',
          body: Map<String, dynamic>.from(session),
          headers: userUuid != null ? ApiConfig.userHeaders(userUuid) : null,
          throwOnError: false,
        );
        if (json.isNotEmpty) {
          final economy = json['economy'] as Map<String, dynamic>?;
          final progression = economy?['progression'] as Map<String, dynamic>?;
          if (progression != null) {
            await _cache.cacheProgression(progression);
          }
        } else {
          await _cache.queuePendingAnswer(session);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('OfflineSync flush failed: $e');
        await _cache.queuePendingAnswer(session);
      }
    }
  }
}
