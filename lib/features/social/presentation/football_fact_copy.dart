import '../../../l10n/app_localizations.dart';

/// Localized rotating football tips when remote facts are unavailable.
abstract final class FootballFactCopy {
  static String pickTip(AppLocalizations l10n, {String context = 'intersection'}) {
    final tips = context == 'timeline'
        ? [
            l10n.footballFactTimeline1,
            l10n.footballFactTimeline2,
            l10n.footballFactTimeline3,
          ]
        : [
            l10n.footballFactTip1,
            l10n.footballFactTip2,
            l10n.footballFactTip3,
            l10n.footballFactTip4,
            l10n.footballFactTip5,
          ];
    final index = DateTime.now().toUtc().day % tips.length;
    return tips[index];
  }
}
