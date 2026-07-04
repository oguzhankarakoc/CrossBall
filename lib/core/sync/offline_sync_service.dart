import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../cache/offline_cache.dart';
import '../config/app_config.dart';

/// Flushes offline queues when connectivity returns.
class OfflineSyncService {
  OfflineSyncService({
    required OfflineCache cache,
    Connectivity? connectivity,
    http.Client? httpClient,
  })  : _cache = cache,
        _connectivity = connectivity ?? Connectivity(),
        _http = httpClient ?? http.Client();

  final OfflineCache _cache;
  final Connectivity _connectivity;
  final http.Client _http;

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
    if (!AppConfig.isSupabaseConfigured) return;

    final pending = await _cache.flushPendingAnswers();
    if (pending.isEmpty) return;

    for (final session in pending) {
      try {
        final response = await _http.post(
          Uri.parse('${AppConfig.supabaseUrl}/functions/v1/complete-session'),
          headers: {
            'apikey': AppConfig.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode(session),
        );
        if (response.statusCode == 200) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final economy = body['economy'] as Map<String, dynamic>?;
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
