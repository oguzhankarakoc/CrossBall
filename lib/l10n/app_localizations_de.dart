// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'CrossBall';

  @override
  String get tagline => 'Vereine verbinden. Beweise dein Fußball-Wissen.';

  @override
  String get homeTitle => 'CrossBall';

  @override
  String get dailyChallenge => 'Tägliche Herausforderung';

  @override
  String get dailyChallengeDesc => 'Ein Rätsel pro Tag. Baue deine Serie auf.';

  @override
  String dailyRefreshSchedule(String localTime, String countdown) {
    return 'Aktualisierung um $localTime Ortszeit (00:00 UTC) · Nächstes in $countdown';
  }

  @override
  String get dailyPuzzleRefreshTitle => 'Das heutige Rätsel wird vorbereitet';

  @override
  String get dailyPuzzleRefreshBody =>
      'Jeden Tag um Mitternacht UTC aktualisieren wir die Vereine und erstellen ein neues globales Gitter. Das Rätsel von gestern ist geschlossen, bis das neue bereit ist.';

  @override
  String dailyPuzzleRefreshElapsed(String elapsed) {
    return 'Vorbereitung seit $elapsed';
  }

  @override
  String get dailyPuzzleRefreshWindowHint =>
      'Das dauert meist nur wenige Minuten. Danke für deine Geduld.';

  @override
  String dailyPuzzleRefreshAutoHint(int seconds) {
    return 'Wir prüfen automatisch erneut in $seconds s.';
  }

  @override
  String get dailyPuzzleRefreshCheckAgain => 'Erneut prüfen';

  @override
  String get dailyPuzzleRefreshRetry => 'Nochmal versuchen';

  @override
  String get dailyPuzzleRefreshFailedTitle =>
      'Das heutige Rätsel ist noch nicht bereit';

  @override
  String get dailyPuzzleRefreshFailedBody =>
      'Nach dem Refresh konnte das heutige Rätsel nicht veröffentlicht werden. Versuche es erneut — im Hintergrund starten wir einen sicheren Fallback.';

  @override
  String get dailyPuzzleRefreshHomeSubtitle =>
      'Neues Rätsel unterwegs — Refresh um 00:00 UTC läuft.';

  @override
  String get dailyPuzzleRefreshHomeHint => 'Heutiges Rätsel wird vorbereitet…';

  @override
  String get dailyPuzzleRefreshBadge => 'Aktualisierung';

  @override
  String get dailyAlreadyCompletedTitle => 'Tagesrätsel abgeschlossen';

  @override
  String get dailyAlreadyCompletedBody =>
      'Du hast das heutige Tagesrätsel bereits gelöst. Das nächste Gitter kommt nach der nächsten Aktualisierung.';

  @override
  String dailyAlreadyCompletedNextPuzzle(String localTime, String countdown) {
    return 'Nächstes Rätsel gegen $localTime · noch $countdown';
  }

  @override
  String get dailyAlreadyCompletedBadge => 'Abgeschlossen';

  @override
  String get dailyAlreadyCompletedHomeSubtitle =>
      'Du hast das heutige Rätsel geschafft. Morgen wartet ein neues Gitter.';

  @override
  String get dailyAlreadyCompletedViewSummary => 'Zusammenfassung';

  @override
  String get friendChallenge => 'Freundes-Herausforderung';

  @override
  String get friendChallengeDesc => 'Link teilen und async wetteifern.';

  @override
  String get practice => 'Übung';

  @override
  String get practiceDesc =>
      '5 Trainingseinheiten pro Tag. Werbung für die nächste Runde.';

  @override
  String get stats => 'Statistiken';

  @override
  String get activeEvents => 'Aktive Events';

  @override
  String get eventLockedBadge => 'Demnächst';

  @override
  String get eventLockedMessage =>
      'Themen-Gitter für dieses Event sind noch nicht verfügbar.';

  @override
  String get communityGoals => 'Community-Ziele';

  @override
  String get maintenanceNotice => 'Wartung';

  @override
  String get maintenanceNoticeBody =>
      'Einige Dienste können eingeschränkt sein. Rätsel spielen geht weiter.';

  @override
  String get settings => 'Einstellungen';

  @override
  String get premium => 'Premium';

  @override
  String get onboardingSkip => 'Überspringen';

  @override
  String get onboardingNext => 'Weiter';

  @override
  String get onboardingStart => 'Los geht\'s';

  @override
  String get onboarding1Title => 'Wähle eine Zelle';

  @override
  String get onboarding1Body =>
      'Tippe auf eine leere Zelle im 3×3-Raster, um die Suche zu öffnen.';

  @override
  String get onboarding2Title => 'Verbinde beide Vereine';

  @override
  String get onboarding2Body =>
      'Die Antwort muss für den Zeilen- und den Spaltenverein gespielt haben.';

  @override
  String get onboarding3Title => 'Seltene Tipps bringen mehr Punkte';

  @override
  String get onboarding3Body =>
      'Obskure Namen schlagen offensichtliche — halte deine Serie am Leben.';

  @override
  String get firstPuzzleCoachTitle => 'Kurz erklärt';

  @override
  String get firstPuzzleCoachSubtitle =>
      'Du bist im Tagesrätsel. So funktioniert eine Zelle.';

  @override
  String get firstPuzzleCoachStep1Title => 'Zelle antippen';

  @override
  String get firstPuzzleCoachStep1Body =>
      'Jedes Feld liegt zwischen einem Zeilen- und einem Spaltenverein.';

  @override
  String get firstPuzzleCoachStep2Title => 'Die Verbindung finden';

  @override
  String get firstPuzzleCoachStep2Body =>
      'Suche einen Spieler, der für beide Vereine aufgelaufen ist.';

  @override
  String get firstPuzzleCoachStep3Title => 'Seltenheit jagen';

  @override
  String get firstPuzzleCoachStep3Body =>
      'Ungewöhnlichere Antworten bringen mehr Punkte. Schließe das Raster für deine Serie.';

  @override
  String get firstPuzzleCoachCta => 'Verstanden — los';

  @override
  String get comingSoon => 'Laden...';

  @override
  String get puzzleLoadFailed =>
      'Das Tagesrätsel konnte nicht geladen werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get practiceLoadFailed =>
      'Das Trainingsrätsel konnte nicht geladen werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get gamesPlayed => 'Gespielte Spiele';

  @override
  String get level => 'Level';

  @override
  String get experiencePoints => 'XP';

  @override
  String get homeWeeklyScoreLabel => 'Diese Woche';

  @override
  String get competitiveRating => 'Rating';

  @override
  String get league => 'Liga';

  @override
  String get currentStreak => 'Aktuelle Serie';

  @override
  String get bestStreak => 'Beste Serie';

  @override
  String get totalScore => 'Gesamtpunktzahl';

  @override
  String get rarityBreakdown => 'Seltenheitsverteilung';

  @override
  String get rarityBreakdownEmpty =>
      'Deine Seltenheitsverteilung erscheint nach kompetitiven Rätseln (Daily & Challenges).';

  @override
  String get rarityBreakdownHint =>
      'Obskure Tipps heben seltene Stufen — so steigst du auf.';

  @override
  String get statsCareerTitle => 'Karriere';

  @override
  String get statsActivityTitle => 'Aktivität';

  @override
  String get statsProgressUnavailable =>
      'Level konnte nicht geladen werden. Zum Aktualisieren ziehen.';

  @override
  String get createChallenge => 'Herausforderung erstellen';

  @override
  String get createAndShareChallenge => 'Herausforderung erstellen & teilen';

  @override
  String get createChallengeDesc =>
      'Löse zuerst das heutige Rätsel, dann teile deinen Score.';

  @override
  String get joinChallenge => 'Herausforderung beitreten';

  @override
  String get challengeDesc =>
      'Fordere Freunde async heraus. Gleiches Rätsel, Scores vergleichen.';

  @override
  String get challengeCodeHint => 'Herausforderungscode eingeben';

  @override
  String get copyLink => 'Link kopieren';

  @override
  String get share => 'Teilen';

  @override
  String get copied => 'Link kopiert!';

  @override
  String get language => 'Sprache';

  @override
  String get premiumTitle => 'CrossBall Premium';

  @override
  String get premiumDesc =>
      '10 werbefreie Trainingseinheiten pro Tag, erweiterte Stats, keine Werbung.';

  @override
  String get upgradePremium => 'Premium upgraden';

  @override
  String get searchPlayer => 'Spieler suchen...';

  @override
  String get recentPicks => 'Letzte Tipps';

  @override
  String get popularPicks => 'Beliebte Tipps';

  @override
  String get suggestedForCell => 'Für dieses Feld vorgeschlagen';

  @override
  String get noPlayersFound => 'Keine Spieler gefunden';

  @override
  String get puzzleComplete => 'Rätsel abgeschlossen!';

  @override
  String get backToHome => 'Zur Startseite';

  @override
  String get mistakes => 'Fehler';

  @override
  String get hintsUsed => 'Hinweise verwendet';

  @override
  String get score => 'Punkte';

  @override
  String get correct => 'Richtig';

  @override
  String get incorrect => 'Falsch';

  @override
  String get tier => 'Stufe';

  @override
  String usedBy(String percent) {
    return 'Von $percent% gewählt';
  }

  @override
  String get continueButton => 'Weiter';

  @override
  String get appearance => 'Erscheinungsbild';

  @override
  String get themeSystem => 'Systemstandard';

  @override
  String get themeDark => 'Dark Stadium';

  @override
  String get themeLight => 'Light Pitch';

  @override
  String get themeSystemDesc => 'Geräte-Erscheinungsbild übernehmen';

  @override
  String get themeDarkDesc =>
      'Schwarzer Platz, Stadionlichter, Rasengrün-Akzente';

  @override
  String get themeLightDesc => 'Sanftes Rasengrün, premium Gold-Akzente';

  @override
  String get localeSystem => 'Systemstandard';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeTurkish => 'Türkçe';

  @override
  String get localeGerman => 'Deutsch';

  @override
  String get hintNationality => 'Werbung für Nationalitätshinweis ansehen';

  @override
  String get hintPosition => 'Werbung für Positionshinweis ansehen';

  @override
  String get hintFirstLetter => 'Werbung für Anfangsbuchstaben ansehen';

  @override
  String get hintCareerLeague => 'Werbung für Karriere-Liga ansehen';

  @override
  String get hintRetiredStatus => 'Werbung für Aktiv/Retired ansehen';

  @override
  String get hintCareerClub => 'Werbung für Vereinshinweis ansehen';

  @override
  String get hintNationalityPremium => 'Nationalitätshinweis anzeigen';

  @override
  String get hintPositionPremium => 'Positionshinweis anzeigen';

  @override
  String get hintFirstLetterPremium => 'Ersten Buchstaben anzeigen';

  @override
  String get hintCareerLeaguePremium => 'Karriere-Liga anzeigen';

  @override
  String get hintRetiredStatusPremium => 'Aktiv/Retired anzeigen';

  @override
  String get hintCareerClubPremium => 'Vereinshinweis anzeigen';

  @override
  String get hintChipNationality => 'Nationalität';

  @override
  String get hintChipPosition => 'Position';

  @override
  String get hintChipFirstLetter => 'Anfangsbuchstabe';

  @override
  String get hintChipStatus => 'Status';

  @override
  String get hintChipClub => 'Verein';

  @override
  String get hintValueUnknown => 'Unbekannt';

  @override
  String get hintStatusActive => 'Aktiv';

  @override
  String get hintStatusRetired => 'Im Ruhestand';

  @override
  String get hintLimitReached =>
      'Alle Hinweise für dieses Feld sind bereits aufgedeckt.';

  @override
  String get hintUnavailable =>
      'Hinweis gerade nicht verfügbar. Bitte erneut versuchen.';

  @override
  String get hintPossibleAnswerLabel => 'Mögliche Antwort';

  @override
  String get hintPossibleAnswerNote =>
      'Hinweise beschreiben eine mögliche Antwort — andere korrekte Spieler zählen weiterhin.';

  @override
  String get searchCompetitiveEmpty =>
      'Spielername eingeben. Hilfe über den Hinweis-Button oben.';

  @override
  String get practiceLimitReached =>
      'Tägliches Trainingslimit erreicht. Morgen wieder oder Premium upgraden.';

  @override
  String get practiceAdRequiredTitle => 'Nächstes Training';

  @override
  String get practiceAdRequired =>
      'Schau eine kurze Werbung, um die nächste Trainingseinheit zu starten.';

  @override
  String get practiceWatchAdForNewSession => 'Werbung ansehen — neues Training';

  @override
  String get practiceNewSession => 'Neues Training';

  @override
  String get practiceCompleteDesc =>
      'Bei jeder Einheit neue Vereins-Kombinationen.';

  @override
  String get practiceFinishTraining => 'Training beenden';

  @override
  String get practiceFinishConfirmTitle => 'Training beenden?';

  @override
  String get practiceFinishConfirmBody =>
      'Diese Einheit endet und verbraucht 1 deiner täglichen Trainingseinheiten.';

  @override
  String get practiceResultTitle => 'Training abgeschlossen';

  @override
  String get practiceResultEarlyDesc =>
      'Früh beendet — Punkte und Fortschritt wurden gespeichert.';

  @override
  String practiceSessionProgress(int current, int limit) {
    return 'Training $current/$limit';
  }

  @override
  String practiceDailyProgress(int used, int limit) {
    return 'Heute $used/$limit Trainingseinheiten genutzt';
  }

  @override
  String get practiceAdGateHint =>
      'Im Gratis-Plan schaust du vor jeder neuen Einheit eine kurze Werbung.';

  @override
  String get adUnavailable =>
      'Werbung gerade nicht verfügbar. Bitte gleich nochmal versuchen.';

  @override
  String get practicePremiumSkipAds =>
      'Premium: bis zu 10 Einheiten pro Tag, keine Werbung zwischen Runden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String practiceSessionsRemaining(int count) {
    return 'Noch $count Trainingseinheiten heute';
  }

  @override
  String get premiumFeatureGrid => '4×4 Premium-Gitter';

  @override
  String get premiumFeaturePractice =>
      '10 werbefreie Trainingseinheiten pro Tag';

  @override
  String get premiumFeatureStats => 'Erweiterte Statistiken';

  @override
  String get premiumFeatureThemes => 'Exklusive Themes';

  @override
  String get premiumFeatureNoAds => 'Keine Werbung';

  @override
  String get premiumActivated => 'Premium aktiviert!';

  @override
  String get premiumActive => 'Premium aktiv';

  @override
  String get premiumPurchaseFailed =>
      'Premium konnte nicht aktiviert werden. Bitte erneut versuchen.';

  @override
  String get premiumVerificationFailed =>
      'Kauf konnte nicht verifiziert werden. Käufe wiederherstellen oder Support kontaktieren.';

  @override
  String get premiumPurchaseUnavailable =>
      'Premium ist im Store noch nicht verfügbar. App-Store-Einrichtung prüfen.';

  @override
  String get premiumDevNotConfigured =>
      'Dev-Premium ist auf dem Server nicht aktiv. IAP_SKIP_VERIFY=true in Supabase setzen oder IAP_ENABLED=true mit StoreKit.';

  @override
  String get premiumPurchasePending =>
      'Ausstehender App-Store-Kauf wird abgeschlossen. Kurz warten oder Käufe wiederherstellen.';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get completeDailyFirst =>
      'Schließe zuerst das heutige Tagesrätsel ab, um eine Herausforderung zu erstellen.';

  @override
  String get challengeYouWon => 'Du hast gewonnen!';

  @override
  String get challengeYouLost => 'Du hast diese Runde verloren.';

  @override
  String get challengeTie => 'Unentschieden!';

  @override
  String get challengeCreator => 'Ersteller';

  @override
  String get challengeYou => 'Du';

  @override
  String get playerNickname => 'Spitzname';

  @override
  String get playerNicknameDesc =>
      'Optionaler Name für Herausforderungen und künftige Bestenlisten.';

  @override
  String get playerNicknameHint => '3–20 Zeichen';

  @override
  String get playerNicknameSaved => 'Spitzname gespeichert';

  @override
  String get playerNicknameTaken => 'Dieser Spitzname ist bereits vergeben';

  @override
  String get playerNicknameInvalid =>
      '3–20 Buchstaben, Ziffern, Punkte, Bindestriche oder Unterstriche';

  @override
  String get gridSelectCell => 'WÄHLEN';

  @override
  String get achievements => 'Erfolge';

  @override
  String get achievementPoints => 'Erfolgspunkte';

  @override
  String get achievementUnlocked => 'Erfolg freigeschaltet!';

  @override
  String get noAchievementsYet =>
      'Schließe Rätsel ab, um Erfolge freizuschalten.';

  @override
  String get dailyMissions => 'Tägliche Missionen';

  @override
  String get missionDailyPlayOneTitle => 'Täglicher Spieler';

  @override
  String get missionDailyPlayOneDesc => 'Löse das heutige Daily-Rätsel';

  @override
  String get missionDailyNoHintsTitle => 'Ohne Hilfe';

  @override
  String get missionDailyNoHintsDesc => 'Beende ein Rätsel ohne Hinweise';

  @override
  String get missionDailyLegendaryTitle => 'Legendenjäger';

  @override
  String get missionDailyLegendaryDesc =>
      'Finde heute eine legendäre oder seltenere Antwort';

  @override
  String get missionWeeklyHard3Title => 'Hard Mode';

  @override
  String get missionWeeklyHard3Desc =>
      'Schließe diese Woche 3 schwere Rätsel ab';

  @override
  String missionsProgress(int completed, int total) {
    return '$completed/$total erledigt';
  }

  @override
  String get shareResult => 'Ergebnis teilen';

  @override
  String get leaderboard => 'Bestenliste';

  @override
  String get leaderboardEmpty =>
      'Noch keine Rangliste. Spiele Rätsel, um gelistet zu werden.';

  @override
  String get pushNotifications => 'Benachrichtigungen';

  @override
  String get pushNotificationsOn => 'Serien-Erinnerungen aktiv';

  @override
  String get pushNotificationsOff => 'Benachrichtigungen aus';

  @override
  String get hintAdRequired =>
      'Sieh dir eine Werbung an, um diesen Tipp freizuschalten.';

  @override
  String get errorGeneric =>
      'Etwas ist schiefgelaufen. Bitte erneut versuchen.';

  @override
  String get answerCellNotFound =>
      'Dieses Feld kann gerade nicht geprüft werden. Puzzle aktualisieren und erneut versuchen.';

  @override
  String get errorNetwork => 'Netzwerkfehler. Verbindung prüfen.';

  @override
  String get errorOffline =>
      'Du bist offline. Verbindung prüfen und erneut versuchen.';

  @override
  String get errorTimeout =>
      'Die Anfrage hat zu lange gedauert. Bitte erneut versuchen.';

  @override
  String get errorServer =>
      'Unsere Server haben Probleme. Bitte später erneut versuchen.';

  @override
  String get errorAuth => 'Deine Sitzung ist abgelaufen. App neu starten.';

  @override
  String get errorValidation => 'Bitte Eingabe prüfen und erneut versuchen.';

  @override
  String get errorNotFound => 'Inhalt nicht gefunden.';

  @override
  String get bootLoading => 'CrossBall wird geladen…';

  @override
  String get bootFailed =>
      'CrossBall konnte nicht starten. Bitte erneut versuchen.';

  @override
  String get themeDarkGold => 'Gold-Stadion';

  @override
  String get themeLightClassic => 'Klassischer Rasen';

  @override
  String get themeDarkGoldDesc => 'Premium: dunkles Stadion mit Goldakzenten';

  @override
  String get themeLightClassicDesc => 'Premium: helles Feld mit Goldakzenten';

  @override
  String get mythicCelebration => 'MYTHISCH!';

  @override
  String get mythicCelebrationBody => 'Ultra-seltene Wahl — elite Fußball-IQ.';

  @override
  String get challengeFromAnySession =>
      'Teile dein zuletzt gelöstes Rätsel mit einem Freund.';

  @override
  String get challengeNeedSession =>
      'Schließe zuerst ein Rätsel ab, um eine Herausforderung zu erstellen.';

  @override
  String get challengeShareFailed =>
      'Herausforderung konnte nicht erstellt werden. Bitte erneut versuchen.';

  @override
  String get weeklyDailyScores => 'Diese Woche (Tagespunkte)';

  @override
  String get noDailyScore => '—';

  @override
  String get challengeRematch => 'Revanche — neuen Link teilen';

  @override
  String get dailyChallengeEasyDesc =>
      'Leichteres Rätsel zum Lernen — baue deine Serie auf.';

  @override
  String seasonPoints(int points) {
    return '$points SP';
  }

  @override
  String seasonNextReward(int points, String reward) {
    return 'Nächste Belohnung bei $points SP: $reward';
  }

  @override
  String get clubMastery => 'Vereins-Meisterschaft';

  @override
  String get clubMasteryEmpty =>
      'Löse Schnittpunkte, um Vereins-Meisterschaft aufzubauen.';

  @override
  String get hintCareerClubTaste =>
      'Wöchentliche Gratisprobe: weiteren Verein enthüllen';

  @override
  String get practiceGrid4Title => '4×4 Premium-Gitter';

  @override
  String get practiceGrid4Desc =>
      'Größeres Gitter mit mehr Vereinskombinationen.';

  @override
  String get premiumGridRequired => '4×4-Gitter sind eine Premium-Funktion.';

  @override
  String get timelineMode => 'Timeline-Training';

  @override
  String get timelineModeDesc =>
      'Sieh Karrierejahre nach jeder richtigen Antwort.';

  @override
  String get quickGridMode => 'Quick Grid';

  @override
  String get quickGridModeDesc =>
      'Gleiches CrossBall-Gitter — wähle aus 5 Spielern. 90 Sekunden. Kein Tippen.';

  @override
  String get quickGridPickTitle => 'Spieler wählen';

  @override
  String get quickGridChoicesError =>
      'Auswahl konnte nicht geladen werden. Erneut versuchen.';

  @override
  String get quickGridEliminateAd => 'Werbung ansehen — 1 Falsche entfernen';

  @override
  String get quickGridEliminateFree => '1 falsche Antwort entfernen';

  @override
  String timelineSheetTitle(String name) {
    return '$name — Karriere-Timeline';
  }

  @override
  String get timelineEmpty => 'Keine Karrieredaten für diesen Spieler.';

  @override
  String get present => 'Heute';

  @override
  String get activityFeed => 'Community-Aktivität';

  @override
  String activityDailyCompleted(String name, String score) {
    return '$name hat das Tagesrätsel gelöst ($score Pkt.)';
  }

  @override
  String activityChallengeCompleted(String name) {
    return '$name hat eine Freundes-Herausforderung abgeschlossen';
  }

  @override
  String activityTimelineCompleted(String name, String score) {
    return '$name hat Timeline-Training beendet ($score Pkt.)';
  }

  @override
  String activityGeneric(String name, String action) {
    return '$name: $action';
  }

  @override
  String activityDailyCompletedAction(String score) {
    return 'Daily-Rätsel abgeschlossen ($score Pkt.)';
  }

  @override
  String get activityChallengeCompletedAction =>
      'Freundes-Herausforderung beendet';

  @override
  String activityTimelineCompletedAction(String score) {
    return 'Timeline-Training beendet ($score Pkt.)';
  }

  @override
  String activityGenericAction(String action) {
    return '$action';
  }

  @override
  String get footballFactTitle => 'Wusstest du?';

  @override
  String get footballFactTip1 =>
      'Seltene Namen an einer Vereins-Kreuzung bringen oft mehr Punkte — mutige Tipps schlagen offensichtliche.';

  @override
  String get footballFactTip2 =>
      'Fußball-IQ heißt nicht nur Stars kennen, sondern versteckte Karrierepfade erinnern.';

  @override
  String get footballFactTip3 =>
      'Vertrau deinem Gedächtnis, nicht den Logos. Ungewöhnliche Antworten öffnen die Rangliste.';

  @override
  String get footballFactTip4 =>
      'Beliebte Namen geben selten leichte Punkte — die tiefen Tipps glänzen am meisten.';

  @override
  String get footballFactTip5 =>
      'Jede Zelle birgt eine Fußballgeschichte. Der richtige Spieler ist die richtige Kreuzung.';

  @override
  String get footballFactTimeline1 =>
      'Im Zeitstrahl-Modus ist das richtige Jahr der Schlüssel — lies die Karrierefolge genau.';

  @override
  String get footballFactTimeline2 =>
      'Achte auf Transferjahre; eine Saison kann das ganze Raster ändern.';

  @override
  String get footballFactTimeline3 =>
      'Chronologie belohnt schnelles Erinnern — ordne Vereinsstationen im Kopf.';

  @override
  String get tournament => 'Turnier';

  @override
  String get tournamentDesc => 'Wöchentlicher Highscore-Wettbewerb';

  @override
  String get tournamentInactive =>
      'Derzeit kein aktives Turnier. Schau bald wieder vorbei.';

  @override
  String get tournamentEmpty => 'Noch keine Punkte — sei der Erste!';

  @override
  String tournamentYourRank(int rank) {
    return 'Dein Rang: #$rank';
  }

  @override
  String get leaderboardWeeklyTab => 'Diese Woche';

  @override
  String get leaderboardRatingTab => 'Rating';

  @override
  String get weeklyLeaderboardTitle => 'Wöchentliche Daily-Rangliste';

  @override
  String get weeklyLeaderboardEmpty =>
      'Diese Woche noch keine Tagespunkte. Schließe das heutige Daily ab.';

  @override
  String get weekResetsMonday =>
      'Punkte reset Montag 00:00 UTC. Gleichstand: weniger Hinweise, dann weniger Fehler.';

  @override
  String daysPlayedCount(int count) {
    return '$count Tage gespielt';
  }

  @override
  String weeklyLeaderboardPenalties(int hints, int mistakes) {
    return 'Hinweise $hints · Fehler $mistakes';
  }

  @override
  String get communityHubTitle => 'Community';

  @override
  String get communityHubSubtitle =>
      'Tägliche Missionen, gemeinsame Ziele und aktuelle Spieleraktivität.';

  @override
  String get communityHubOpen => 'Öffnen';

  @override
  String get communityHubTeaserEmpty =>
      'Missionen, Community-Ziele & Spieleraktivität';

  @override
  String communityHubTeaserMissionLine(int completed, int total) {
    return '$completed/$total Missionen';
  }

  @override
  String communityHubTeaserGoalLine(int count) {
    return '$count Community-Ziele';
  }

  @override
  String communityHubTeaserActivityLine(int count) {
    return '$count aktuelle Spiele';
  }

  @override
  String get communityGoalsEmpty =>
      'Derzeit keine Community-Ziele. Schau bei Special Events wieder vorbei.';

  @override
  String get communityMissionsEmpty =>
      'Noch keine täglichen Missionen. Spiele ein Rätsel, um die heutigen Aufgaben freizuschalten.';

  @override
  String get activityFeedEmpty =>
      'Noch keine Freundesaktivität. Schließe Daily-Rätsel ab, um im Feed zu erscheinen.';

  @override
  String get moreGameModes => 'Weitere Modi';

  @override
  String get comingModesTitle => 'Demnächst';

  @override
  String get comingModesSubtitle =>
      'Neue Raster-Achsen und Event-Modi sind unterwegs.';

  @override
  String get comingModesLearnMore => 'Mehr erfahren';

  @override
  String get modeWorldXiTitle => 'World XI';

  @override
  String get modeWorldXiBody =>
      'Dasselbe Raster, neue Achsen — Spieler, die zu Verein und Nation passen.';

  @override
  String get modeThemedWeekTitle => 'Themenwoche';

  @override
  String get modeThemedWeekBody =>
      'Kalendergebundene Vereinsraster für große Fußballmomente.';

  @override
  String get modeBlitzTitle => 'Blitz';

  @override
  String get modeBlitzBody =>
      'Schnellere Sessions mit knapper Zeit — Hardcore-Wochen-Energie.';

  @override
  String get timeJustNow => 'Gerade eben';

  @override
  String timeMinutesAgo(int count) {
    return 'vor $count Min.';
  }

  @override
  String timeHoursAgo(int count) {
    return 'vor $count Std.';
  }

  @override
  String timeDaysAgo(int count) {
    return 'vor $count Tg.';
  }
}
