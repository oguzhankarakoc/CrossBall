import '../../../core/network/api_http_client.dart';
import '../../search/domain/search.dart';
import '../domain/match_grid_bank.dart';
import '../domain/puzzle.dart';

class MatchGridBankApi {
  MatchGridBankApi({required ApiHttpClient httpClient}) : _http = httpClient;

  final ApiHttpClient _http;

  Future<MatchGridBank> fetchBank(Puzzle puzzle) async {
    final cells = <Map<String, dynamic>>[];
    for (var row = 0; row < puzzle.gridSize; row++) {
      for (var col = 0; col < puzzle.gridSize; col++) {
        cells.add({
          'row': row,
          'col': col,
          'row_club_id': puzzle.rowClubAt(row).id,
          'col_club_id': puzzle.colClubAt(col).id,
        });
      }
    }

    final json = await _http.postJson(
      'match-grid-bank',
      body: {'cells': cells},
    );

    if (json['ok'] != true) {
      throw StateError(json['reason']?.toString() ?? 'match_grid_bank_failed');
    }

    Player parsePlayer(Map<String, dynamic> raw) => Player(
          id: raw['id'] as String,
          name: raw['name'] as String? ?? '',
          nationalityCode: raw['nationality_code'] as String?,
          primaryPosition: raw['primary_position'] as String?,
        );

    final placements = (json['placements'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return MatchGridBankCell(
            row: (m['row'] as num).toInt(),
            col: (m['col'] as num).toInt(),
            player: parsePlayer(m['player'] as Map<String, dynamic>),
          );
        })
        .toList();

    final tray = (json['tray'] as List<dynamic>? ?? [])
        .map((e) => parsePlayer(e as Map<String, dynamic>))
        .toList();

    return MatchGridBank(placements: placements, tray: tray);
  }
}
