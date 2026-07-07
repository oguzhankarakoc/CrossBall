import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/puzzle/domain/puzzle.dart';

/// Persists in-progress puzzle state so navigation / app restart can resume fairly.
class ActivePuzzleCache {
  ActivePuzzleCache({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;
  static const _keyPrefix = 'cache_active_puzzle_v1_';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  String _storageKey({
    required PuzzleMode mode,
    String? challengeId,
    int? gridSize,
  }) =>
      '$_keyPrefix${mode.name}_${challengeId ?? 'none'}_${gridSize ?? 3}';

  Future<void> save({
    required PuzzleMode mode,
    String? challengeId,
    int? gridSize,
    required Map<String, dynamic> snapshot,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(
      _storageKey(mode: mode, challengeId: challengeId, gridSize: gridSize),
      jsonEncode(snapshot),
    );
  }

  Future<Map<String, dynamic>?> load({
    required PuzzleMode mode,
    String? challengeId,
    int? gridSize,
  }) async {
    final prefs = await _prefs;
    final raw = prefs.getString(
      _storageKey(mode: mode, challengeId: challengeId, gridSize: gridSize),
    );
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear({
    required PuzzleMode mode,
    String? challengeId,
    int? gridSize,
  }) async {
    final prefs = await _prefs;
    await prefs.remove(
      _storageKey(mode: mode, challengeId: challengeId, gridSize: gridSize),
    );
  }
}
