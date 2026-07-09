import 'dart:io';

import '../../../core/cache/offline_cache.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';
import '../domain/liveops_snapshot.dart';

class LiveOpsRepositoryImpl implements LiveOpsRepository {
  LiveOpsRepositoryImpl({
    required OfflineCache cache,
    ApiHttpClient? httpClient,
  })  : _cache = cache,
        _http = httpClient ?? ApiHttpClient();

  final OfflineCache _cache;
  final ApiHttpClient _http;

  @override
  Future<LiveOpsSnapshot> getSnapshot({
    required String userUuid,
    required String locale,
    required String platform,
    String country = '',
    String appVersion = '1.0.0',
  }) async {
    try {
      final json = await _http.getJson(
        'liveops-config',
        query: {
          'user_uuid': userUuid,
          'locale': locale,
          'platform': platform,
          'country': country,
          'app_version': appVersion,
        },
        headers: ApiConfig.userHeaders(userUuid),
        throwOnError: false,
      );
      if (json['ok'] == true) {
        final snapshot = LiveOpsSnapshot.fromJson(json);
        await _cache.cacheLiveOps(snapshot.toJson());
        return snapshot;
      }
    } catch (_) {}

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
