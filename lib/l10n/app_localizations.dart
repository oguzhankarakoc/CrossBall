import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
    Locale('de'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CrossBall'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Connect clubs. Prove your football IQ.'**
  String get tagline;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'CrossBall'**
  String get homeTitle;

  /// No description provided for @dailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'Daily Challenge'**
  String get dailyChallenge;

  /// No description provided for @dailyChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'One puzzle per day. Build your streak.'**
  String get dailyChallengeDesc;

  /// No description provided for @dailyRefreshSchedule.
  ///
  /// In en, this message translates to:
  /// **'Updates at {localTime} your time (00:00 UTC) · Next in {countdown}'**
  String dailyRefreshSchedule(String localTime, String countdown);

  /// No description provided for @dailyPuzzleRefreshTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle is being prepared'**
  String get dailyPuzzleRefreshTitle;

  /// No description provided for @dailyPuzzleRefreshBody.
  ///
  /// In en, this message translates to:
  /// **'Every day at midnight UTC we refresh clubs and build a new global grid. Yesterday\'s puzzle is closed while the new one is on the way.'**
  String get dailyPuzzleRefreshBody;

  /// No description provided for @dailyPuzzleRefreshElapsed.
  ///
  /// In en, this message translates to:
  /// **'Preparing for {elapsed}'**
  String dailyPuzzleRefreshElapsed(String elapsed);

  /// No description provided for @dailyPuzzleRefreshWindowHint.
  ///
  /// In en, this message translates to:
  /// **'This usually takes a few minutes. Thanks for your patience.'**
  String get dailyPuzzleRefreshWindowHint;

  /// No description provided for @dailyPuzzleRefreshAutoHint.
  ///
  /// In en, this message translates to:
  /// **'We\'ll check again automatically in {seconds}s.'**
  String dailyPuzzleRefreshAutoHint(int seconds);

  /// No description provided for @dailyPuzzleRefreshCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get dailyPuzzleRefreshCheckAgain;

  /// No description provided for @dailyPuzzleRefreshRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get dailyPuzzleRefreshRetry;

  /// No description provided for @dailyPuzzleRefreshFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s puzzle isn\'t ready yet'**
  String get dailyPuzzleRefreshFailedTitle;

  /// No description provided for @dailyPuzzleRefreshFailedBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t publish today\'s puzzle after the refresh window. You can retry — we\'ll attempt a safe fallback in the background.'**
  String get dailyPuzzleRefreshFailedBody;

  /// No description provided for @dailyPuzzleRefreshHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New puzzle incoming — refresh in progress at 00:00 UTC.'**
  String get dailyPuzzleRefreshHomeSubtitle;

  /// No description provided for @dailyPuzzleRefreshHomeHint.
  ///
  /// In en, this message translates to:
  /// **'Preparing today\'s puzzle…'**
  String get dailyPuzzleRefreshHomeHint;

  /// No description provided for @dailyPuzzleRefreshBadge.
  ///
  /// In en, this message translates to:
  /// **'Refreshing'**
  String get dailyPuzzleRefreshBadge;

  /// No description provided for @dailyAlreadyCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Puzzle Complete'**
  String get dailyAlreadyCompletedTitle;

  /// No description provided for @dailyAlreadyCompletedBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already finished today\'s daily puzzle. Come back after the next refresh for a new grid.'**
  String get dailyAlreadyCompletedBody;

  /// No description provided for @dailyAlreadyCompletedNextPuzzle.
  ///
  /// In en, this message translates to:
  /// **'Next puzzle around {localTime} · {countdown} to go'**
  String dailyAlreadyCompletedNextPuzzle(String localTime, String countdown);

  /// No description provided for @dailyAlreadyCompletedBadge.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dailyAlreadyCompletedBadge;

  /// No description provided for @dailyAlreadyCompletedHomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You finished today\'s puzzle. A new grid arrives tomorrow.'**
  String get dailyAlreadyCompletedHomeSubtitle;

  /// No description provided for @dailyAlreadyCompletedViewSummary.
  ///
  /// In en, this message translates to:
  /// **'View Summary'**
  String get dailyAlreadyCompletedViewSummary;

  /// No description provided for @friendChallenge.
  ///
  /// In en, this message translates to:
  /// **'Friend Challenge'**
  String get friendChallenge;

  /// No description provided for @friendChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Share a link and compete async.'**
  String get friendChallengeDesc;

  /// No description provided for @practice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get practice;

  /// No description provided for @practiceDesc.
  ///
  /// In en, this message translates to:
  /// **'5 sessions per day. Watch ads to unlock the next round.'**
  String get practiceDesc;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @activeEvents.
  ///
  /// In en, this message translates to:
  /// **'Active Events'**
  String get activeEvents;

  /// No description provided for @eventLockedBadge.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get eventLockedBadge;

  /// No description provided for @eventLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'Themed club grids for this event are not available yet. Stay tuned!'**
  String get eventLockedMessage;

  /// No description provided for @communityGoals.
  ///
  /// In en, this message translates to:
  /// **'Community Goals'**
  String get communityGoals;

  /// No description provided for @maintenanceNotice.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenanceNotice;

  /// No description provided for @maintenanceNoticeBody.
  ///
  /// In en, this message translates to:
  /// **'Some services may be limited. You can still play puzzles.'**
  String get maintenanceNoticeBody;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @premium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Play'**
  String get onboardingStart;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Pick a grid cell'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Tap any cell to start solving.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'Connect both clubs'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Find a footballer who played for both clubs.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Rare picks score higher'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Less common players give more points.'**
  String get onboarding3Body;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get comingSoon;

  /// No description provided for @puzzleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load today\'s puzzle. Check your connection and try again.'**
  String get puzzleLoadFailed;

  /// No description provided for @practiceLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load a practice puzzle. Check your connection and try again.'**
  String get practiceLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @experiencePoints.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get experiencePoints;

  /// No description provided for @homeWeeklyScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get homeWeeklyScoreLabel;

  /// No description provided for @competitiveRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get competitiveRating;

  /// No description provided for @league.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get league;

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current Streak'**
  String get currentStreak;

  /// No description provided for @bestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best Streak'**
  String get bestStreak;

  /// No description provided for @totalScore.
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScore;

  /// No description provided for @rarityBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Rarity Breakdown'**
  String get rarityBreakdown;

  /// No description provided for @rarityBreakdownEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your rarity mix appears after competitive puzzles (Daily & Challenges).'**
  String get rarityBreakdownEmpty;

  /// No description provided for @rarityBreakdownHint.
  ///
  /// In en, this message translates to:
  /// **'Obscure picks push rare tiers up — that\'s how you climb.'**
  String get rarityBreakdownHint;

  /// No description provided for @statsCareerTitle.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get statsCareerTitle;

  /// No description provided for @statsActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get statsActivityTitle;

  /// No description provided for @statsProgressUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your level. Pull to refresh.'**
  String get statsProgressUnavailable;

  /// No description provided for @createChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get createChallenge;

  /// No description provided for @createAndShareChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create & Share Challenge'**
  String get createAndShareChallenge;

  /// No description provided for @createChallengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve today\'s puzzle first, then share your score.'**
  String get createChallengeDesc;

  /// No description provided for @joinChallenge.
  ///
  /// In en, this message translates to:
  /// **'Join Challenge'**
  String get joinChallenge;

  /// No description provided for @challengeDesc.
  ///
  /// In en, this message translates to:
  /// **'Challenge friends asynchronously. Same puzzle, compare scores.'**
  String get challengeDesc;

  /// No description provided for @challengeCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter challenge code'**
  String get challengeCodeHint;

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Link copied!'**
  String get copied;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @premiumTitle.
  ///
  /// In en, this message translates to:
  /// **'CrossBall Premium'**
  String get premiumTitle;

  /// No description provided for @premiumDesc.
  ///
  /// In en, this message translates to:
  /// **'10 ad-free training sessions per day, advanced stats, no ads.'**
  String get premiumDesc;

  /// No description provided for @upgradePremium.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get upgradePremium;

  /// No description provided for @searchPlayer.
  ///
  /// In en, this message translates to:
  /// **'Search player...'**
  String get searchPlayer;

  /// No description provided for @recentPicks.
  ///
  /// In en, this message translates to:
  /// **'Recent picks'**
  String get recentPicks;

  /// No description provided for @popularPicks.
  ///
  /// In en, this message translates to:
  /// **'Popular picks'**
  String get popularPicks;

  /// No description provided for @suggestedForCell.
  ///
  /// In en, this message translates to:
  /// **'Suggested for this cell'**
  String get suggestedForCell;

  /// No description provided for @noPlayersFound.
  ///
  /// In en, this message translates to:
  /// **'No players found'**
  String get noPlayersFound;

  /// No description provided for @puzzleComplete.
  ///
  /// In en, this message translates to:
  /// **'Puzzle Complete!'**
  String get puzzleComplete;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @mistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get mistakes;

  /// No description provided for @hintsUsed.
  ///
  /// In en, this message translates to:
  /// **'Hints used'**
  String get hintsUsed;

  /// No description provided for @score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @tier.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get tier;

  /// No description provided for @usedBy.
  ///
  /// In en, this message translates to:
  /// **'Used by {percent}%'**
  String usedBy(String percent);

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Stadium'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Pitch'**
  String get themeLight;

  /// No description provided for @themeSystemDesc.
  ///
  /// In en, this message translates to:
  /// **'Follow your device appearance'**
  String get themeSystemDesc;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Black pitch, stadium lights, pitch green accents'**
  String get themeDarkDesc;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'Soft field green, premium gold accents'**
  String get themeLightDesc;

  /// No description provided for @localeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get localeSystem;

  /// No description provided for @localeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @localeTurkish.
  ///
  /// In en, this message translates to:
  /// **'Türkçe'**
  String get localeTurkish;

  /// No description provided for @localeGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get localeGerman;

  /// No description provided for @hintNationality.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for nationality hint'**
  String get hintNationality;

  /// No description provided for @hintPosition.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for position hint'**
  String get hintPosition;

  /// No description provided for @hintFirstLetter.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for first letter hint'**
  String get hintFirstLetter;

  /// No description provided for @hintCareerLeague.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for career league hint'**
  String get hintCareerLeague;

  /// No description provided for @hintRetiredStatus.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for active/retired hint'**
  String get hintRetiredStatus;

  /// No description provided for @hintCareerClub.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for career club hint'**
  String get hintCareerClub;

  /// No description provided for @hintNationalityPremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal nationality hint'**
  String get hintNationalityPremium;

  /// No description provided for @hintPositionPremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal position hint'**
  String get hintPositionPremium;

  /// No description provided for @hintFirstLetterPremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal first letter hint'**
  String get hintFirstLetterPremium;

  /// No description provided for @hintCareerLeaguePremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal career league hint'**
  String get hintCareerLeaguePremium;

  /// No description provided for @hintRetiredStatusPremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal active/retired hint'**
  String get hintRetiredStatusPremium;

  /// No description provided for @hintCareerClubPremium.
  ///
  /// In en, this message translates to:
  /// **'Reveal career club hint'**
  String get hintCareerClubPremium;

  /// No description provided for @hintChipNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get hintChipNationality;

  /// No description provided for @hintChipPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get hintChipPosition;

  /// No description provided for @hintChipFirstLetter.
  ///
  /// In en, this message translates to:
  /// **'First letter'**
  String get hintChipFirstLetter;

  /// No description provided for @hintChipStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get hintChipStatus;

  /// No description provided for @hintChipClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get hintChipClub;

  /// No description provided for @hintValueUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get hintValueUnknown;

  /// No description provided for @hintStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get hintStatusActive;

  /// No description provided for @hintStatusRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get hintStatusRetired;

  /// No description provided for @hintLimitReached.
  ///
  /// In en, this message translates to:
  /// **'All hints for this cell are already revealed.'**
  String get hintLimitReached;

  /// No description provided for @hintUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Hint unavailable right now. Please try again.'**
  String get hintUnavailable;

  /// No description provided for @searchCompetitiveEmpty.
  ///
  /// In en, this message translates to:
  /// **'Type a player name to search. Use the hint button above for help.'**
  String get searchCompetitiveEmpty;

  /// No description provided for @practiceLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Daily training limit reached. Come back tomorrow or upgrade to Premium.'**
  String get practiceLimitReached;

  /// No description provided for @practiceAdRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Next training'**
  String get practiceAdRequiredTitle;

  /// No description provided for @practiceAdRequired.
  ///
  /// In en, this message translates to:
  /// **'Watch a short ad to start your next training session.'**
  String get practiceAdRequired;

  /// No description provided for @practiceWatchAdForNewSession.
  ///
  /// In en, this message translates to:
  /// **'Watch ad for new training'**
  String get practiceWatchAdForNewSession;

  /// No description provided for @practiceNewSession.
  ///
  /// In en, this message translates to:
  /// **'New training'**
  String get practiceNewSession;

  /// No description provided for @practiceCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Fresh club combinations every session.'**
  String get practiceCompleteDesc;

  /// No description provided for @practiceFinishTraining.
  ///
  /// In en, this message translates to:
  /// **'Finish training'**
  String get practiceFinishTraining;

  /// No description provided for @practiceFinishConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Finish training?'**
  String get practiceFinishConfirmTitle;

  /// No description provided for @practiceFinishConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This session ends and uses 1 of your daily training credits.'**
  String get practiceFinishConfirmBody;

  /// No description provided for @practiceResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Training complete'**
  String get practiceResultTitle;

  /// No description provided for @practiceResultEarlyDesc.
  ///
  /// In en, this message translates to:
  /// **'You finished early — your score and progress were saved.'**
  String get practiceResultEarlyDesc;

  /// No description provided for @practiceSessionProgress.
  ///
  /// In en, this message translates to:
  /// **'Training {current}/{limit}'**
  String practiceSessionProgress(int current, int limit);

  /// No description provided for @practiceDailyProgress.
  ///
  /// In en, this message translates to:
  /// **'{used}/{limit} training sessions used today'**
  String practiceDailyProgress(int used, int limit);

  /// No description provided for @practiceAdGateHint.
  ///
  /// In en, this message translates to:
  /// **'On the free plan, watch a short ad before each new training session.'**
  String get practiceAdGateHint;

  /// No description provided for @practicePremiumSkipAds.
  ///
  /// In en, this message translates to:
  /// **'Premium: up to 10 training sessions per day, no ads between rounds.'**
  String get practicePremiumSkipAds;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @practiceSessionsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} training sessions left today'**
  String practiceSessionsRemaining(int count);

  /// No description provided for @premiumFeatureGrid.
  ///
  /// In en, this message translates to:
  /// **'4×4 premium grids'**
  String get premiumFeatureGrid;

  /// No description provided for @premiumFeaturePractice.
  ///
  /// In en, this message translates to:
  /// **'10 ad-free training sessions per day'**
  String get premiumFeaturePractice;

  /// No description provided for @premiumFeatureStats.
  ///
  /// In en, this message translates to:
  /// **'Advanced stats'**
  String get premiumFeatureStats;

  /// No description provided for @premiumFeatureThemes.
  ///
  /// In en, this message translates to:
  /// **'Exclusive themes'**
  String get premiumFeatureThemes;

  /// No description provided for @premiumFeatureNoAds.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get premiumFeatureNoAds;

  /// No description provided for @premiumActivated.
  ///
  /// In en, this message translates to:
  /// **'Premium activated!'**
  String get premiumActivated;

  /// No description provided for @premiumActive.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premiumActive;

  /// No description provided for @premiumPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not activate Premium. Please try again.'**
  String get premiumPurchaseFailed;

  /// No description provided for @premiumVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be verified. Try Restore Purchases or contact support.'**
  String get premiumVerificationFailed;

  /// No description provided for @premiumPurchaseUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Premium is not available in the store yet. Check App Store setup or try again later.'**
  String get premiumPurchaseUnavailable;

  /// No description provided for @premiumDevNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Dev premium is not enabled on the server. Set IAP_SKIP_VERIFY=true in Supabase, or use IAP_ENABLED=true with StoreKit.'**
  String get premiumDevNotConfigured;

  /// No description provided for @premiumPurchasePending.
  ///
  /// In en, this message translates to:
  /// **'Finishing your pending App Store purchase. Try again in a moment or tap Restore Purchases.'**
  String get premiumPurchasePending;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get restorePurchases;

  /// No description provided for @completeDailyFirst.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s daily puzzle first to create a challenge.'**
  String get completeDailyFirst;

  /// No description provided for @challengeYouWon.
  ///
  /// In en, this message translates to:
  /// **'You won the challenge!'**
  String get challengeYouWon;

  /// No description provided for @challengeYouLost.
  ///
  /// In en, this message translates to:
  /// **'You lost this round.'**
  String get challengeYouLost;

  /// No description provided for @challengeTie.
  ///
  /// In en, this message translates to:
  /// **'It\'s a tie!'**
  String get challengeTie;

  /// No description provided for @challengeCreator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get challengeCreator;

  /// No description provided for @challengeYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get challengeYou;

  /// No description provided for @playerNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get playerNickname;

  /// No description provided for @playerNicknameDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional name for challenges and future leaderboards.'**
  String get playerNicknameDesc;

  /// No description provided for @playerNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'3–20 characters'**
  String get playerNicknameHint;

  /// No description provided for @playerNicknameSaved.
  ///
  /// In en, this message translates to:
  /// **'Nickname saved'**
  String get playerNicknameSaved;

  /// No description provided for @playerNicknameTaken.
  ///
  /// In en, this message translates to:
  /// **'This nickname is already taken'**
  String get playerNicknameTaken;

  /// No description provided for @playerNicknameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 3–20 letters, numbers, dots, dashes or underscores'**
  String get playerNicknameInvalid;

  /// No description provided for @gridSelectCell.
  ///
  /// In en, this message translates to:
  /// **'SELECT'**
  String get gridSelectCell;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @achievementPoints.
  ///
  /// In en, this message translates to:
  /// **'Achievement Points'**
  String get achievementPoints;

  /// No description provided for @achievementUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievement unlocked!'**
  String get achievementUnlocked;

  /// No description provided for @noAchievementsYet.
  ///
  /// In en, this message translates to:
  /// **'Complete puzzles to unlock achievements.'**
  String get noAchievementsYet;

  /// No description provided for @dailyMissions.
  ///
  /// In en, this message translates to:
  /// **'Daily Missions'**
  String get dailyMissions;

  /// No description provided for @missionDailyPlayOneTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Player'**
  String get missionDailyPlayOneTitle;

  /// No description provided for @missionDailyPlayOneDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete today\'s daily puzzle'**
  String get missionDailyPlayOneDesc;

  /// No description provided for @missionDailyNoHintsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Help Needed'**
  String get missionDailyNoHintsTitle;

  /// No description provided for @missionDailyNoHintsDesc.
  ///
  /// In en, this message translates to:
  /// **'Finish a puzzle without using hints'**
  String get missionDailyNoHintsDesc;

  /// No description provided for @missionDailyLegendaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Legend Hunter'**
  String get missionDailyLegendaryTitle;

  /// No description provided for @missionDailyLegendaryDesc.
  ///
  /// In en, this message translates to:
  /// **'Find one legendary or better answer today'**
  String get missionDailyLegendaryDesc;

  /// No description provided for @missionWeeklyHard3Title.
  ///
  /// In en, this message translates to:
  /// **'Hard Mode'**
  String get missionWeeklyHard3Title;

  /// No description provided for @missionWeeklyHard3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 hard puzzles this week'**
  String get missionWeeklyHard3Desc;

  /// No description provided for @missionsProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} done'**
  String missionsProgress(int completed, int total);

  /// No description provided for @shareResult.
  ///
  /// In en, this message translates to:
  /// **'Share result'**
  String get shareResult;

  /// No description provided for @leaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get leaderboard;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No ranked players yet. Complete puzzles to appear on the board.'**
  String get leaderboardEmpty;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pushNotifications;

  /// No description provided for @pushNotificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Streak reminders enabled'**
  String get pushNotificationsOn;

  /// No description provided for @pushNotificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get pushNotificationsOff;

  /// No description provided for @hintAdRequired.
  ///
  /// In en, this message translates to:
  /// **'Watch an ad to unlock this hint.'**
  String get hintAdRequired;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @answerCellNotFound.
  ///
  /// In en, this message translates to:
  /// **'This cell cannot be validated right now. Refresh the puzzle and try again.'**
  String get answerCellNotFound;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your connection.'**
  String get errorNetwork;

  /// No description provided for @errorOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Check your connection and try again.'**
  String get errorOffline;

  /// No description provided for @errorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request took too long. Please try again.'**
  String get errorTimeout;

  /// No description provided for @errorServer.
  ///
  /// In en, this message translates to:
  /// **'Our servers are having trouble. Please try again shortly.'**
  String get errorServer;

  /// No description provided for @errorAuth.
  ///
  /// In en, this message translates to:
  /// **'Your session expired. Restart the app to continue.'**
  String get errorAuth;

  /// No description provided for @errorValidation.
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get errorValidation;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find what you\'re looking for.'**
  String get errorNotFound;

  /// No description provided for @bootLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading CrossBall…'**
  String get bootLoading;

  /// No description provided for @bootFailed.
  ///
  /// In en, this message translates to:
  /// **'CrossBall couldn\'t start. Please try again.'**
  String get bootFailed;

  /// No description provided for @themeDarkGold.
  ///
  /// In en, this message translates to:
  /// **'Gold Stadium'**
  String get themeDarkGold;

  /// No description provided for @themeLightClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic Pitch'**
  String get themeLightClassic;

  /// No description provided for @themeDarkGoldDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium: black pitch with gold accents'**
  String get themeDarkGoldDesc;

  /// No description provided for @themeLightClassicDesc.
  ///
  /// In en, this message translates to:
  /// **'Premium: warm white pitch with gold accents'**
  String get themeLightClassicDesc;

  /// No description provided for @mythicCelebration.
  ///
  /// In en, this message translates to:
  /// **'MYTHIC!'**
  String get mythicCelebration;

  /// No description provided for @mythicCelebrationBody.
  ///
  /// In en, this message translates to:
  /// **'Ultra-rare pick — elite football IQ.'**
  String get mythicCelebrationBody;

  /// No description provided for @challengeFromAnySession.
  ///
  /// In en, this message translates to:
  /// **'Share your last completed puzzle with a friend.'**
  String get challengeFromAnySession;

  /// No description provided for @challengeNeedSession.
  ///
  /// In en, this message translates to:
  /// **'Complete any puzzle first to create a challenge.'**
  String get challengeNeedSession;

  /// No description provided for @challengeShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the challenge. Please try again.'**
  String get challengeShareFailed;

  /// No description provided for @weeklyDailyScores.
  ///
  /// In en, this message translates to:
  /// **'This Week (Daily Scores)'**
  String get weeklyDailyScores;

  /// No description provided for @noDailyScore.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get noDailyScore;

  /// No description provided for @challengeRematch.
  ///
  /// In en, this message translates to:
  /// **'Rematch — share new link'**
  String get challengeRematch;

  /// No description provided for @dailyChallengeEasyDesc.
  ///
  /// In en, this message translates to:
  /// **'Easier puzzle while you learn — build your streak.'**
  String get dailyChallengeEasyDesc;

  /// No description provided for @seasonPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} SP'**
  String seasonPoints(int points);

  /// No description provided for @seasonNextReward.
  ///
  /// In en, this message translates to:
  /// **'Next reward at {points} SP: {reward}'**
  String seasonNextReward(int points, String reward);

  /// No description provided for @clubMastery.
  ///
  /// In en, this message translates to:
  /// **'Club Mastery'**
  String get clubMastery;

  /// No description provided for @clubMasteryEmpty.
  ///
  /// In en, this message translates to:
  /// **'Solve intersections to build club mastery.'**
  String get clubMasteryEmpty;

  /// No description provided for @hintCareerClubTaste.
  ///
  /// In en, this message translates to:
  /// **'Free weekly taste: reveal another career club'**
  String get hintCareerClubTaste;

  /// No description provided for @practiceGrid4Title.
  ///
  /// In en, this message translates to:
  /// **'4×4 Premium Grid'**
  String get practiceGrid4Title;

  /// No description provided for @practiceGrid4Desc.
  ///
  /// In en, this message translates to:
  /// **'Larger grid with more club combinations.'**
  String get practiceGrid4Desc;

  /// No description provided for @premiumGridRequired.
  ///
  /// In en, this message translates to:
  /// **'4×4 grids are a Premium feature.'**
  String get premiumGridRequired;

  /// No description provided for @timelineMode.
  ///
  /// In en, this message translates to:
  /// **'Timeline Training'**
  String get timelineMode;

  /// No description provided for @timelineModeDesc.
  ///
  /// In en, this message translates to:
  /// **'See career years after each correct answer.'**
  String get timelineModeDesc;

  /// No description provided for @timelineSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — career timeline'**
  String timelineSheetTitle(String name);

  /// No description provided for @timelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No senior career data available for this player.'**
  String get timelineEmpty;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @activityFeed.
  ///
  /// In en, this message translates to:
  /// **'Community Activity'**
  String get activityFeed;

  /// No description provided for @activityDailyCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} completed the daily puzzle ({score} pts)'**
  String activityDailyCompleted(String name, String score);

  /// No description provided for @activityChallengeCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} finished a friend challenge'**
  String activityChallengeCompleted(String name);

  /// No description provided for @activityTimelineCompleted.
  ///
  /// In en, this message translates to:
  /// **'{name} finished timeline training ({score} pts)'**
  String activityTimelineCompleted(String name, String score);

  /// No description provided for @activityGeneric.
  ///
  /// In en, this message translates to:
  /// **'{name}: {action}'**
  String activityGeneric(String name, String action);

  /// No description provided for @activityDailyCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'Completed the daily puzzle ({score} pts)'**
  String activityDailyCompletedAction(String score);

  /// No description provided for @activityChallengeCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'Finished a friend challenge'**
  String get activityChallengeCompletedAction;

  /// No description provided for @activityTimelineCompletedAction.
  ///
  /// In en, this message translates to:
  /// **'Finished timeline training ({score} pts)'**
  String activityTimelineCompletedAction(String score);

  /// No description provided for @activityGenericAction.
  ///
  /// In en, this message translates to:
  /// **'{action}'**
  String activityGenericAction(String action);

  /// No description provided for @footballFactTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you know?'**
  String get footballFactTitle;

  /// No description provided for @footballFactTip1.
  ///
  /// In en, this message translates to:
  /// **'The rarest names at a club crossing often score highest — bold picks beat obvious ones.'**
  String get footballFactTip1;

  /// No description provided for @footballFactTip2.
  ///
  /// In en, this message translates to:
  /// **'Football IQ is not just knowing stars; it is remembering the hidden career paths.'**
  String get footballFactTip2;

  /// No description provided for @footballFactTip3.
  ///
  /// In en, this message translates to:
  /// **'Trust your memory, not the badges. Uncommon answers unlock the leaderboard.'**
  String get footballFactTip3;

  /// No description provided for @footballFactTip4.
  ///
  /// In en, this message translates to:
  /// **'Popular names rarely give easy points — the deep cuts shine brightest.'**
  String get footballFactTip4;

  /// No description provided for @footballFactTip5.
  ///
  /// In en, this message translates to:
  /// **'Every cell hides a football story. The right player is the right intersection.'**
  String get footballFactTip5;

  /// No description provided for @footballFactTimeline1.
  ///
  /// In en, this message translates to:
  /// **'In timeline mode, the right year unlocks the right player — read the career order carefully.'**
  String get footballFactTimeline1;

  /// No description provided for @footballFactTimeline2.
  ///
  /// In en, this message translates to:
  /// **'Watch transfer years closely; one season can change the whole grid.'**
  String get footballFactTimeline2;

  /// No description provided for @footballFactTimeline3.
  ///
  /// In en, this message translates to:
  /// **'Chronology rewards quick recall — line up club spells in your head.'**
  String get footballFactTimeline3;

  /// No description provided for @tournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get tournament;

  /// No description provided for @tournamentDesc.
  ///
  /// In en, this message translates to:
  /// **'Weekly high-score competition'**
  String get tournamentDesc;

  /// No description provided for @tournamentInactive.
  ///
  /// In en, this message translates to:
  /// **'No active tournament right now. Check back soon.'**
  String get tournamentInactive;

  /// No description provided for @tournamentEmpty.
  ///
  /// In en, this message translates to:
  /// **'No scores yet — be the first to play!'**
  String get tournamentEmpty;

  /// No description provided for @tournamentYourRank.
  ///
  /// In en, this message translates to:
  /// **'Your rank: #{rank}'**
  String tournamentYourRank(int rank);

  /// No description provided for @leaderboardWeeklyTab.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get leaderboardWeeklyTab;

  /// No description provided for @leaderboardRatingTab.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get leaderboardRatingTab;

  /// No description provided for @weeklyLeaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Daily Challenge'**
  String get weeklyLeaderboardTitle;

  /// No description provided for @weeklyLeaderboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily scores this week yet. Complete today\'s puzzle to join the board.'**
  String get weeklyLeaderboardEmpty;

  /// No description provided for @weekResetsMonday.
  ///
  /// In en, this message translates to:
  /// **'Scores reset every Monday 00:00 UTC. Tie-break: fewer hints, then fewer mistakes.'**
  String get weekResetsMonday;

  /// No description provided for @daysPlayedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} days played'**
  String daysPlayedCount(int count);

  /// No description provided for @weeklyLeaderboardPenalties.
  ///
  /// In en, this message translates to:
  /// **'Hints {hints} · Mistakes {mistakes}'**
  String weeklyLeaderboardPenalties(int hints, int mistakes);

  /// No description provided for @communityHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityHubTitle;

  /// No description provided for @communityHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily missions, shared goals, and what players are doing right now.'**
  String get communityHubSubtitle;

  /// No description provided for @communityHubOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get communityHubOpen;

  /// No description provided for @communityHubTeaserEmpty.
  ///
  /// In en, this message translates to:
  /// **'Missions, community goals & player activity'**
  String get communityHubTeaserEmpty;

  /// No description provided for @communityHubTeaserMissionLine.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{total} missions'**
  String communityHubTeaserMissionLine(int completed, int total);

  /// No description provided for @communityHubTeaserGoalLine.
  ///
  /// In en, this message translates to:
  /// **'{count} community goals'**
  String communityHubTeaserGoalLine(int count);

  /// No description provided for @communityHubTeaserActivityLine.
  ///
  /// In en, this message translates to:
  /// **'{count} recent plays'**
  String communityHubTeaserActivityLine(int count);

  /// No description provided for @communityGoalsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active community goals right now. Check back during special events.'**
  String get communityGoalsEmpty;

  /// No description provided for @communityMissionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No daily missions available yet. Play a puzzle to unlock today\'s tasks.'**
  String get communityMissionsEmpty;

  /// No description provided for @activityFeedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recent activity from friends yet. Complete daily puzzles to appear on the feed.'**
  String get activityFeedEmpty;

  /// No description provided for @moreGameModes.
  ///
  /// In en, this message translates to:
  /// **'More Modes'**
  String get moreGameModes;

  /// No description provided for @comingModesTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingModesTitle;

  /// No description provided for @comingModesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New grid axes and event modes are on the way.'**
  String get comingModesSubtitle;

  /// No description provided for @comingModesLearnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get comingModesLearnMore;

  /// No description provided for @modeWorldXiTitle.
  ///
  /// In en, this message translates to:
  /// **'World XI'**
  String get modeWorldXiTitle;

  /// No description provided for @modeWorldXiBody.
  ///
  /// In en, this message translates to:
  /// **'Same grid, new axes — find players who fit both the club and the country.'**
  String get modeWorldXiBody;

  /// No description provided for @modeThemedWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Themed Week'**
  String get modeThemedWeekTitle;

  /// No description provided for @modeThemedWeekBody.
  ///
  /// In en, this message translates to:
  /// **'Calendar-tied club grids for big football moments.'**
  String get modeThemedWeekBody;

  /// No description provided for @modeBlitzTitle.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get modeBlitzTitle;

  /// No description provided for @modeBlitzBody.
  ///
  /// In en, this message translates to:
  /// **'Faster sessions with a tighter clock — hardcore week energy.'**
  String get modeBlitzBody;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
