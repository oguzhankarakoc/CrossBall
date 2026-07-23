import 'package:shared_preferences/shared_preferences.dart';

/// One-time contextual coach on the first daily puzzle open.
class FirstPuzzleCoachStore {
  FirstPuzzleCoachStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  static const _key = 'first_puzzle_coach_seen_v1';

  final SharedPreferences? _prefsOverride;

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<bool> hasSeen() async {
    final prefs = await _prefs;
    return prefs.getBool(_key) ?? false;
  }

  Future<void> markSeen() async {
    final prefs = await _prefs;
    await prefs.setBool(_key, true);
  }
}
