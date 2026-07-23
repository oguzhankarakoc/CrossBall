import 'package:shared_preferences/shared_preferences.dart';

import 'feature_info_topic.dart';

/// Remembers which feature-info sheets the user has already dismissed.
class FeatureInfoStore {
  FeatureInfoStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<bool> hasSeen(FeatureInfoTopic topic) async {
    final prefs = await _prefs;
    return prefs.getBool(topic.prefsKey) ?? false;
  }

  Future<void> markSeen(FeatureInfoTopic topic) async {
    final prefs = await _prefs;
    await prefs.setBool(topic.prefsKey, true);
  }
}
