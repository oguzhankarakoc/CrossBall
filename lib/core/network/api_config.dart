import '../config/app_config.dart';
import '../config/app_environment.dart';

/// Central API configuration — never hardcode URLs in repositories.
abstract final class ApiConfig {
  static AppEnvironment get environment => AppEnvironment.current;

  /// Supabase project URL (Edge Functions + REST).
  static String get baseUrl => AppConfig.supabaseUrl;

  static String get functionsBaseUrl => '$baseUrl/functions/v1';

  static bool get isConfigured => AppConfig.isSupabaseConfigured;

  static Map<String, String> get defaultHeaders => AppConfig.supabaseFunctionHeaders;

  static Duration get connectTimeout => const Duration(seconds: 15);

  static Duration get receiveTimeout => const Duration(seconds: 30);

  static int get maxRetries => environment.isDevelopment ? 1 : 2;

  static Map<String, String> userHeaders(String userUuid) => {
        ...defaultHeaders,
        'x-user-uuid': userUuid,
      };

  static Uri functionUri(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$functionsBaseUrl/$normalized').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }
}
