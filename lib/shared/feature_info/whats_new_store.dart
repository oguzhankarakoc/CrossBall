import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_build_info.dart';

/// Tracks whether the user has seen the what's-new sheet for the current build.
class WhatsNewStore {
  WhatsNewStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _key = 'whats_new_seen_version_key_v1';

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<String?> lastSeenVersionKey() async {
    final prefs = await _prefs;
    return prefs.getString(_key);
  }

  /// True for first install and every marketing/build bump.
  Future<bool> shouldShowForCurrentBuild() async {
    final last = await lastSeenVersionKey();
    return last != AppBuildInfo.versionKey;
  }

  Future<void> markCurrentBuildSeen() async {
    final prefs = await _prefs;
    await prefs.setString(_key, AppBuildInfo.versionKey);
  }
}
