import '../../search/domain/search.dart';

class MatchGridBankCell {
  const MatchGridBankCell({
    required this.row,
    required this.col,
    required this.player,
  });

  final int row;
  final int col;
  final Player player;

  String get cellKey => '${row}_$col';
}

class MatchGridBank {
  const MatchGridBank({
    required this.placements,
    required this.tray,
  });

  final List<MatchGridBankCell> placements;
  final List<Player> tray;

  Player? expectedPlayerFor(int row, int col) {
    for (final p in placements) {
      if (p.row == row && p.col == col) return p.player;
    }
    return null;
  }

  /// cellKey (`row_col`) → canonical player id for that cell.
  Map<String, String> get expectedIdsByCell => {
        for (final p in placements) p.cellKey: p.player.id,
      };
}
