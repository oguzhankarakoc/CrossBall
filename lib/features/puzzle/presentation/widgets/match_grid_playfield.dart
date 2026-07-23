import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/club_identity/club_identity_widgets.dart';
import '../../../../shared/widgets/crossball_ui.dart';
import '../../../../shared/widgets/player_avatar.dart';
import '../../../search/domain/search.dart';
import '../../domain/puzzle.dart';

/// Drag-and-drop Match Grid: club headers + drop targets + shuffled player tray.
class MatchGridPlayfield extends StatelessWidget {
  const MatchGridPlayfield({
    super.key,
    required this.puzzle,
    required this.cells,
    required this.tray,
    required this.lockedByCell,
    required this.expectedIdsByCell,
    required this.onDropPlayer,
    this.validatingCellKey,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final List<Player> tray;
  final Map<String, Player> lockedByCell;
  /// Canonical bank map: `row_col` → player id. Wrong chips bounce immediately.
  final Map<String, String> expectedIdsByCell;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;
  final String? validatingCellKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return Column(
      children: [
        Text(
          l10n.matchGridTrayHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          flex: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: _MatchGridTable(
                  puzzle: puzzle,
                  cells: cells,
                  lockedByCell: lockedByCell,
                  expectedIdsByCell: expectedIdsByCell,
                  validatingCellKey: validatingCellKey,
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                  onDropPlayer: onDropPlayer,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          flex: 3,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.85),
              borderRadius: AppRadius.lgBorder,
              border: Border.all(color: colors.glassBorder),
            ),
            child: tray.isEmpty
                ? CrossBallEmptyState(
                    message: l10n.matchGridTrayEmpty,
                    subtitle: l10n.matchGridTrayEmptySubtitle,
                    icon: Icons.check_circle_outline_rounded,
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final player in tray)
                          _DraggablePlayerChip(player: player),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DraggablePlayerChip extends StatelessWidget {
  const _DraggablePlayerChip({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final chip = _PlayerChipBody(player: player);

    return LongPressDraggable<Player>(
      data: player,
      hapticFeedbackOnStart: true,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.92, child: chip),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: chip,
      ),
      child: chip,
    );
  }
}

class _PlayerChipBody extends StatelessWidget {
  const _PlayerChipBody({required this.player, this.compact = false});

  final Player player;
  final bool compact;

  /// Tray-friendly label: keep short names; prefer surname for long legal names.
  static String compactLabel(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return name;
    if (parts.length <= 2) return parts.join(' ');
    // "José Diogo Dalot Teixeira" → "Dalot Teixeira" (last two tokens).
    return '${parts[parts.length - 2]} ${parts.last}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);
    final label = compactLabel(player.name);
    final avatarSize = compact ? 22.0 : 32.0;
    final fontSize = compact ? 9.0 : 10.5;

    return Container(
      width: compact ? null : 92,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 6,
        vertical: compact ? 2 : 6,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: colors.lime.withValues(alpha: 0.35)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PlayerAvatar(
            seed: player.id,
            size: avatarSize,
            nationalityCode: player.nationalityCode,
          ),
          SizedBox(height: compact ? 2 : 3),
          Text(
            label,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchGridTable extends StatelessWidget {
  const _MatchGridTable({
    required this.puzzle,
    required this.cells,
    required this.lockedByCell,
    required this.expectedIdsByCell,
    required this.onDropPlayer,
    required this.maxWidth,
    required this.maxHeight,
    this.validatingCellKey,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final Map<String, Player> lockedByCell;
  final Map<String, String> expectedIdsByCell;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;
  final double maxWidth;
  final double maxHeight;
  final String? validatingCellKey;

  @override
  Widget build(BuildContext context) {
    final gridSize = puzzle.gridSize;
    final colors = context.cb;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const gridPadding = AppSpacing.sm;
    const cellGap = 4.0; // matches _DropCell margin * 2
    const headerFraction = 0.30;

    final usableW = (maxWidth - gridPadding * 2).clamp(200.0, 440.0);
    var headerWidth = (usableW * headerFraction).clamp(78.0, 108.0);
    var cellSize =
        ((usableW - headerWidth - cellGap * gridSize) / gridSize).floorToDouble();

    // Badge + 2-line short label (original crests are not recognizable alone).
    var badgeSize = (cellSize * 0.42).clamp(26.0, 38.0);
    var colHeaderHeight = badgeSize + 28.0;
    var tableHeight =
        gridPadding * 2 + colHeaderHeight + (cellSize + cellGap) * gridSize;

    if (tableHeight > maxHeight && maxHeight > 120) {
      final scale = maxHeight / tableHeight;
      cellSize = (cellSize * scale).floorToDouble().clamp(44.0, cellSize);
      headerWidth = (headerWidth * scale).clamp(64.0, headerWidth);
      badgeSize = (cellSize * 0.42).clamp(24.0, 36.0);
      colHeaderHeight = badgeSize + 26.0;
      tableHeight =
          gridPadding * 2 + colHeaderHeight + (cellSize + cellGap) * gridSize;
    }

    cellSize = cellSize.clamp(44.0, 92.0);
    // Keep a few px of slack so badge+label never trip RenderFlex overflow.
    final tableWidth = headerWidth + (cellSize + cellGap) * gridSize + gridPadding * 2;
    tableHeight =
        gridPadding * 2 + colHeaderHeight + (cellSize + cellGap) * gridSize;

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: tableWidth,
        height: tableHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorder,
            color: isDark
                ? colors.surfaceElevated.withValues(alpha: 0.9)
                : colors.surface,
            border: Border.all(color: colors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(gridPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: colHeaderHeight,
                  child: Row(
                    children: [
                      SizedBox(width: headerWidth),
                      for (var col = 0; col < gridSize; col++)
                        SizedBox(
                          width: cellSize + cellGap,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: PuzzleClubTile(
                                club: puzzle.colClubAt(col),
                                badgeSize: badgeSize,
                                maxLabelWidth: cellSize - 2,
                                labelAbove: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (var row = 0; row < gridSize; row++)
                  SizedBox(
                    height: cellSize + cellGap,
                    child: Row(
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
                                axis: Axis.horizontal,
                              ),
                            ),
                          ),
                        ),
                        for (var col = 0; col < gridSize; col++)
                          _DropCell(
                            size: cellSize,
                            row: row,
                            col: col,
                            locked: lockedByCell['${row}_$col'],
                            expectedPlayerId:
                                expectedIdsByCell['${row}_$col'],
                            isValidating: validatingCellKey == '${row}_$col',
                            solved: cells['${row}_$col']?.isSolved == true,
                            onDropPlayer: onDropPlayer,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropCell extends StatefulWidget {
  const _DropCell({
    required this.size,
    required this.row,
    required this.col,
    required this.onDropPlayer,
    this.locked,
    this.expectedPlayerId,
    this.isValidating = false,
    this.solved = false,
  });

  final double size;
  final int row;
  final int col;
  final Player? locked;
  final String? expectedPlayerId;
  final bool isValidating;
  final bool solved;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;

  @override
  State<_DropCell> createState() => _DropCellState();
}

class _DropCellState extends State<_DropCell> {
  bool _hover = false;

  bool _isCanonical(Player player) {
    final expected = widget.expectedPlayerId;
    return expected != null && expected == player.id;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final locked = widget.locked;

    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) {
        if (locked != null || widget.solved) return false;
        // Accept any chip on an empty cell so a wrong release can fire one
        // reject haptic. Only the canonical chip gets the "ready" highlight.
        if (_isCanonical(details.data)) {
          if (!_hover) {
            HapticFeedback.selectionClick();
          }
          setState(() => _hover = true);
        }
        return true;
      },
      onLeave: (_) {
        if (_hover) setState(() => _hover = false);
      },
      onAcceptWithDetails: (details) async {
        setState(() => _hover = false);
        // Career intersection is NOT enough — bounce non-canonical chips.
        if (!_isCanonical(details.data)) {
          HapticFeedback.heavyImpact();
          return;
        }
        final ok = await widget.onDropPlayer(widget.row, widget.col, details.data);
        if (!ok) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, candidate, rejected) {
        final hasCanonicalCandidate = candidate.any(
          (player) => player != null && _isCanonical(player),
        );
        final highlight = _hover || hasCanonicalCandidate;
        return Container(
          width: widget.size,
          height: widget.size,
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            color: locked != null
                ? colors.lime.withValues(alpha: 0.12)
                : highlight
                    ? colors.lime.withValues(alpha: 0.18)
                    : colors.surfaceElevated.withValues(alpha: 0.4),
            border: Border.all(
              color: locked != null
                  ? colors.lime
                  : highlight
                      ? colors.lime.withValues(alpha: 0.8)
                      : colors.glassBorder,
              width: locked != null || highlight ? 1.5 : 1,
            ),
          ),
          child: widget.isValidating
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.lime,
                    ),
                  ),
                )
              : locked != null
                  ? Padding(
                      padding: const EdgeInsets.all(2),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _PlayerChipBody(player: locked, compact: true),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.add_rounded,
                      color: colors.textSecondary.withValues(alpha: 0.35),
                    ),
        );
      },
    );
  }
}
