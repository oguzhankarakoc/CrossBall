/// Keep in sync with `pubspec.yaml` `version:`.
abstract final class AppBuildInfo {
  static const versionName = '1.0.2';
  static const buildNumber = 26;

  /// Unique key for update / first-open what's-new gating.
  static String get versionKey => '$versionName+$buildNumber';
}
