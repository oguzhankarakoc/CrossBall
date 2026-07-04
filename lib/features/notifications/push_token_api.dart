import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';

class PushTokenApi {
  PushTokenApi({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<void> registerToken({
    required String userUuid,
    required String token,
    required String platform,
    String? locale,
    bool? pushOptIn,
    String? appVersion,
  }) async {
    if (!AppConfig.isSupabaseConfigured) return;

    final response = await _http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/register-push-token'),
      headers: {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
        'x-user-uuid': userUuid,
      },
      body: jsonEncode({
        'user_uuid': userUuid,
        'token': token,
        'platform': platform,
        if (locale != null) 'locale': locale,
        if (pushOptIn != null) 'push_opt_in': pushOptIn,
        if (appVersion != null) 'app_version': appVersion,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      final message =
          body is Map ? (body['error'] as String? ?? 'push_register_failed') : 'push_register_failed';
      throw PushTokenException(message, response.statusCode);
    }
  }
}

class PushTokenException implements Exception {
  PushTokenException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
