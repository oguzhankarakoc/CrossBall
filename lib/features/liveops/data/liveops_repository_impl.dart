import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/cache/offline_cache.dart';
import '../../../core/config/app_config.dart';
import '../domain/liveops_snapshot.dart';

class LiveOpsRepositoryImpl implements LiveOpsRepository {
  LiveOpsRepositoryImpl({
    required OfflineCache cache,
    http.Client? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? http.Client();

  final OfflineCache _cache;
  final http.Client _http;

  @override
  Future<LiveOpsSnapshot> getSnapshot({
    required String userUuid,
    required String locale,
    required String platform,
    String country = '',
    String appVersion = '1.0.0',
  }) async {
    if (AppConfig.isSupabaseConfigured) {
      try {
        final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/liveops-config')
            .replace(queryParameters: {
          'user_uuid': userUuid,
          'locale': locale,
          'platform': platform,
          'country': country,
          'app_version': appVersion,
        });

        final response = await _http.get(
          uri,
          headers: {
            ...AppConfig.supabaseFunctionHeaders,
            'x-user-uuid': userUuid,
          },
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          if (json['ok'] == true) {
            final snapshot = LiveOpsSnapshot.fromJson(json);
            await _cache.cacheLiveOps(snapshot.toJson());
            return snapshot;
          }
        }
      } catch (_) {}
    }

    final cached = await _cache.getLiveOps();
    if (cached != null) {
      final cachedAt = cached['fetched_at'] as String?;
      if (cachedAt != null) {
        final age = DateTime.now().difference(DateTime.parse(cachedAt));
        final ttl = cached['cache_ttl_seconds'] as int? ??
            LiveOpsDefaults.cacheTtlSeconds;
        if (age.inSeconds <= ttl * 24) {
          return LiveOpsSnapshot.fromJson({...cached, 'ok': true});
        }
      } else {
        return LiveOpsSnapshot.fromJson({...cached, 'ok': true});
      }
    }

    return LiveOpsSnapshot.fallback();
  }

  static String platformName() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'unknown';
  }
}
