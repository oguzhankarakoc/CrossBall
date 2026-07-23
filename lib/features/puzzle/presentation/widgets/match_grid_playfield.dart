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
    required this.onDropPlayer,
    this.validatingCellKey,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final List<Player> tray;
  final Map<String, Player> lockedByCell;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;
  final String? validatingCellKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxWidth = (screenWidth - AppSpacing.md * 2).clamp(300.0, 420.0);

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
          child: Center(
            child: _MatchGridTable(
              puzzle: puzzle,
              cells: cells,
              lockedByCell: lockedByCell,
              validatingCellKey: validatingCellKey,
              maxWidth: maxWidth,
              onDropPlayer: onDropPlayer,
            ),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final theme = Theme.of(context);
    return Container(
      width: compact ? null : 108,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.sm,
        vertical: compact ? 4 : AppSpacing.sm,
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
            size: compact ? 28 : 40,
            nationalityCode: player.nationalityCode,
          ),
          const SizedBox(height: 4),
          Text(
            player.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.15,
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
    required this.onDropPlayer,
    required this.maxWidth,
    this.validatingCellKey,
  });

  final Puzzle puzzle;
  final Map<String, PuzzleCell> cells;
  final Map<String, Player> lockedByCell;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;
  final double maxWidth;
  final String? validatingCellKey;

  @override
  Widget build(BuildContext context) {
    final gridSize = puzzle.gridSize;
    final colors = context.cb;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const headerFraction = 0.28;
    const gridPadding = AppSpacing.sm;
    final innerWidth = maxWidth - gridPadding * 2;
    final headerWidth = (innerWidth * headerFraction).clamp(72.0, 100.0);
    final cellSize =
        ((innerWidth - headerWidth) / gridSize).floorToDouble().clamp(52.0, 96.0);

    return DecoratedBox(
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: headerWidth, height: cellSize * 0.7),
                for (var col = 0; col < gridSize; col++)
                  SizedBox(
                    width: cellSize,
                    height: cellSize * 0.7,
                    child: Center(
                      child: ClubBadge(
                        club: puzzle.colClubAt(col),
                        size: (cellSize * 0.42).clamp(28.0, 40.0),
                        showLabel: false,
                        compact: true,
                      ),
                    ),
                  ),
              ],
            ),
            for (var row = 0; row < gridSize; row++)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: headerWidth,
                    height: cellSize,
                    child: Center(
                      child: ClubBadge(
                        club: puzzle.rowClubAt(row),
                        size: (cellSize * 0.42).clamp(28.0, 40.0),
                        showLabel: false,
                        compact: true,
                      ),
                    ),
                  ),
                  for (var col = 0; col < gridSize; col++)
                    _DropCell(
                      size: cellSize,
                      row: row,
                      col: col,
                      locked: lockedByCell['${row}_$col'],
                      isValidating: validatingCellKey == '${row}_$col',
                      solved: cells['${row}_$col']?.isSolved == true,
                      onDropPlayer: onDropPlayer,
                    ),
                ],
              ),
          ],
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
    this.isValidating = false,
    this.solved = false,
  });

  final double size;
  final int row;
  final int col;
  final Player? locked;
  final bool isValidating;
  final bool solved;
  final Future<bool> Function(int row, int col, Player player) onDropPlayer;

  @override
  State<_DropCell> createState() => _DropCellState();
}

class _DropCellState extends State<_DropCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;
    final locked = widget.locked;

    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) {
        if (locked != null || widget.solved) return false;
        if (!_hover) {
          HapticFeedback.selectionClick();
        }
        setState(() => _hover = true);
        return true;
      },
      onLeave: (_) => setState(() => _hover = false),
      onAcceptWithDetails: (details) async {
        setState(() => _hover = false);
        final ok = await widget.onDropPlayer(widget.row, widget.col, details.data);
        if (!ok) {
          HapticFeedback.heavyImpact();
        } else {
          HapticFeedback.mediumImpact();
        }
      },
      builder: (context, candidate, rejected) {
        final highlight = _hover || candidate.isNotEmpty;
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
                  ? Center(
                      child: _PlayerChipBody(player: locked, compact: true),
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
