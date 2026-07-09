import '../../l10n/app_localizations.dart';

String formatRelativeTime(AppLocalizations l10n, DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inHours < 1) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.timeHoursAgo(diff.inHours);
  return l10n.timeDaysAgo(diff.inDays);
}
