import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';

class PracticeQuotaApi {
  PracticeQuotaApi({ApiHttpClient? httpClient}) : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  Future<Map<String, dynamic>> fetchQuota(String userUuid) async {
    cbDebug('Practice', 'fetchQuota GET', 'practice-quota');
    final json = await _http.getJson(
      'practice-quota',
      query: {'user_uuid': userUuid},
      headers: ApiConfig.userHeaders(userUuid),
    );
    cbDebug('Practice', 'fetchQuota OK', json);
    return json;
  }

  Future<Map<String, dynamic>> grantAdUnlock(String userUuid) async {
    return _http.postJson(
      'practice-quota',
      body: {'action': 'grant_ad_unlock'},
      headers: ApiConfig.userHeaders(userUuid),
    );
  }
}

class PracticeQuotaException implements Exception {
  PracticeQuotaException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
