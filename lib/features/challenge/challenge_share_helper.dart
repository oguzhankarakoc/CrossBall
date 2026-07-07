import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/providers/app_providers.dart';
import '../../shared/providers/session_providers.dart';
import '../auth/presentation/auth_providers.dart';
import 'domain/challenge.dart';

/// Creates a friend challenge from the last completed session and opens the share sheet.
Future<Challenge?> createAndShareChallenge({
  required WidgetRef ref,
  required BuildContext context,
  required String needSessionMessage,
  required String shareFailedMessage,
}) async {
  final lastSession = ref.read(lastCompletedSessionProvider);
  if (lastSession == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(needSessionMessage)),
    );
    return null;
  }

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
      'shared': true,
    });
    await SharePlus.instance.share(ShareParams(text: challenge.shareUrl));
    return challenge;
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(shareFailedMessage)),
      );
    }
    return null;
  }
}
