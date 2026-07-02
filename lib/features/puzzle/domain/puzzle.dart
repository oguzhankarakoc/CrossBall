import 'package:equatable/equatable.dart';

enum PuzzleMode { daily, practice, challenge }

enum HintType { nationality, position, firstLetter }

enum SessionStatus { active, completed, abandoned, suspicious }

class Club extends Equatable {
  const Club({
    required this.id,
    required this.name,
    required this.slug,
    this.countryCode,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String? countryCode;
  final String? logoUrl;

  factory Club.fromJson(Map<String, dynamic> json) => Club(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        countryCode: json['country_code'] as String?,
        logoUrl: json['logo_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'country_code': countryCode,
        'logo_url': logoUrl,
      };

  @override
  List<Object?> get props => [id, name, slug];
}

class PuzzleCell extends Equatable {
  const PuzzleCell({
    required this.id,
    required this.row,
    required this.col,
    this.validAnswerCount = 0,
    this.difficulty = 0.5,
    this.solvedPlayerId,
    this.solvedPlayerName,
    this.isCorrect,
    this.usagePercentage,
    this.rarityScore,
    this.cellScore,
  });

  final String id;
  final int row;
  final int col;
  final int validAnswerCount;
  final double difficulty;
  final String? solvedPlayerId;
  final String? solvedPlayerName;
  final bool? isCorrect;
  final double? usagePercentage;
  final double? rarityScore;
  final double? cellScore;

  bool get isSolved => solvedPlayerId != null && isCorrect == true;

  PuzzleCell copyWith({
    String? solvedPlayerId,
    String? solvedPlayerName,
    bool? isCorrect,
    double? usagePercentage,
    double? rarityScore,
    double? cellScore,
  }) =>
      PuzzleCell(
        id: id,
        row: row,
        col: col,
        validAnswerCount: validAnswerCount,
        difficulty: difficulty,
        solvedPlayerId: solvedPlayerId ?? this.solvedPlayerId,
        solvedPlayerName: solvedPlayerName ?? this.solvedPlayerName,
        isCorrect: isCorrect ?? this.isCorrect,
        usagePercentage: usagePercentage ?? this.usagePercentage,
        rarityScore: rarityScore ?? this.rarityScore,
        cellScore: cellScore ?? this.cellScore,
      );

  factory PuzzleCell.fromJson(Map<String, dynamic> json) => PuzzleCell(
        id: json['id'] as String? ?? '${json['row_index']}_${json['col_index']}',
        row: json['row_index'] as int? ?? json['row'] as int,
        col: json['col_index'] as int? ?? json['col'] as int,
        validAnswerCount: json['valid_answer_count'] as int? ?? 0,
        difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      );

  @override
  List<Object?> get props => [id, row, col, isSolved];
}

class Puzzle extends Equatable {
  const Puzzle({
    required this.id,
    required this.date,
    required this.gridSize,
    required this.rowClubs,
    required this.colClubs,
    required this.cells,
    this.mode = PuzzleMode.daily,
    this.difficulty = 0.5,
  });

  final String id;
  final String date;
  final int gridSize;
  final List<Club> rowClubs;
  final List<Club> colClubs;
  final List<PuzzleCell> cells;
  final PuzzleMode mode;
  final double difficulty;

  int get totalCells => gridSize * gridSize;

  Club rowClubAt(int row) => rowClubs[row];
  Club colClubAt(int col) => colClubs[col];

  PuzzleCell? cellAt(int row, int col) {
    for (final cell in cells) {
      if (cell.row == row && cell.col == col) return cell;
    }
    return null;
  }

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    final rowClubs = (json['row_clubs'] as List<dynamic>)
        .map((e) => Club.fromJson(e as Map<String, dynamic>))
        .toList();
    final colClubs = (json['col_clubs'] as List<dynamic>)
        .map((e) => Club.fromJson(e as Map<String, dynamic>))
        .toList();
    final cells = (json['cells'] as List<dynamic>? ?? [])
        .map((e) => PuzzleCell.fromJson(e as Map<String, dynamic>))
        .toList();

    return Puzzle(
      id: json['puzzle_id'] as String? ?? json['id'] as String,
      date: json['date'] as String? ??
          DateTime.now().toIso8601String().split('T').first,
      gridSize: json['grid_size'] as int? ?? 3,
      rowClubs: rowClubs,
      colClubs: colClubs,
      cells: cells,
      mode: PuzzleMode.values.firstWhere(
        (m) => m.name == (json['mode'] as String?),
        orElse: () => PuzzleMode.daily,
      ),
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toJson() => {
        'puzzle_id': id,
        'id': id,
        'date': date,
        'grid_size': gridSize,
        'row_clubs': rowClubs.map((c) => c.toJson()).toList(),
        'col_clubs': colClubs.map((c) => c.toJson()).toList(),
        'cells': cells
            .map((c) => {
                  'id': c.id,
                  'row_index': c.row,
                  'col_index': c.col,
                  'valid_answer_count': c.validAnswerCount,
                  'difficulty': c.difficulty,
                })
            .toList(),
        'mode': mode.name,
        'difficulty': difficulty,
      };

  Puzzle copyWith({List<PuzzleCell>? cells}) => Puzzle(
        id: id,
        date: date,
        gridSize: gridSize,
        rowClubs: rowClubs,
        colClubs: colClubs,
        cells: cells ?? this.cells,
        mode: mode,
        difficulty: difficulty,
      );

  @override
  List<Object?> get props => [id, date, gridSize];
}

class AnswerResult extends Equatable {
  const AnswerResult({
    required this.correct,
    required this.playerName,
    this.usagePercentage = 0,
    this.rarityTier = 'common',
    this.rarityScore = 0,
    this.alreadyUsedInSession = false,
    this.message,
  });

  final bool correct;
  final String playerName;
  final double usagePercentage;
  final String rarityTier;
  final double rarityScore;
  final bool alreadyUsedInSession;
  final String? message;

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        correct: json['correct'] as bool? ?? false,
        playerName: json['player_name'] as String? ?? '',
        usagePercentage: (json['usage_percentage'] as num?)?.toDouble() ?? 0,
        rarityTier: json['rarity_tier'] as String? ?? 'common',
        rarityScore: (json['rarity_score'] as num?)?.toDouble() ?? 0,
        alreadyUsedInSession: json['already_used_in_session'] as bool? ?? false,
        message: json['message'] as String?,
      );

  @override
  List<Object?> get props => [correct, playerName, rarityTier];
}

class PuzzleSession extends Equatable {
  const PuzzleSession({
    required this.id,
    required this.puzzleId,
    required this.mode,
    required this.gridSize,
    this.status = SessionStatus.active,
    this.mistakes = 0,
    this.hintsUsed = 0,
    this.finalScore = 0,
    this.startedAt,
  });

  final String id;
  final String puzzleId;
  final PuzzleMode mode;
  final int gridSize;
  final SessionStatus status;
  final int mistakes;
  final int hintsUsed;
  final double finalScore;
  final DateTime? startedAt;

  @override
  List<Object?> get props => [id, puzzleId];
}
