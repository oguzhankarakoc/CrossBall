import '../../../core/network/api_config.dart';
import '../../../core/network/api_http_client.dart';

class PushTokenApi {
  PushTokenApi({ApiHttpClient? httpClient}) : _http = httpClient ?? ApiHttpClient();

  final ApiHttpClient _http;

  Future<void> registerToken({
    required String userUuid,
    required String token,
    required String platform,
    String? locale,
    bool? pushOptIn,
    String? appVersion,
  }) async {
    await _http.postJson(
      'register-push-token',
      body: {
        'user_uuid': userUuid,
        'token': token,
        'platform': platform,
        if (locale != null) 'locale': locale,
        if (pushOptIn != null) 'push_opt_in': pushOptIn,
        if (appVersion != null) 'app_version': appVersion,
      },
      headers: ApiConfig.userHeaders(userUuid),
    );
  }
}

class PushTokenException implements Exception {
  PushTokenException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}
