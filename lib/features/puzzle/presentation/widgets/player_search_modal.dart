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
  });

  final PuzzleGameParams params;
  final Club rowClub;
  final Club colClub;
  final List<String> revealedHints;

  @override
  ConsumerState<PlayerSearchModal> createState() => _PlayerSearchModalState();
}

class _PlayerSearchModalState extends ConsumerState<PlayerSearchModal> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Player> _results = [];
  List<Player> _recent = [];
  List<Player> _popular = [];
  List<Player> _suggested = [];
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

  @override
  void initState() {
    super.initState();
    _hints = List<String>.from(widget.revealedHints);
    _loadInitial();
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  Future<void> _loadInitial() async {
    final repo = ref.read(searchRepositoryProvider);
    final results = await Future.wait([
      repo.getRecentPicks(),
      repo.getSuggestedForCell(_searchContext),
      repo.getPopularPicks(context: _searchContext),
    ]);
    if (mounted) {
      setState(() {
        _recent = results[0];
        _suggested = results[1];
        _popular = results[2];
        _results = _recent.isNotEmpty ? _recent : _popular;
      });
    }
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: GameConstants.searchDebounceMs),
      () => _search(_controller.text),
    );
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      await _loadInitial();
      return;
    }

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
    if (_hints.isEmpty) return HintType.nationality;
    if (_hints.length == 1) return HintType.position;
    if (_hints.length == 2) return HintType.firstLetter;
    return null;
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
    final query = _controller.text;
    final showSections = query.isEmpty;
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
                                onPressed: () {
                                  _controller.clear();
                                  _loadInitial();
                                },
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
                    if (showSections && _recent.isNotEmpty) ...[
                      _SectionHeader(title: l10n.recentPicks, icon: Icons.history),
                      ..._recent.map((p) => PlayerSearchCard(
                            player: p,
                            highlightClubs: _highlightClubs,
                            showRelevanceBadge: p.isCellRelevant,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    ],
                    if (showSections && _suggested.isNotEmpty) ...[
                      _SectionHeader(title: l10n.suggestedForCell, icon: Icons.bolt),
                      ..._suggested.map((p) => PlayerSearchCard(
                            player: p,
                            highlightClubs: _highlightClubs,
                            showRelevanceBadge: true,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    ],
                    if (showSections && _popular.isNotEmpty) ...[
                      _SectionHeader(title: l10n.popularPicks, icon: Icons.trending_up),
                      ..._popular.map((p) => PlayerSearchCard(
                            player: p,
                            highlightClubs: _highlightClubs,
                            showRelevanceBadge: p.isCellRelevant,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    ],
                    if (!showSections)
                      ..._results.map((p) => PlayerSearchCard(
                            player: p,
                            highlightClubs: _highlightClubs,
                            showRelevanceBadge: p.isCellRelevant,
                            onTap: () => Navigator.pop(context, p),
                          )),
                    if (!showSections && _results.isEmpty && !_loading && query.isNotEmpty)
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
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colors.accent),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.accent,
                  letterSpacing: 0.2,
                ),
          ),
        ],
      ),
    );
  }
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
