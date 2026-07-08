import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/club_identity/club_badge_tokens.dart';
import '../../../../shared/widgets/club_identity/club_identity_widgets.dart';
import '../../domain/puzzle.dart';

class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({
    super.key,
    required this.puzzle,
    required this.cells,
    required this.onCellTap,
    this.selectedRow,
    this.selectedCol,
    this.validatingCellKey,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final void Function(int row, int col) onCellTap;
  final int? selectedRow;
  final int? selectedCol;
  final String? validatingCellKey;

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
              : colors.surface,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : colors.primary.withValues(alpha: 0.45),
            width: isDark ? 1 : 1.5,
          ),
          boxShadow: AppElevation.cardShadow(isDark, tint: colors.primary),
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
                            child: PuzzleClubTile(
                              club: puzzle.colClubAt(col),
                              badgeSize: badgeSize,
                              maxLabelWidth: cellSize - 4,
                              visualState: _headerState(
                                gridSize: gridSize,
                                index: col,
                                isRow: false,
                                selected: selectedCol,
                              ),
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
                            child: PuzzleClubTile(
                              club: puzzle.rowClubAt(row),
                              badgeSize: badgeSize,
                              maxLabelWidth: headerWidth - 4,
                              visualState: _headerState(
                                gridSize: gridSize,
                                index: row,
                                isRow: true,
                                selected: selectedRow,
                              ),
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
                            isValidating: validatingCellKey == '${row}_$col',
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

  ClubBadgeVisualState _headerState({
    required int gridSize,
    required int index,
    required bool isRow,
    required int? selected,
  }) {
    if (selected == index) return ClubBadgeVisualState.selected;
    final fullySolved = isRow ? _rowFullySolved(gridSize, index) : _colFullySolved(gridSize, index);
    if (fullySolved) return ClubBadgeVisualState.solved;
    return ClubBadgeVisualState.normal;
  }

  bool _rowFullySolved(int gridSize, int row) {
    for (var col = 0; col < gridSize; col++) {
      if (!(cells['${row}_$col']?.isSolved ?? false)) return false;
    }
    return true;
  }

  bool _colFullySolved(int gridSize, int col) {
    for (var row = 0; row < gridSize; row++) {
      if (!(cells['${row}_$col']?.isSolved ?? false)) return false;
    }
    return true;
  }
}

class _GridCell extends StatefulWidget {
  const _GridCell({
    required this.cell,
    required this.size,
    required this.isSelected,
    required this.isValidating,
    required this.onTap,
  });

  final PuzzleCell? cell;
  final double size;
  final bool isSelected;
  final bool isValidating;
  final VoidCallback onTap;

  @override
  State<_GridCell> createState() => _GridCellState();
}

class _GridCellState extends State<_GridCell> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _GridCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final solved = widget.cell?.isSolved ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inner = widget.size - AppSpacing.sm;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: solved || widget.isValidating ? null : widget.onTap,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final glow = widget.isSelected ? 0.15 + _pulseController.value * 0.12 : 0.0;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: solved
                    ? colors.success.withValues(alpha: isDark ? 0.22 : 0.18)
                    : widget.isSelected
                        ? colors.lime.withValues(alpha: 0.12 + glow)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : colors.surfaceElevated,
                borderRadius: AppRadius.lgBorder,
                border: Border.all(
                  color: solved
                      ? colors.success.withValues(alpha: 0.65)
                      : widget.isSelected
                          ? colors.lime.withValues(alpha: 0.85)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : colors.primary.withValues(alpha: 0.4),
                  width: widget.isSelected ? 2 : 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: widget.isSelected
                    ? AppElevation.limeGlow(colors.lime)
                    : solved
                        ? [
                            BoxShadow(
                              color: colors.success.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ]
                        : null,
              ),
              child: child,
            );
          },
          child: SizedBox(
            width: inner,
            height: inner,
            child: Center(
              child: widget.isValidating
                  ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: colors.lime,
                      ),
                    )
                  : solved
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, color: colors.success, size: 20),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            widget.cell!.solvedPlayerName ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.textPrimary,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : widget.isSelected
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.touch_app_rounded, color: colors.lime, size: 22),
                            Text(
                              AppLocalizations.of(context)!.gridSelectCell,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: colors.lime,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          Icons.add_rounded,
                          color: isDark
                              ? colors.primary.withValues(alpha: 0.5)
                              : colors.primary.withValues(alpha: 0.85),
                          size: 24,
                        ),
            ),
          ),
        ),
      ),
    );
  }
}
