import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/debug/crossball_debug_log.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/daily_puzzle_schedule.dart';
import '../../../core/utils/rarity.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/crossball_error_panel.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../../shared/widgets/mythic_celebration_overlay.dart';
import '../../../features/social/presentation/football_fact_banner.dart';
import '../../../features/social/presentation/career_timeline_sheet.dart';
import '../../challenge/domain/challenge.dart';
import '../../../features/ads/ads_service.dart';
import '../../../features/auth/presentation/auth_providers.dart';
import '../../../features/liveops/presentation/liveops_providers.dart';
import '../../../features/premium/premium_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/session_providers.dart';
import '../../../shared/providers/practice_session_provider.dart';
import '../domain/puzzle.dart';
import 'puzzle_providers.dart';
import 'daily_puzzle_rollout_provider.dart';
import 'widgets/daily_puzzle_refresh_panel.dart';
import 'widgets/player_search_modal.dart';
import 'widgets/puzzle_grid.dart';
import 'widgets/puzzle_result_screen.dart';
import 'widgets/puzzle_timer.dart';

class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({
    super.key,
    required this.params,
  });

  final PuzzleGameParams params;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> {
  Timer? _dailyRefreshPollTimer;

  bool get _isTrainingMode =>
      widget.params.mode == PuzzleMode.practice ||
      widget.params.mode == PuzzleMode.timeline;

  @override
  void initState() {
    super.initState();
    if (_isTrainingMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(practiceSessionProvider.notifier).syncForCurrentUser();
      });
    }
    ref.listenManual(
      puzzleGameProvider(widget.params).select((s) => s.error),
      (previous, next) {
        if (next != null && next != previous) {
          cbDebug('Puzzle', 'UI showing error', {
            'mode': widget.params.mode.name,
            'errorKey': next,
          });
        }
        _syncDailyRefreshPolling(next);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _dailyRefreshPollTimer?.cancel();
    super.dispose();
  }

  void _syncDailyRefreshPolling(String? errorKey) {
    _dailyRefreshPollTimer?.cancel();
    if (widget.params.mode != PuzzleMode.daily) return;
    if (errorKey != 'daily_puzzle_generating') return;

    final rollout = ref.read(dailyPuzzleRolloutProvider).valueOrNull;
    final retrySeconds = rollout?.retryAfterSeconds ?? 30;
    _dailyRefreshPollTimer = Timer.periodic(Duration(seconds: retrySeconds), (_) async {
      if (!mounted) return;
      await ref.read(dailyPuzzleRolloutProvider.notifier).refresh();
      await ref.read(puzzleGameProvider(widget.params).notifier).loadPuzzle(forceRefresh: true);
    });
  }

  Future<void> _retryDailyPuzzle() async {
    await ref.read(dailyPuzzleRolloutProvider.notifier).refresh();
    await ref.read(puzzleGameProvider(widget.params).notifier).loadPuzzle(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final game = ref.watch(puzzleGameProvider(widget.params));

    if (game.isComplete) {
      if (game.challengeResult != null) {
        return ChallengeResultScreen(
          result: game.challengeResult!,
          yourScore: game.totalScore,
          onHome: () => context.go(AppRoutes.home),
          onRematch: () => _createRematch(context),
        );
      }
      if (_isTrainingMode) {
        return _buildPracticeResult(context, game);
      }
      return PuzzleResultScreen(
        score: game.totalScore,
        mistakes: game.mistakes,
        hintsUsed: game.hintsUsed,
        streak: ref.watch(userStatsProvider).valueOrNull?.currentStreak ?? 0,
        onHome: () => context.go(AppRoutes.home),
        onShareChallenge: _createChallengeFromResult,
      );
    }

    final practiceSession = _isTrainingMode ? ref.watch(practiceSessionProvider) : null;
    final showAiFacts = ref.watch(featureFlagProvider('ai_features'));
    final factContext = widget.params.mode == PuzzleMode.timeline ? 'timeline' : 'intersection';
    final footballFact = showAiFacts
        ? ref.watch(footballFactProvider(factContext)).valueOrNull
        : null;

    return Scaffold(
      appBar: CrossBallAppBar(
        title: _title(l10n),
        actions: [
          if (practiceSession != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated.withValues(alpha: 0.8),
                    borderRadius: AppRadius.pillBorder,
                    border: Border.all(color: colors.glassBorder),
                  ),
                  child: Text(
                    l10n.practiceSessionProgress(
                      practiceSession.completedToday + 1,
                      practiceSession.dailyLimit,
                    ),
                    style: TextStyle(
                      color: colors.lime,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated.withValues(alpha: 0.8),
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(color: colors.glassBorder),
                ),
                child: Text(
                  '${game.solvedCount}/${game.totalCells}',
                  style: TextStyle(
                    color: colors.lime,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: PitchBackground(
        child: game.isLoading
            ? Center(
                child: CircularProgressIndicator(color: colors.lime),
              )
            : game.error == 'practice_limit_reached'
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(l10n.practiceLimitReached, textAlign: TextAlign.center),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: () => context.push(AppRoutes.premium),
                            child: Text(l10n.upgradePremium),
                          ),
                        ],
                      ),
                    ),
                  )
                : game.error == 'practice_ad_required'
                    ? _buildPracticeAdGate(context, l10n, colors)
                : game.error == 'daily_puzzle_generating' ||
                        game.error == 'daily_puzzle_failed'
                    ? DailyPuzzleRefreshPanel(
                        startedAt: ref
                            .watch(dailyPuzzleRolloutProvider)
                            .valueOrNull
                            ?.startedAt,
                        elapsedSeconds: ref
                                .watch(dailyPuzzleRolloutProvider)
                                .valueOrNull
                                ?.elapsedSeconds ??
                            0,
                        isFailed: game.error == 'daily_puzzle_failed',
                        errorMessage: ref
                            .watch(dailyPuzzleRolloutProvider)
                            .valueOrNull
                            ?.errorMessage,
                        retryAfterSeconds: ref
                                .watch(dailyPuzzleRolloutProvider)
                                .valueOrNull
                                ?.retryAfterSeconds ??
                            30,
                        onRetry: _retryDailyPuzzle,
                      )
                : game.error == 'puzzle_load_failed' ||
                        game.error == 'practice_load_failed'
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                game.error == 'practice_load_failed'
                                    ? l10n.practiceLoadFailed
                                    : l10n.puzzleLoadFailed,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton(
                                onPressed: () => ref
                                    .read(puzzleGameProvider(widget.params).notifier)
                                    .loadPuzzle(forceRefresh: true),
                                child: Text(l10n.retry),
                              ),
                            ],
                          ),
                        ),
                      )
                : game.error != null
                    ? Center(
                        child: CrossBallErrorPanel(
                          message: localizedErrorMessage(l10n, game.error),
                          onRetry: () => ref
                              .read(puzzleGameProvider(widget.params).notifier)
                              .loadPuzzle(),
                        ),
                      )
                    : game.puzzle == null
                        ? Center(child: Text(l10n.comingSoon))
                        : SafeArea(
                            child: Column(
                              children: [
                                if (widget.params.mode == PuzzleMode.daily)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      AppSpacing.sm,
                                      AppSpacing.md,
                                      0,
                                    ),
                                    child: Text(
                                      DailyPuzzleSchedule.scheduleNote(
                                        l10n,
                                        Localizations.localeOf(context).toString(),
                                      ),
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colors.textSecondary,
                                          ),
                                    ),
                                  ),
                                if (footballFact != null && footballFact.isValid)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.md,
                                      AppSpacing.sm,
                                      AppSpacing.md,
                                      0,
                                    ),
                                    child: FootballFactBanner(fact: footballFact),
                                  ),
                                PuzzleTimer(startedAt: game.startedAt ?? DateTime.now()),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.sm,
                                      ),
                                      child: PuzzleGrid(
                                        puzzle: game.puzzle!,
                                        cells: game.cells,
                                        selectedRow: game.selectedRow,
                                        selectedCol: game.selectedCol,
                                        onCellTap: _onCellTap,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_isTrainingMode)
                                  _PracticeBottomBar(
                                    score: game.totalScore,
                                    scoreLabel: l10n.score,
                                    finishLabel: l10n.practiceFinishTraining,
                                    onFinish: _confirmFinishPractice,
                                  )
                                else if (game.totalScore > 0)
                                  Padding(
                                    padding: const EdgeInsets.all(AppSpacing.md),
                                    child: Text(
                                      '${l10n.score}: ${game.totalScore.toStringAsFixed(0)}',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: colors.accent,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
      ),
    );
  }

  String _title(AppLocalizations l10n) => switch (widget.params.mode) {
        PuzzleMode.daily => l10n.dailyChallenge,
        PuzzleMode.practice => l10n.practice,
        PuzzleMode.timeline => l10n.timelineMode,
        PuzzleMode.challenge => l10n.friendChallenge,
      };

  Widget _buildPracticeAdGate(
    BuildContext context,
    AppLocalizations l10n,
    CrossBallColors colors,
  ) {
    final session = ref.watch(practiceSessionProvider);
    final limit = session.dailyLimit;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: CrossBallGlassPanel(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline_rounded, size: 48, color: colors.lime),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.practiceAdRequiredTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.practiceDailyProgress(session.completedToday, limit),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: colors.lime),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.practiceAdGateHint, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => _watchAdAndStartPractice(),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: Text(l10n.practiceWatchAdForNewSession),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.practicePremiumSkipAds,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.push(AppRoutes.premium),
                child: Text(l10n.upgradePremium),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: Text(l10n.backToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeResult(BuildContext context, PuzzleGameState game) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(practiceSessionProvider);
    final remaining = session.remaining;
    final limit = session.dailyLimit;
    final canPlayMore = remaining > 0;
    final needsAd = session.needsRewardedAdForNextSession && canPlayMore;

    return PuzzleResultScreen(
      title: l10n.practiceResultTitle,
      score: game.totalScore,
      mistakes: game.mistakes,
      hintsUsed: game.hintsUsed,
      subtitle: game.finishedEarly
          ? l10n.practiceResultEarlyDesc
          : l10n.practiceCompleteDesc,
      remainingSessions: remaining,
      sessionsUsed: session.completedToday,
      sessionsLimit: limit,
      showShare: false,
      newSessionLabel: needsAd ? l10n.practiceWatchAdForNewSession : l10n.practiceNewSession,
      newSessionRequiresAd: needsAd,
      onNewSession: canPlayMore ? () => _startNextPracticeSession(needsAd: needsAd) : null,
      onHome: () => context.go(AppRoutes.home),
      onShareChallenge: () {},
    );
  }

  Future<void> _confirmFinishPractice() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.practiceFinishConfirmTitle),
        content: Text(l10n.practiceFinishConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.practiceFinishTraining),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(puzzleGameProvider(widget.params).notifier).finishPractice();
  }

  Future<void> _startNextPracticeSession({required bool needsAd}) async {
    if (needsAd) {
      await _watchAdAndStartPractice();
      return;
    }
    await ref.read(puzzleGameProvider(widget.params).notifier).startNewPracticeSession();
  }

  Future<void> _watchAdAndStartPractice() async {
    final rewarded = await ref.read(adsServiceProvider).showRewarded();
    if (!rewarded || !mounted) return;

    ref.read(analyticsProvider).track('ad_impression', properties: {
      'placement': 'rewarded_practice_unlock',
    });
    final profile = await ref.read(userProfileProvider.future);
    await ref.read(practiceSessionProvider.notifier).grantAdUnlock(profile.userUuid);
    await ref.read(puzzleGameProvider(widget.params).notifier).startNewPracticeSession();
  }

  Future<void> _createChallengeFromResult() async {
    context.push(AppRoutes.challenge);
  }

  Future<void> _createRematch(BuildContext context) async {
    final last = ref.read(lastCompletedSessionProvider);
    if (last == null) return;

    final profile = await ref.read(userProfileProvider.future);
    final challenge = await ref.read(challengeRepositoryProvider).createChallenge(
          puzzleId: last.puzzleId,
          sessionId: last.sessionId,
          creatorScore: last.score,
          userUuid: profile.userUuid,
        );

    if (!context.mounted) return;
    await SharePlus.instance.share(ShareParams(text: challenge.shareUrl));
    context.go(AppRoutes.challenge);
  }

  Future<void> _onCellTap(int row, int col) async {
    final notifier = ref.read(puzzleGameProvider(widget.params).notifier);
    notifier.selectCell(row, col);

    final game = ref.read(puzzleGameProvider(widget.params));
    final puzzle = game.puzzle;
    if (puzzle == null) return;

    final cellKey = '${row}_$col';
    final player = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PlayerSearchModal(
        params: widget.params,
        rowClub: puzzle.rowClubAt(row),
        colClub: puzzle.colClubAt(col),
        revealedHints: game.hintsRevealed[cellKey] ?? const [],
        isPremium: ref.read(isPremiumProvider),
      ),
    );

    if (player == null || !mounted) {
      notifier.clearSelection();
      return;
    }

    final result = await notifier.submitAnswer(player);
    if (result != null && mounted) {
      if (result.correct &&
          (result.rarityTier == 'mythic' ||
              RarityTier.fromUsagePercentage(result.usagePercentage) == RarityTier.mythic)) {
        await showMythicCelebration(context);
      }
      if (!mounted) return;

      if (result.correct && widget.params.mode == PuzzleMode.timeline) {
        final timeline = await ref.read(socialRepositoryProvider).getCareerTimeline(
              playerId: player.id,
              rowClubId: puzzle.rowClubAt(row).id,
              colClubId: puzzle.colClubAt(col).id,
            );
        if (mounted && timeline.entries.isNotEmpty) {
          await showCareerTimelineSheet(context, timeline: timeline);
        }
      }

      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => AnswerResultSheet(result: result),
      );
    }
  }
}

