import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../domain/leaderboard.dart';

class LeaderboardRepositoryImpl implements LeaderboardRepository {
  LeaderboardRepositoryImpl({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({String? league, int limit = 50}) async {
    if (!AppConfig.isSupabaseConfigured) return const [];

    try {
      final params = <String, String>{'limit': '$limit'};
      if (league != null && league.isNotEmpty) params['league'] = league;

      final uri = Uri.parse('${AppConfig.supabaseUrl}/functions/v1/leaderboard')
          .replace(queryParameters: params);
      final response = await _http.get(
        uri,
        headers: {'apikey': AppConfig.supabaseAnonKey},
      );

      if (response.statusCode != 200) return const [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if (json['ok'] != true) return const [];

      final entries = json['entries'] as List<dynamic>? ?? [];
      return entries
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
