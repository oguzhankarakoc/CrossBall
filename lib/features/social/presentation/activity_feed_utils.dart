import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/social.dart';

String formatActivityEvent(AppLocalizations l10n, ActivityEvent event) {
  final score = (event.payload['final_score'] as num?)?.toDouble();
  final scoreText = score != null ? score.toStringAsFixed(0) : '';
  final name = event.displayLabel;
  return switch (event.eventType) {
    'daily_completed' => l10n.activityDailyCompleted(name, scoreText),
    'challenge_completed' => l10n.activityChallengeCompleted(name),
    'timeline_completed' => l10n.activityTimelineCompleted(name, scoreText),
    _ => l10n.activityGeneric(
        name,
        event.eventType.replaceAll('_', ' '),
      ),
  };
}

String formatActivityAction(AppLocalizations l10n, ActivityEvent event) {
  final score = (event.payload['final_score'] as num?)?.toDouble();
  final scoreText = score != null ? score.toStringAsFixed(0) : '';
  return switch (event.eventType) {
    'daily_completed' => l10n.activityDailyCompletedAction(scoreText),
    'challenge_completed' => l10n.activityChallengeCompletedAction,
    'timeline_completed' => l10n.activityTimelineCompletedAction(scoreText),
    _ => l10n.activityGenericAction(event.eventType.replaceAll('_', ' ')),
  };
}

IconData activityEventIcon(String eventType) {
  return switch (eventType) {
    'daily_completed' => Icons.calendar_today_rounded,
    'challenge_completed' => Icons.people_rounded,
    'timeline_completed' => Icons.timeline_rounded,
    _ => Icons.sports_soccer_rounded,
  };
}
