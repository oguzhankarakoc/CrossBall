import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<void> syncUser({
    required String userUuid,
    bool onboardingComplete = false,
    bool isPremium = false,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return;

    await _http.post(
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
      }),
    );
  }
}
