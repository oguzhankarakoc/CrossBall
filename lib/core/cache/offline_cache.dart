import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/daily_puzzle_schedule.dart';

import '../constants/game_constants.dart';

/// Offline-first cache for daily puzzles, stats, and recent picks.
class OfflineCache {
  OfflineCache({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  static const _keyDailyPuzzle = 'cache_daily_puzzle_v6';
  static const _keyDailyPuzzleDate = 'cache_daily_puzzle_date_v6';
  static const _keyStats = 'cache_user_stats';
  static const _keyProgression = 'cache_player_progression_v1';
  static const _keyLiveOps = 'cache_liveops_snapshot_v1';
  static const _keyRecentPicks = 'cache_recent_picks';
  static const _keyPendingAnswers = 'cache_pending_answers';

  Future<SharedPreferences> get _prefs async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<File> _cacheFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/crossball_$name.json');
  }

  Future<void> cacheDailyPuzzle(Map<String, dynamic> puzzle) async {
    final prefs = await _prefs;
    await prefs.setString(_keyDailyPuzzle, jsonEncode(puzzle));
    await prefs.setString(
      _keyDailyPuzzleDate,
      puzzle['date'] as String? ?? DateTime.now().toIso8601String().split('T').first,
    );
    try {
      final file = await _cacheFile('daily_puzzle');
      await file.writeAsString(jsonEncode(puzzle));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getDailyPuzzle({String? forDate}) async {
    final prefs = await _prefs;
    final cachedDate = prefs.getString(_keyDailyPuzzleDate);
    final today = forDate ?? DailyPuzzleSchedule.todayPuzzleDateUtc();

    if (cachedDate == today) {
      final raw = prefs.getString(_keyDailyPuzzle);
      if (raw != null) return jsonDecode(raw) as Map<String, dynamic>;
    }

    try {
      final file = await _cacheFile('daily_puzzle');
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        if (data['date'] == today) return data;
      }
    } catch (_) {}

    return null;
  }

  Future<void> cacheStats(Map<String, dynamic> stats) async {
    final prefs = await _prefs;
    await prefs.setString(_keyStats, jsonEncode(stats));
  }

  Future<Map<String, dynamic>?> getStats() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyStats);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> cacheProgression(Map<String, dynamic> progression) async {
    final prefs = await _prefs;
    await prefs.setString(_keyProgression, jsonEncode(progression));
  }

  Future<Map<String, dynamic>?> getProgression() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyProgression);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> cacheLiveOps(Map<String, dynamic> snapshot) async {
    final prefs = await _prefs;
    await prefs.setString(_keyLiveOps, jsonEncode(snapshot));
  }

  Future<Map<String, dynamic>?> getLiveOps() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyLiveOps);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> getRecentPicks() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyRecentPicks);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> addRecentPick(Map<String, dynamic> player) async {
    final picks = await getRecentPicks();
    picks.removeWhere((p) => p['id'] == player['id']);
    picks.insert(0, player);
    if (picks.length > GameConstants.maxRecentPicks) {
      picks.removeRange(GameConstants.maxRecentPicks, picks.length);
    }
    final prefs = await _prefs;
    await prefs.setString(_keyRecentPicks, jsonEncode(picks));
  }

  Future<void> queuePendingAnswer(Map<String, dynamic> answer) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyPendingAnswers);
    final queue = raw != null
        ? (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    queue.add(answer);
    await prefs.setString(_keyPendingAnswers, jsonEncode(queue));
  }

  Future<List<Map<String, dynamic>>> flushPendingAnswers() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyPendingAnswers);
    await prefs.remove(_keyPendingAnswers);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> removePendingSession(String sessionId) async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyPendingAnswers);
    if (raw == null) return;
    final queue = (jsonDecode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
    final filtered = queue.where((entry) => entry['session_id'] != sessionId).toList();
    if (filtered.isEmpty) {
      await prefs.remove(_keyPendingAnswers);
    } else {
      await prefs.setString(_keyPendingAnswers, jsonEncode(filtered));
    }
  }

  Future<void> invalidateDailyPuzzle() async {
    final prefs = await _prefs;
    await prefs.remove(_keyDailyPuzzle);
    await prefs.remove(_keyDailyPuzzleDate);
    try {
      final file = await _cacheFile('daily_puzzle');
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
