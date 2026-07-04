import 'package:equatable/equatable.dart';

class ClubMasteryEntry extends Equatable {
  const ClubMasteryEntry({
    required this.clubId,
    required this.clubName,
    required this.shortName,
    required this.intersectionsSolved,
  });

  final String clubId;
  final String clubName;
  final String shortName;
  final int intersectionsSolved;

  factory ClubMasteryEntry.fromJson(Map<String, dynamic> json) => ClubMasteryEntry(
        clubId: json['club_id'] as String,
        clubName: json['club_name'] as String? ?? '',
        shortName: json['short_name'] as String? ?? '',
        intersectionsSolved: json['intersections_solved'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [clubId, intersectionsSolved];
}
