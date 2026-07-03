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
  /// **'Sharpen your skills. Limited free games.'**
  String get practiceDesc;

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

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

  /// No description provided for @gamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'Games Played'**
  String get gamesPlayed;

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

  /// No description provided for @createChallenge.
  ///
  /// In en, this message translates to:
  /// **'Create Challenge'**
  String get createChallenge;

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
  /// **'4×4 grids, unlimited practice, advanced stats, no ads.'**
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

  /// No description provided for @practiceLimitReached.
  ///
  /// In en, this message translates to:
  /// **'Free practice limit reached. Upgrade to Premium for unlimited games.'**
  String get practiceLimitReached;

  /// No description provided for @premiumFeatureGrid.
  ///
  /// In en, this message translates to:
  /// **'4×4 premium grids'**
  String get premiumFeatureGrid;

  /// No description provided for @premiumFeaturePractice.
  ///
  /// In en, this message translates to:
  /// **'Unlimited practice'**
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
