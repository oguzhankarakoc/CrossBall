import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Brief full-screen burst when the player finds a mythic answer.
Future<void> showMythicCelebration(BuildContext context) async {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  if (!reduceMotion) {
    HapticFeedback.heavyImpact();
  }
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'mythic',
    barrierColor: Colors.black54,
    transitionDuration: reduceMotion ? Duration.zero : const Duration(milliseconds: 350),
    pageBuilder: (ctx, _, __) => const _MythicCelebrationDialog(),
    transitionBuilder: (ctx, anim, _, child) {
      if (reduceMotion) return child;
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

class _MythicCelebrationDialog extends StatelessWidget {
  const _MythicCelebrationDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: l10n.mythicCelebration,
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.xl),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFE9C349)],
              ),
              borderRadius: AppRadius.xxlBorder,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withValues(alpha: 0.45),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 64, color: Colors.white),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.mythicCelebration,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.mythicCelebrationBody,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
