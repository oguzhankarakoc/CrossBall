import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/club_header_cell.dart';
import '../../domain/puzzle.dart';

class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    super.key,
    required this.puzzle,
    required this.cells,
    required this.onCellTap,
    this.selectedRow,
    this.selectedCol,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final void Function(int row, int col) onCellTap;
  final int? selectedRow;
  final int? selectedCol;

  @override
  Widget build(BuildContext context) {
    final gridSize = puzzle.gridSize;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.cb;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - AppSpacing.md * 2).clamp(300.0, 420.0);

    const headerFraction = 0.28;
    const gridPadding = AppSpacing.sm;
    final innerWidth = maxWidth - gridPadding * 2;
    final headerWidth = (innerWidth * headerFraction).clamp(84.0, 112.0);
    final cellSize = ((innerWidth - headerWidth) / gridSize).floorToDouble().clamp(56.0, 104.0);
    final tableWidth = headerWidth + cellSize * gridSize + gridPadding * 2;
    final badgeSize = (cellSize * 0.5).clamp(32.0, 42.0);
    final colHeaderHeight = badgeSize * 1.55;
    final gridHeight = cellSize * gridSize;
    final totalHeight = colHeaderHeight + gridHeight + gridPadding * 2;

    assert(() {
      debugPrint(
        '[PuzzleGrid] rowClubs=${puzzle.rowClubs.length} colClubs=${puzzle.colClubs.length} '
        'cells=${puzzle.cells.length} tableWidth=$tableWidth totalHeight=$totalHeight '
        'cellSize=$cellSize',
      );
      return true;
    }());

    return SizedBox(
      width: tableWidth,
      height: totalHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgBorder,
          color: isDark
              ? colors.surfaceElevated.withValues(alpha: 0.9)
              : colors.surface.withValues(alpha: 0.96),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : colors.primary.withValues(alpha: 0.2),
          ),
          boxShadow: AppElevation.cardShadow(isDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(gridPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: headerWidth + cellSize * gridSize,
                height: colHeaderHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(width: headerWidth),
                    for (var col = 0; col < gridSize; col++)
                      SizedBox(
                        width: cellSize,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ClubHeaderCell(
                              club: puzzle.colClubAt(col),
                              badgeSize: badgeSize,
                              maxLabelWidth: cellSize - 4,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              ...List.generate(gridSize, (row) {
                return SizedBox(
                  width: headerWidth + cellSize * gridSize,
                  height: cellSize,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: headerWidth,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: ClubHeaderCell(
                              club: puzzle.rowClubAt(row),
                              badgeSize: badgeSize,
                              maxLabelWidth: headerWidth - 4,
                            ),
                          ),
                        ),
                      ),
                      for (var col = 0; col < gridSize; col++)
                        SizedBox(
                          width: cellSize,
                          height: cellSize,
                          child: _GridCell(
                            cell: cells['${row}_$col'],
                            size: cellSize,
                            isSelected: selectedRow == row && selectedCol == col,
                            onTap: () => onCellTap(row, col),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.cell,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final PuzzleCell? cell;
  final double size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final solved = cell?.isSolved ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = size - AppSpacing.sm;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: solved ? null : onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: solved
                ? colors.primary.withValues(alpha: 0.5)
                : isSelected
                    ? colors.primary.withValues(alpha: 0.22)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : colors.background,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(
              color: isSelected
                  ? colors.accent.withValues(alpha: 0.85)
                  : isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : colors.primary.withValues(alpha: 0.35),
              width: isSelected ? 2 : 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: SizedBox(
            width: inner,
            height: inner,
            child: Center(
              child: solved
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: colors.accent, size: 18),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            cell!.solvedPlayerName ?? '',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Icon(
                      Icons.add_rounded,
                      color: isSelected ? colors.accent : colors.primary.withValues(alpha: 0.55),
                      size: 24,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
