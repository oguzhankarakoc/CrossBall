import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Daily puzzle calendar day and refresh window (aligned with GitHub Actions cron).
abstract final class DailyPuzzleSchedule {
  /// UTC hour when the data-sync job runs and a new global puzzle is ensured.
  static const utcResetHour = 0;

  /// Maximum time we treat the midnight refresh window as active.
  /// GitHub Actions cron is 00:00 UTC but runners + API sync often finish ~3h later.
  static const rolloutWindow = Duration(hours: 3);

  /// Start of the next UTC calendar day (= next puzzle refresh instant).
  static DateTime nextResetUtc([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day).add(const Duration(days: 1));
  }

  /// UTC date string (YYYY-MM-DD) for today's global daily puzzle.
  static String todayPuzzleDateUtc([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day).toIso8601String().split('T').first;
  }

  static Duration timeUntilNextReset([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    return nextResetUtc(utc).difference(utc);
  }

  static String formatCountdown(Duration duration) {
    if (duration.isNegative) return '0m';
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (duration.inMinutes >= 1) return '${duration.inMinutes}m';
    return '<1m';
  }

  static String formatElapsed(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final duration = Duration(seconds: totalSeconds);
    if (duration.inHours >= 1) {
      final minutes = duration.inMinutes % 60;
      return '${duration.inHours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (duration.inMinutes >= 1) return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    return '${duration.inSeconds}s';
  }

  static bool isWithinRolloutWindow([DateTime? now]) {
    final utc = (now ?? DateTime.now()).toUtc();
    final midnight = DateTime.utc(utc.year, utc.month, utc.day);
    final elapsed = utc.difference(midnight);
    return !elapsed.isNegative && elapsed < rolloutWindow;
  }

  /// Local wall-clock time when the next UTC midnight reset occurs.
  static String formatLocalResetTime(String localeName, [DateTime? now]) {
    final local = nextResetUtc(now).toLocal();
    return DateFormat.jm(localeName).format(local);
  }

  static String scheduleNote(AppLocalizations l10n, String localeName, [DateTime? now]) {
    return l10n.dailyRefreshSchedule(
      formatLocalResetTime(localeName, now),
      formatCountdown(timeUntilNextReset(now)),
    );
  }
}
