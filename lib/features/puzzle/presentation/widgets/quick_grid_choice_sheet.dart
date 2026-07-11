import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/game_constants.dart';
import '../../../../core/network/api_http_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/crossball_ui.dart';
import '../../../../shared/widgets/player_avatar.dart';
import '../../../ads/ads_service.dart';
import '../../../search/domain/search.dart';
import '../../domain/puzzle.dart';

/// Multiple-choice sheet for Quick Grid — 5 players, optional rewarded eliminate.
Future<Player?> showQuickGridChoiceSheet(
  BuildContext context, {
  required Club rowClub,
  required Club colClub,
  required bool isPremium,
}) {
  return showModalBottomSheet<Player>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuickGridChoiceSheet(
      rowClub: rowClub,
      colClub: colClub,
      isPremium: isPremium,
    ),
  );
}

class _QuickGridChoiceSheet extends ConsumerStatefulWidget {
  const _QuickGridChoiceSheet({
    required this.rowClub,
    required this.colClub,
    required this.isPremium,
  });

  final Club rowClub;
  final Club colClub;
  final bool isPremium;

  @override
  ConsumerState<_QuickGridChoiceSheet> createState() => _QuickGridChoiceSheetState();
}

class _QuickGridChoiceSheetState extends ConsumerState<_QuickGridChoiceSheet> {
  final _http = ApiHttpClient();
  List<Player> _choices = const [];
  bool _loading = true;
  bool _eliminating = false;
  bool _eliminatedOnce = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChoices();
  }

  Future<void> _loadChoices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final json = await _http.getJson(
        'quick-grid-choices',
        query: {
          'row_club_id': widget.rowClub.id,
          'col_club_id': widget.colClub.id,
          'limit': '${GameConstants.quickGridChoiceCount}',
        },
        throwOnError: false,
      );
      if (!mounted) return;
      if (json['ok'] != true) {
        setState(() {
          _loading = false;
          _error = 'choices_unavailable';
        });
        return;
      }
      final raw = (json['choices'] as List<dynamic>? ?? [])
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _choices = raw;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'choices_unavailable';
      });
    }
  }

  Future<void> _eliminateWrong() async {
    if (_eliminatedOnce || _choices.length < 3 || _eliminating) return;

    setState(() => _eliminating = true);
    try {
      if (!widget.isPremium) {
        final watched = await ref.read(adsServiceProvider).showRewarded();
        if (!watched) {
          if (mounted) setState(() => _eliminating = false);
          return;
        }
      }

      final json = await _http.getJson(
        'quick-grid-choices',
        query: {
          'action': 'eliminate',
          'row_club_id': widget.rowClub.id,
          'col_club_id': widget.colClub.id,
          'choice_ids': _choices.map((c) => c.id).join(','),
        },
        throwOnError: false,
      );
      if (!mounted) return;
      final removeId = json['remove_player_id'] as String?;
      if (json['ok'] == true && removeId != null) {
        setState(() {
          _choices = _choices.where((c) => c.id != removeId).toList();
          _eliminatedOnce = true;
          _eliminating = false;
        });
      } else {
        setState(() => _eliminating = false);
      }
    } catch (_) {
      if (mounted) setState(() => _eliminating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
            child: CrossBallGlassPanel(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xxl,
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.textSecondary.withValues(alpha: 0.35),
                        borderRadius: AppRadius.pillBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.quickGridPickTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${widget.rowClub.shortLabel} × ${widget.colClub.shortLabel}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.lime,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Column(
                      children: [
                        Text(
                          l10n.quickGridChoicesError,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: _loadChoices,
                          child: Text(l10n.retry),
                        ),
                      ],
                    )
                  else ...[
                    ..._choices.map(
                      (player) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Material(
                          color: colors.surfaceElevated.withValues(alpha: 0.9),
                          borderRadius: AppRadius.xlBorder,
                          child: InkWell(
                            borderRadius: AppRadius.xlBorder,
                            onTap: () => Navigator.pop(context, player),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm + 2,
                              ),
                              child: Row(
                                children: [
                                  PlayerAvatar(
                                    seed: player.id,
                                    size: 44,
                                    nationalityCode: player.nationalityCode,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, color: colors.lime),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!_eliminatedOnce && _choices.length >= 3) ...[
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _eliminating ? null : _eliminateWrong,
                        icon: _eliminating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                widget.isPremium
                                    ? Icons.filter_alt_off_rounded
                                    : Icons.ondemand_video_rounded,
                              ),
                        label: Text(
                          widget.isPremium
                              ? l10n.quickGridEliminateFree
                              : l10n.quickGridEliminateAd,
                        ),
                      ),
                    ],
                  ],
                  if (!AppConfig.isAdMobEnabled && !widget.isPremium)
                    const SizedBox.shrink(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
