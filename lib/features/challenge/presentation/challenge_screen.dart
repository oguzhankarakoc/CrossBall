import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/routing/app_routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/providers/app_providers.dart';
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
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createChallenge() async {
    setState(() => _loading = true);
    try {
      final profile = await ref.read(userProfileProvider.future);
      final puzzle = await ref.read(dailyPuzzleProvider.future);
      final challenge = await ref.read(challengeRepositoryProvider).createChallenge(
            puzzleId: puzzle.id,
            sessionId: 'demo-session',
            creatorScore: 750,
            userUuid: profile.userUuid,
          );
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

    return Scaffold(
      appBar: CrossBallAppBar(title: l10n.friendChallenge),
      body: PitchBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.challengeDesc,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.createChallenge, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(l10n.createChallengeDesc, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 16),
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
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.cardBorder),
                            ),
                            child: Text(_createdLink!, style: const TextStyle(fontFamily: 'monospace')),
                          ),
                          const SizedBox(height: 8),
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
                              const SizedBox(width: 8),
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
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l10n.joinChallenge, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: l10n.challengeCodeHint,
                            filled: true,
                            fillColor: colors.surfaceElevated,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _joinChallenge,
                          child: Text(l10n.joinChallenge),
                        ),
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
