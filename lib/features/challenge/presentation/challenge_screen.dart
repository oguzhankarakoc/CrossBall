import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/session_providers.dart';
import '../../../shared/widgets/crossball_ui.dart';
import '../challenge_share_helper.dart';

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

  Future<void> _createAndShareChallenge() async {
    setState(() => _loading = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final challenge = await createAndShareChallenge(
        ref: ref,
        context: context,
        needSessionMessage: l10n.challengeNeedSession,
        shareFailedMessage: l10n.challengeShareFailed,
      );
      if (challenge != null && mounted) {
        setState(() => _createdLink = challenge.shareUrl);
      }
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
                CrossBallGlassPanel(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l10n.createChallenge, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.sm),
                      Text(l10n.createChallengeDesc, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        hasSession ? l10n.challengeFromAnySession : l10n.challengeNeedSession,
                        style: TextStyle(
                          color: hasSession ? colors.textSecondary : colors.accent,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: hasSession && !_loading ? _createAndShareChallenge : null,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.createAndShareChallenge),
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
                          child: Text(
                            _createdLink!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: context.cb.textPrimary,
                                ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _createdLink!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.copied)),
                            );
                          },
                          child: Text(l10n.copyLink),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                CrossBallGlassPanel(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
