import 'package:equatable/equatable.dart';

class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    this.nationalityCode,
    this.primaryPosition,
    this.clubsPreview = const [],
    this.popularityScore = 0,
    this.isCellRelevant = false,
  });

  final String id;
  final String name;
  final String? nationalityCode;
  final String? primaryPosition;
  final List<String> clubsPreview;
  final int popularityScore;
  final bool isCellRelevant;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        nationalityCode: json['nationality_code'] as String?,
        primaryPosition: json['primary_position'] as String?,
        clubsPreview: (json['clubs_preview'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        popularityScore: json['popularity_score'] as int? ?? 0,
        isCellRelevant: json['is_cell_relevant'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationality_code': nationalityCode,
        'primary_position': primaryPosition,
        'clubs_preview': clubsPreview,
        'popularity_score': popularityScore,
        'is_cell_relevant': isCellRelevant,
      };

  @override
  List<Object?> get props => [id, name];
}

class SearchContext extends Equatable {
  const SearchContext({
    this.rowClubId,
    this.colClubId,
    this.rowClubLabel,
    this.colClubLabel,
  });

  final String? rowClubId;
  final String? colClubId;
  final String? rowClubLabel;
  final String? colClubLabel;

  bool get hasCellContext => rowClubId != null && colClubId != null;

  @override
  List<Object?> get props => [rowClubId, colClubId];
}

class SearchResponse extends Equatable {
  const SearchResponse({
    required this.results,
    this.suggested = const [],
    this.latencyMs = 0,
  });

  final List<Player> results;
  final List<Player> suggested;
  final int latencyMs;

  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        suggested: (json['suggested'] as List<dynamic>? ?? [])
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        latencyMs: json['latency_ms'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [results, suggested, latencyMs];
}

abstract interface class SearchRepository {
  Future<SearchResponse> search(
    String query, {
    int limit = 20,
    SearchContext? context,
  });
  Future<List<Player>> getRecentPicks();
  Future<List<Player>> getPopularPicks({int limit = 10, SearchContext? context});
  Future<List<Player>> getSuggestedForCell(SearchContext context, {int limit = 12});
  Future<void> recordPick(Player player);
}
