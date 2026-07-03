import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Map<String, dynamic>?> syncUser({
    required String userUuid,
    bool onboardingComplete = false,
    bool isPremium = false,
    String? locale,
    String? themePreference,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return null;

    final response = await _http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/sync-user'),
      headers: {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
        'x-user-uuid': userUuid,
      },
      body: jsonEncode({
        'user_uuid': userUuid,
        'onboarding_complete': onboardingComplete,
        'is_premium': isPremium,
        if (locale != null) 'locale': locale,
        if (themePreference != null) 'theme_preference': themePreference,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
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
}
