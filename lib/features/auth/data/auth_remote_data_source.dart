import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';

class SyncUserException implements Exception {
  SyncUserException(this.errorCode, this.statusCode);

  final String errorCode;
  final int statusCode;

  @override
  String toString() => errorCode;
}

class AuthRemoteDataSource {
  AuthRemoteDataSource({ApiHttpClient? httpClient})
      : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

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
    if (!ApiConfig.isConfigured) {
      cbDebug('Auth', 'syncUser skipped — supabase not configured');
      throw SyncUserException('supabase_not_configured', 0);
    }

    cbDebug('Auth', 'syncUser POST', {
      'userUuid': userUuid,
      'onboardingComplete': onboardingComplete,
    });

    final body = <String, dynamic>{
      'user_uuid': userUuid,
      if (onboardingComplete != null) 'onboarding_complete': onboardingComplete,
      if (locale != null) 'locale': locale,
      if (themePreference != null) 'theme_preference': themePreference,
      if (timezoneOffsetMinutes != null) 'timezone_offset_minutes': timezoneOffsetMinutes,
      if (pushOptIn != null) 'push_opt_in': pushOptIn,
    };

    if (clearDisplayName) {
      body['display_name'] = '';
    } else if (displayName != null) {
      body['display_name'] = displayName;
    }

    try {
      final decoded = await _http.postJson(
        'sync-user',
        body: body,
        headers: ApiConfig.userHeaders(userUuid),
      );
      cbDebug('Auth', 'syncUser OK', {
        'is_premium': decoded['is_premium'],
        'display_name': decoded['display_name'],
      });
      return decoded;
    } on AppFailure catch (e) {
      final code = e is ValidationFailure ? 'sync_failed' : e.message;
      cbDebug('Auth', 'syncUser failed', {'error': code});
      throw SyncUserException(code, 0);
    }
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

  Future<void> verifyPremium({
    required String userUuid,
    required String platform,
    required String productId,
    String? verificationData,
    String? source,
  }) async {
    if (!ApiConfig.isConfigured) return;

    try {
      await _http.postJson(
        'verify-premium',
        body: {
          'user_uuid': userUuid,
          'platform': platform,
          'product_id': productId,
          if (verificationData != null) 'verification_data': verificationData,
          if (source != null) 'source': source,
        },
        headers: ApiConfig.userHeaders(userUuid),
      );
    } on AppFailure catch (e) {
      throw SyncUserException(e.message, 0);
    }
  }
}
