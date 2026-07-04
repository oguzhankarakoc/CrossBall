import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';

class PracticeQuotaApi {
  PracticeQuotaApi({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<Map<String, dynamic>> fetchQuota(String userUuid) async {
    final response = await _http.get(
      Uri.parse(
        '${AppConfig.supabaseUrl}/functions/v1/practice-quota?user_uuid=$userUuid',
      ),
      headers: _headers(userUuid),
    );
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> grantAdUnlock(String userUuid) async {
    final response = await _http.post(
      Uri.parse('${AppConfig.supabaseUrl}/functions/v1/practice-quota'),
      headers: _headers(userUuid),
      body: jsonEncode({'action': 'grant_ad_unlock'}),
    );
    return _parseResponse(response);
  }

  Map<String, String> _headers(String userUuid) => {
        'apikey': AppConfig.supabaseAnonKey,
        'Content-Type': 'application/json',
        'x-user-uuid': userUuid,
      };

  Map<String, dynamic> _parseResponse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body as Map<String, dynamic>;
    }
    final message = body is Map ? (body['error'] as String? ?? 'quota_error') : 'quota_error';
    throw PracticeQuotaException(message, response.statusCode);
  }
}

class PracticeQuotaException implements Exception {
  PracticeQuotaException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
