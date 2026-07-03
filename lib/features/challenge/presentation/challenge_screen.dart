import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/providers/session_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../../auth/presentation/auth_providers.dart';

class ChallengeScreen extends ConsumerStatefulWidget {
  const ChallengeScreen({super.key, this.challengeId});

  final String? challengeId;

  @override
  ConsumerState<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends ConsumerState<ChallengeScreen> {
  final _codeController = TextEditingController();
  String? _createdLink;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.challengeId != null) {
      _codeController.text = widget.challengeId!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _joinChallenge());
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    final lastSession = ref.read(lastCompletedSessionProvider);
    if (lastSession == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.createChallengeDesc)),
      );
      context.push('${AppRoutes.puzzle}?mode=daily');
      return;
    }

    setState(() => _loading = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final challenge = await ref.read(challengeRepositoryProvider).createChallenge(
            puzzleId: lastSession.puzzleId,
            sessionId: lastSession.sessionId,
            creatorScore: lastSession.score,
            userUuid: profile.userUuid,
          );
      ref.read(analyticsProvider).track('challenge_created', properties: {
        'challenge_id': challenge.id,
      });
      setState(() => _createdLink = challenge.shareUrl);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinChallenge() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    if (!mounted) return;
    context.push('${AppRoutes.puzzle}?mode=challenge&id=$code');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.cb;
    final hasSession = ref.watch(lastCompletedSessionProvider) != null;

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.friendChallenge),
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.challengeDesc, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.createChallenge, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(l10n.createChallengeDesc, style: Theme.of(context).textTheme.bodySmall),
                        if (!hasSession) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.completeDailyFirst,
                            style: TextStyle(color: colors.accent, fontSize: 12),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(
                          onPressed: _loading ? null : _createChallenge,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(l10n.createChallenge),
                        ),
                        if (_createdLink != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: AppRadius.smBorder,
                              border: Border.all(color: colors.cardBorder),
                            ),
                            child: Text(_createdLink!, style: const TextStyle(fontFamily: 'monospace')),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _createdLink!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(l10n.copied)),
                                    );
                                  },
                                  child: Text(l10n.copyLink),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => SharePlus.instance.share(
                                    ShareParams(text: _createdLink!),
                                  ),
                                  child: Text(l10n.share),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.joinChallenge, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: l10n.challengeCodeHint,
                            filled: true,
                            fillColor: colors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        FilledButton(onPressed: _joinChallenge, child: Text(l10n.joinChallenge)),
                      ],
                    ),
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
