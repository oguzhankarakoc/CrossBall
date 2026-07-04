import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/rarity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../search/domain/search.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/club_header_cell.dart';
import '../../../../shared/widgets/player_search_card.dart';
import '../../domain/puzzle.dart';
import '../puzzle_providers.dart';

class PlayerSearchModal extends ConsumerStatefulWidget {
  const PlayerSearchModal({
    super.key,
    required this.params,
    required this.rowClub,
    required this.colClub,
    this.revealedHints = const [],
    this.isPremium = false,
  });

  final PuzzleGameParams params;
  final Club rowClub;
  final Club colClub;
  final List<String> revealedHints;
  final bool isPremium;

  @override
  ConsumerState<PlayerSearchModal> createState() => _PlayerSearchModalState();
}

class _PlayerSearchModalState extends ConsumerState<PlayerSearchModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Player> _results = [];
  bool _loading = false;
  bool _hintLoading = false;
  late List<String> _hints;

  SearchContext get _searchContext => SearchContext(
        rowClubId: widget.rowClub.id,
        colClubId: widget.colClub.id,
        rowClubLabel: widget.rowClub.shortLabel,
        colClubLabel: widget.colClub.shortLabel,
      );

  Set<String> get _highlightClubs => {
        widget.rowClub.shortLabel,
        widget.colClub.shortLabel,
        if (widget.rowClub.shortName != null) widget.rowClub.shortName!,
        if (widget.colClub.shortName != null) widget.colClub.shortName!,
        widget.rowClub.name,
        widget.colClub.name,
      };

  static const _hintSequence = [
    HintType.nationality,
    HintType.position,
    HintType.firstLetter,
    HintType.careerLeague,
    HintType.retiredStatus,
    HintType.careerClub,
  ];

  @override
  void initState() {
    super.initState();
    _hints = List<String>.from(widget.revealedHints);
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: GameConstants.searchDebounceMs),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _loading = true);
    final start = DateTime.now();
    final response = await ref.read(searchRepositoryProvider).search(
          query,
          context: _searchContext,
        );
    final latency = DateTime.now().difference(start).inMilliseconds;
    if (mounted) {
      ref.read(analyticsProvider).track('search_query', properties: {
        'query_length': query.length,
        'result_count': response.results.length,
        'latency_ms': latency,
      });
      setState(() {
        _results = response.results;
        _loading = false;
      });
    }
  }

  HintType? get _nextHintType {
    if (_hints.length >= _hintSequence.length) return null;
    final next = _hintSequence[_hints.length];
    if (next == HintType.careerClub && !widget.isPremium) return null;
    return next;
  }

  Future<void> _requestHint() async {
    final nextType = _nextHintType;
    if (nextType == null || _hintLoading) return;

    setState(() => _hintLoading = true);
    final result =
        await ref.read(puzzleGameProvider(widget.params).notifier).requestHint(nextType);
    if (mounted) {
      setState(() {
        _hintLoading = false;
        if (result != null) _hints.add(result.hintValue);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final query = _controller.text.trim();
    final hasQuery = query.isNotEmpty;
    final nextHint = _nextHintType;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: colors.surface,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textSecondary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClubHeaderCell(
                      club: widget.rowClub,
                      badgeSize: 40,
                      maxLabelWidth: 72,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Icon(Icons.close, size: 14, color: colors.textSecondary),
                    ),
                    ClubHeaderCell(
                      club: widget.colClub,
                      badgeSize: 40,
                      maxLabelWidth: 72,
                    ),
                  ],
                ),
              ),
              if (_hints.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _hints
                        .map(
                          (h) => Chip(
                            label: Text(h),
                            backgroundColor: colors.surfaceElevated,
                            side: BorderSide(color: colors.cardBorder),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (nextHint != null)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _hintLoading ? null : _requestHint,
                      icon: _hintLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                            )
                          : Icon(Icons.lightbulb_outline, color: colors.accent),
                      label: Text(_hintLabel(nextHint, l10n)),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  style: TextStyle(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: l10n.searchPlayer,
                    prefixIcon: Icon(Icons.search, color: colors.iconTint),
                    suffixIcon: _loading
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.accent),
                            ),
                          )
                        : _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _controller.clear(),
                              )
                            : null,
                    filled: true,
                    fillColor: colors.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorder,
                      borderSide: BorderSide(color: colors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorder,
                      borderSide: BorderSide(color: colors.cardBorder.withValues(alpha: 0.6)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.mdBorder,
                      borderSide: BorderSide(color: colors.accent.withValues(alpha: 0.65)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  children: [
                    if (!hasQuery)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            l10n.searchPlayer,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ),
                    if (hasQuery)
                      ..._results.map((p) => PlayerSearchCard(
                            player: p,
                            highlightClubs: _highlightClubs,
                            showRelevanceBadge: false,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    if (hasQuery && _results.isEmpty && !_loading)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Center(
                          child: Text(
                            l10n.noPlayersFound,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _hintLabel(HintType type, AppLocalizations l10n) => switch (type) {
        HintType.nationality => l10n.hintNationality,
        HintType.position => l10n.hintPosition,
        HintType.firstLetter => l10n.hintFirstLetter,
        HintType.careerLeague => l10n.hintCareerLeague,
        HintType.retiredStatus => l10n.hintRetiredStatus,
        HintType.careerClub => l10n.hintCareerClub,
      };
}

class AnswerResultSheet extends StatelessWidget {
  const AnswerResultSheet({super.key, required this.result});

  final AnswerResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final correct = result.correct;
    final tier = RarityTier.fromUsagePercentage(result.usagePercentage);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        border: Border(top: BorderSide(color: colors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.playerName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? colors.primary : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(correct ? l10n.correct : l10n.incorrect),
            ],
          ),
          if (correct) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.usedBy(result.usagePercentage.toStringAsFixed(0)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.2),
                borderRadius: AppRadius.smBorder,
                border: Border.all(color: tier.color),
              ),
              child: Text(
                '${l10n.tier}: ${tier.label}',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
  }
}
