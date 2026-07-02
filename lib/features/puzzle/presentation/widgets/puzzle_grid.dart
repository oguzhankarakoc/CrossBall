import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
    final size = puzzle.gridSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final headerWidth = constraints.maxWidth * 0.22;
        final cellSize = (constraints.maxWidth - headerWidth) / size;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(width: headerWidth),
                ...List.generate(size, (col) {
                  return SizedBox(
                    width: cellSize,
                    child: _ClubLabel(
                      name: puzzle.colClubAt(col).name,
                      vertical: false,
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(size, (row) {
              return Row(
                children: [
                  SizedBox(
                    width: headerWidth,
                    height: cellSize,
                    child: _ClubLabel(
                      name: puzzle.rowClubAt(row).name,
                      vertical: true,
                    ),
                  ),
                  ...List.generate(size, (col) {
                    final key = '${row}_$col';
                    final cell = cells[key];
                    final isSelected = selectedRow == row && selectedCol == col;
                    return _GridCell(
                      cell: cell,
                      size: cellSize,
                      isSelected: isSelected,
                      onTap: () => onCellTap(row, col),
                    );
                  }),
                ],
              );
            }),
          ],
        );
      },
    );
  }
}

class _ClubLabel extends StatelessWidget {
  const _ClubLabel({required this.name, required this.vertical});

  final String name;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final shortName = name.length > 12 ? name.split(' ').first : name;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Text(
          shortName,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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

    return Padding(
      padding: const EdgeInsets.all(3),
      child: Material(
        color: solved
            ? colors.primary.withValues(alpha: 0.55)
            : isSelected
                ? colors.primary.withValues(alpha: 0.25)
                : colors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        elevation: isSelected ? 6 : 2,
        shadowColor: isSelected ? colors.accent.withValues(alpha: 0.3) : null,
        child: InkWell(
          onTap: solved ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: size - 6,
            height: size - 6,
            child: Center(
              child: solved
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: colors.accent, size: 18),
                        const SizedBox(height: 2),
                        Text(
                          cell!.solvedPlayerName ?? '',
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Icon(
                      Icons.add,
                      color: isSelected ? colors.accent : colors.textSecondary,
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
