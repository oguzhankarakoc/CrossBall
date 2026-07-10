import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/game_constants.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/rarity.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/player_identity.dart';
import '../../../search/domain/search.dart';
import '../../../../shared/providers/app_providers.dart';
import '../../../../shared/widgets/crossball_ui.dart';
import '../../../../shared/widgets/club_identity/club_identity_widgets.dart';
import '../../../../shared/widgets/player_search_card.dart';
import '../widgets/hint_reveal_chip.dart';
import '../../domain/puzzle.dart';
import '../../domain/puzzle_fetch_exception.dart';
import '../puzzle_providers.dart';

class PlayerSearchModal extends ConsumerStatefulWidget {
  const PlayerSearchModal({
    super.key,
    required this.params,
    required this.rowClub,
    required this.colClub,
    required this.cellKey,
    this.revealedHints = const [],
    this.isPremium = false,
  });

  final PuzzleGameParams params;
  final Club rowClub;
  final Club colClub;
  final String cellKey;
  final List<HintResult> revealedHints;
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
  String? _hintErrorKey;

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
    _focusNode.requestFocus();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant PlayerSearchModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cellKey != widget.cellKey) {
      _hintErrorKey = null;
    }
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
          competitive: true,
        );
    final latency = DateTime.now().difference(start).inMilliseconds;
    if (mounted) {
      ref.read(analyticsProvider).track('search_query', properties: {
        'query_length': query.length,
        'result_count': response.results.length,
        'latency_ms': latency,
      });
      setState(() {
        _results = _dedupePlayers(response.results);
        _loading = false;
      });
    }
  }

  List<Player> _dedupePlayers(List<Player> players) {
    return dedupeByPlayerIdentity<Player>(
      items: players,
      nameOf: (player) => player.name,
      identityKeyOf: (player) => player.identityKey,
      completenessScore: (player) => playerCompletenessScore(
        name: player.name,
        nationalityCode: player.nationalityCode,
        primaryPosition: player.primaryPosition,
        clubsCount: player.clubsPreview.length,
      ),
      merge: (primary, secondary) {
        final clubs = {
          ...primary.clubsPreview,
          ...secondary.clubsPreview,
        }.toList();
        return Player(
          id: primary.id,
          name: primary.name,
          nationalityCode: primary.nationalityCode ?? secondary.nationalityCode,
          primaryPosition: primary.primaryPosition ?? secondary.primaryPosition,
          clubsPreview: clubs.take(4).toList(),
          popularityScore: primary.popularityScore > secondary.popularityScore
              ? primary.popularityScore
              : secondary.popularityScore,
          isCellRelevant: primary.isCellRelevant || secondary.isCellRelevant,
          identityKey: primary.identityKey ?? secondary.identityKey,
        );
      },
    );
  }

  HintType? _nextHintType(List<HintResult> hints) => nextHintTypeForCount(hints.length);

  Future<void> _requestHint(List<HintResult> hints) async {
    final nextType = _nextHintType(hints);
    if (nextType == null || _hintLoading) return;

    setState(() {
      _hintLoading = true;
      _hintErrorKey = null;
    });
    try {
      await ref.read(puzzleGameProvider(widget.params).notifier).requestHint(nextType);
    } on HintRequestException catch (e) {
      if (mounted) {
        setState(() => _hintErrorKey = e.errorCode ?? 'hint_request_failed');
      }
    } finally {
      if (mounted) {
        setState(() => _hintLoading = false);
      }
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
    final hints = ref.watch(
      puzzleGameProvider(widget.params).select(
        (game) => game.hintsRevealed[widget.cellKey] ?? const <HintResult>[],
      ),
    );
    final nextHint = _nextHintType(hints);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
            child: CrossBallGlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xxl,
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(alpha: 0.35),
                      borderRadius: AppRadius.pillBorder,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ClubHeaderCell(
                            club: widget.rowClub,
                            badgeSize: 44,
                            maxLabelWidth: 88,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                          child: IconButton(
                            icon: Icon(Icons.close_rounded, size: 20, color: colors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                            tooltip: l10n.cancel,
                          ),
                        ),
                        Expanded(
                          child: ClubHeaderCell(
                            club: widget.colClub,
                            badgeSize: 44,
                            maxLabelWidth: 88,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hints.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final chipMaxWidth = constraints.maxWidth;
                          return Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: hints
                                .map(
                                  (hint) => HintRevealChip(
                                    hint: hint,
                                    maxWidth: chipMaxWidth,
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                  if (_hintErrorKey != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Text(
                        _hintErrorMessage(_hintErrorKey!, l10n),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.error,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (nextHint != null)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _hintLoading ? null : () => _requestHint(hints),
                          icon: _hintLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.lime),
                                )
                              : Icon(Icons.lightbulb_outline_rounded, color: colors.lime),
                          label: Text(_hintLabel(nextHint, hints.length, l10n)),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      decoration: InputDecoration(
                        hintText: l10n.searchPlayer,
                        hintStyle: TextStyle(color: colors.textSecondary),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.lime),
                        suffixIcon: _loading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.lime),
                                ),
                              )
                            : _controller.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () => _controller.clear(),
                                  )
                                : null,
                        filled: true,
                        fillColor: colors.surfaceElevated.withValues(alpha: 0.65),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.xlBorder,
                          borderSide: BorderSide(color: colors.glassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.xlBorder,
                          borderSide: BorderSide(color: colors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.xlBorder,
                          borderSide: BorderSide(color: colors.lime.withValues(alpha: 0.75), width: 2),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.xl,
                      ),
                      children: [
                        if (!hasQuery)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl,
                              vertical: AppSpacing.xxl,
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.sports_soccer_rounded,
                                  size: 56,
                                  color: colors.textSecondary.withValues(alpha: 0.35),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  l10n.searchCompetitiveEmpty,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: colors.textSecondary,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${widget.rowClub.shortLabel} × ${widget.colClub.shortLabel}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colors.lime,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        if (hasQuery)
                          ..._results.asMap().entries.map(
                                (entry) => PlayerSearchCard(
                                  player: entry.value,
                                  highlightClubs: _highlightClubs,
                                  showRelevanceBadge: entry.value.isCellRelevant,
                                  animationDelay: entry.key * 40,
                                  onTap: () => Navigator.pop(context, entry.value),
                                ),
                              ),
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
            ),
          ),
        );
      },
    );
  }

  String _hintErrorMessage(String errorKey, AppLocalizations l10n) => switch (errorKey) {
        'ad_token_required' || 'invalid_ad_token' => l10n.hintAdRequired,
        'hint_limit_reached' => l10n.hintLimitReached,
        'cell_not_found' || 'invalid_puzzle_cell_id' => l10n.answerCellNotFound,
        _ => l10n.hintUnavailable,
      };

  String _hintLabel(HintType type, int revealedCount, AppLocalizations l10n) {
    final progress = '${revealedCount + 1}/${kHintSequence.length}';
    final base = widget.isPremium
        ? switch (type) {
            HintType.nationality => l10n.hintNationalityPremium,
            HintType.position => l10n.hintPositionPremium,
            HintType.firstLetter => l10n.hintFirstLetterPremium,
            HintType.careerLeague => l10n.hintCareerLeaguePremium,
            HintType.retiredStatus => l10n.hintRetiredStatusPremium,
            HintType.careerClub => l10n.hintCareerClubPremium,
          }
        : switch (type) {
            HintType.nationality => l10n.hintNationality,
            HintType.position => l10n.hintPosition,
            HintType.firstLetter => l10n.hintFirstLetter,
            HintType.careerLeague => l10n.hintCareerLeague,
            HintType.retiredStatus => l10n.hintRetiredStatus,
            HintType.careerClub => l10n.hintCareerClub,
          };
    return '$base ($progress)';
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
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        border: Border(top: BorderSide(color: colors.glassBorder)),
        boxShadow: AppElevation.limeGlow(correct ? colors.success : colors.error),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 5,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: AppRadius.pillBorder,
            ),
          ),
          Text(
            result.playerName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: correct ? colors.success : colors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                correct ? l10n.correct : l10n.incorrect,
                style: TextStyle(
                  color: correct ? colors.success : colors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (correct) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.usedBy(result.usagePercentage.toStringAsFixed(0)),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: tier.color.withValues(alpha: 0.18),
                borderRadius: AppRadius.pillBorder,
                border: Border.all(color: tier.color.withValues(alpha: 0.65)),
              ),
              child: Text(
                '${l10n.tier}: ${tier.label}',
                style: TextStyle(
                  color: tier.color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.continueButton.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
