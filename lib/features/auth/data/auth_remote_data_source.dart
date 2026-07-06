import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/debug/crossball_debug_log.dart';

class SyncUserException implements Exception {
  SyncUserException(this.errorCode, this.statusCode);

  final String errorCode;
  final int statusCode;

  @override
  String toString() => errorCode;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Map<String, dynamic>> syncUser({
    required String userUuid,
    bool? onboardingComplete,
    String? locale,
    String? themePreference,
    String? displayName,
    int? timezoneOffsetMinutes,
    bool? pushOptIn,
    bool clearDisplayName = false,
  }) async {
    if (!AppConfig.isSupabaseConfigured) {
      cbDebug('Auth', 'syncUser skipped — supabase not configured');
      throw SyncUserException('supabase_not_configured', 0);
    }

    cbDebug('Auth', 'syncUser POST', {
      'userUuid': userUuid,
      'onboardingComplete': onboardingComplete,
    });

    final body = <String, dynamic>{
      'user_uuid': userUuid,
      'onboarding_complete': ?onboardingComplete,
      'locale': ?locale,
      'theme_preference': ?themePreference,
      'timezone_offset_minutes': ?timezoneOffsetMinutes,
      'push_opt_in': ?pushOptIn,
    };

    if (clearDisplayName) {
      body['display_name'] = '';
    } else if (displayName != null) {
      body['display_name'] = displayName;
    }

    final response = await _http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/sync-user'),
      headers: {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
        'x-user-uuid': userUuid,
      },
      body: jsonEncode(body),
    );

    final decoded = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode == 200 && decoded is Map<String, dynamic>) {
      cbDebug('Auth', 'syncUser OK', {
        'is_premium': decoded['is_premium'],
        'display_name': decoded['display_name'],
      });
      return decoded;
    }

    final errorCode = decoded is Map
        ? (decoded['error'] as String? ?? 'sync_failed')
        : 'sync_failed';
    cbDebug('Auth', 'syncUser failed', {
      'status': response.statusCode,
      'error': errorCode,
      'bodyPreview': response.body.length > 200
          ? '${response.body.substring(0, 200)}…'
          : response.body,
    });
    throw SyncUserException(errorCode, response.statusCode);
  }

  Future<void> syncPreferences({
    required String userUuid,
    String? locale,
    String? themePreference,
  }) async {
    await syncUser(
      userUuid: userUuid,
      locale: locale,
      themePreference: themePreference,
    );
  }

  /// Activates premium server-side after IAP (or dev/staging bypass).
  Future<void> verifyPremium({
    required String userUuid,
    required String platform,
    required String productId,
    String? verificationData,
    String? source,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return;

    final response = await _http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/verify-premium'),
      headers: {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
        'x-user-uuid': userUuid,
      },
      body: jsonEncode({
        'user_uuid': userUuid,
        'platform': platform,
        'product_id': productId,
        'verification_data': ?verificationData,
        'source': ?source,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final decoded = response.body.isNotEmpty
          ? jsonDecode(response.body)
          : <String, dynamic>{};
      final errorCode = decoded is Map
          ? (decoded['error'] as String? ?? 'verify_failed')
          : 'verify_failed';
      throw SyncUserException(errorCode, response.statusCode);
    }
  }
}
