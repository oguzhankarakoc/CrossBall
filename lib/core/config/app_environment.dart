import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Deployment target — single source for API base URL resolution.
enum AppEnvironment {
  development,
  staging,
  production;

  static AppEnvironment get current {
    final raw = dotenv.env['APP_ENV']?.trim().toLowerCase() ?? 'production';
    return switch (raw) {
      'dev' || 'development' || 'local' => AppEnvironment.development,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.production,
    };
  }

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}
