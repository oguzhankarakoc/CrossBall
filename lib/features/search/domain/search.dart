import 'package:equatable/equatable.dart';

class Player extends Equatable {
  const Player({
    required this.id,
    required this.name,
    this.nationalityCode,
    this.primaryPosition,
    this.clubsPreview = const [],
  });

  final String id;
  final String name;
  final String? nationalityCode;
  final String? primaryPosition;
  final List<String> clubsPreview;

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'] as String,
        name: json['name'] as String,
        nationalityCode: json['nationality_code'] as String?,
        primaryPosition: json['primary_position'] as String?,
        clubsPreview: (json['clubs_preview'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nationality_code': nationalityCode,
        'primary_position': primaryPosition,
        'clubs_preview': clubsPreview,
      };

  @override
  List<Object?> get props => [id, name];
}

class SearchResponse extends Equatable {
  const SearchResponse({
    required this.results,
    this.latencyMs = 0,
  });

  final List<Player> results;
  final int latencyMs;

  factory SearchResponse.fromJson(Map<String, dynamic> json) => SearchResponse(
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => Player.fromJson(e as Map<String, dynamic>))
            .toList(),
        latencyMs: json['latency_ms'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [results, latencyMs];
}

abstract interface class SearchRepository {
  Future<SearchResponse> search(String query, {int limit = 20});
  Future<List<Player>> getRecentPicks();
  Future<List<Player>> getPopularPicks({int limit = 10});
  Future<void> recordPick(Player player);
}