class ChallengeResultScreen extends StatelessWidget {
  const ChallengeResultScreen({
    super.key,
    required this.result,
    required this.yourScore,
    required this.onHome,
    this.onRematch,
  });

  final ChallengeResult result;
  final double yourScore;
  final VoidCallback onHome;
  final VoidCallback? onRematch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final title = result.isTie
        ? l10n.challengeTie
        : result.youWon
            ? l10n.challengeYouWon
            : l10n.challengeYouLost;

    return Scaffold(
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  result.youWon ? Icons.emoji_events : Icons.sports_soccer,
                  size: 64,
                  color: colors.accent,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.lg),
                _ScoreCompareRow(label: l10n.challengeCreator, score: result.creatorScore),
                _ScoreCompareRow(label: l10n.challengeYou, score: yourScore),
                const SizedBox(height: AppSpacing.xl),
                if (onRematch != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onRematch,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(l10n.challengeRematch),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(onPressed: onHome, child: Text(l10n.backToHome)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreCompareRow extends StatelessWidget {
  const _ScoreCompareRow({required this.label, required this.score});

  final String label;
  final double score;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(score.toStringAsFixed(0), style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}

class _PracticeBottomBar extends StatelessWidget {
  const _PracticeBottomBar({
    required this.score,
    required this.scoreLabel,
    required this.finishLabel,
    required this.onFinish,
  });

  final double score;
  final String scoreLabel;
  final String finishLabel;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final colors = context.cb;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (score > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                '$scoreLabel: ${score.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onFinish,
              icon: Icon(Icons.flag_rounded, color: colors.lime),
              label: Text(finishLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}
