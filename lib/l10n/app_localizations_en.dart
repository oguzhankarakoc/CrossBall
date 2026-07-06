// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CrossBall';

  @override
  String get tagline => 'Connect clubs. Prove your football IQ.';

  @override
  String get homeTitle => 'CrossBall';

  @override
  String get dailyChallenge => 'Daily Challenge';

  @override
  String get dailyChallengeDesc => 'One puzzle per day. Build your streak.';

  @override
  String dailyRefreshSchedule(String localTime, String countdown) {
    return 'Updates at $localTime your time (00:00 UTC) · Next in $countdown';
  }

  @override
  String get dailyPuzzleRefreshTitle => 'Today\'s puzzle is being prepared';

  @override
  String get dailyPuzzleRefreshBody =>
      'Every day at midnight UTC we refresh clubs and build a new global grid. Yesterday\'s puzzle is closed while the new one is on the way.';

  @override
  String dailyPuzzleRefreshElapsed(String elapsed) {
    return 'Preparing for $elapsed';
  }

  @override
  String get dailyPuzzleRefreshWindowHint =>
      'This usually takes a few minutes. Thanks for your patience.';

  @override
  String dailyPuzzleRefreshAutoHint(int seconds) {
    return 'We\'ll check again automatically in ${seconds}s.';
  }

  @override
  String get dailyPuzzleRefreshCheckAgain => 'Check again';

  @override
  String get dailyPuzzleRefreshRetry => 'Try again';

  @override
  String get dailyPuzzleRefreshFailedTitle =>
      'Today\'s puzzle isn\'t ready yet';

  @override
  String get dailyPuzzleRefreshFailedBody =>
      'We couldn\'t publish today\'s puzzle after the refresh window. You can retry — we\'ll attempt a safe fallback in the background.';

  @override
  String get dailyPuzzleRefreshHomeSubtitle =>
      'New puzzle incoming — refresh in progress at 00:00 UTC.';

  @override
  String get dailyPuzzleRefreshHomeHint => 'Preparing today\'s puzzle…';

  @override
  String get dailyPuzzleRefreshBadge => 'Refreshing';

  @override
  String get friendChallenge => 'Friend Challenge';

  @override
  String get friendChallengeDesc => 'Share a link and compete async.';

  @override
  String get practice => 'Practice';

  @override
  String get practiceDesc =>
      '5 sessions per day. Watch ads to unlock the next round.';

  @override
  String get stats => 'Stats';

  @override
  String get activeEvents => 'Active Events';

  @override
  String get eventLockedBadge => 'Coming soon';

  @override
  String get eventLockedMessage =>
      'Themed club grids for this event are not available yet. Stay tuned!';

  @override
  String get communityGoals => 'Community Goals';

  @override
  String get maintenanceNotice => 'Maintenance';

  @override
  String get maintenanceNoticeBody =>
      'Some services may be limited. You can still play puzzles.';

  @override
  String get settings => 'Settings';

  @override
  String get premium => 'Premium';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingStart => 'Let\'s Play';

  @override
  String get onboarding1Title => 'Pick a grid cell';

  @override
  String get onboarding1Body => 'Tap any cell to start solving.';

  @override
  String get onboarding2Title => 'Connect both clubs';

  @override
  String get onboarding2Body => 'Find a footballer who played for both clubs.';

  @override
  String get onboarding3Title => 'Rare picks score higher';

  @override
  String get onboarding3Body => 'Less common players give more points.';

  @override
  String get comingSoon => 'Loading...';

  @override
  String get puzzleLoadFailed =>
      'Could not load today\'s puzzle. Check your connection and try again.';

  @override
  String get practiceLoadFailed =>
      'Could not load a practice puzzle. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get gamesPlayed => 'Games Played';

  @override
  String get level => 'Level';

  @override
  String get experiencePoints => 'XP';

  @override
  String get competitiveRating => 'Rating';

  @override
  String get league => 'League';

  @override
  String get currentStreak => 'Current Streak';

  @override
  String get bestStreak => 'Best Streak';

  @override
  String get totalScore => 'Total Score';

  @override
  String get rarityBreakdown => 'Rarity Breakdown';

  @override
  String get createChallenge => 'Create Challenge';

  @override
  String get createChallengeDesc =>
      'Solve today\'s puzzle first, then share your score.';

  @override
  String get joinChallenge => 'Join Challenge';

  @override
  String get challengeDesc =>
      'Challenge friends asynchronously. Same puzzle, compare scores.';

  @override
  String get challengeCodeHint => 'Enter challenge code';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get share => 'Share';

  @override
  String get copied => 'Link copied!';

  @override
  String get language => 'Language';

  @override
  String get premiumTitle => 'CrossBall Premium';

  @override
  String get premiumDesc =>
      '10 ad-free training sessions per day, advanced stats, no ads.';

  @override
  String get upgradePremium => 'Upgrade to Premium';

  @override
  String get searchPlayer => 'Search player...';

  @override
  String get recentPicks => 'Recent picks';

  @override
  String get popularPicks => 'Popular picks';

  @override
  String get suggestedForCell => 'Suggested for this cell';

  @override
  String get noPlayersFound => 'No players found';

  @override
  String get puzzleComplete => 'Puzzle Complete!';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get mistakes => 'Mistakes';

  @override
  String get hintsUsed => 'Hints used';

  @override
  String get score => 'Score';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get tier => 'Tier';

  @override
  String usedBy(String percent) {
    return 'Used by $percent%';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeDark => 'Dark Stadium';

  @override
  String get themeLight => 'Light Pitch';

  @override
  String get themeSystemDesc => 'Follow your device appearance';

  @override
  String get themeDarkDesc =>
      'Black pitch, stadium lights, pitch green accents';

  @override
  String get themeLightDesc => 'Soft field green, premium gold accents';

  @override
  String get localeSystem => 'System default';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeTurkish => 'Türkçe';

  @override
  String get localeGerman => 'Deutsch';

  @override
  String get hintNationality => 'Watch ad for nationality hint';

  @override
  String get hintPosition => 'Watch ad for position hint';

  @override
  String get hintFirstLetter => 'Watch ad for first letter hint';

  @override
  String get hintCareerLeague => 'Watch ad for career league hint';

  @override
  String get hintRetiredStatus => 'Watch ad for active/retired hint';

  @override
  String get hintCareerClub => 'Premium: reveal another career club';

  @override
  String get hintNationalityPremium => 'Reveal nationality hint';

  @override
  String get hintPositionPremium => 'Reveal position hint';

  @override
  String get hintFirstLetterPremium => 'Reveal first letter hint';

  @override
  String get hintCareerLeaguePremium => 'Reveal career league hint';

  @override
  String get hintRetiredStatusPremium => 'Reveal active/retired hint';

  @override
  String get unlockPlayerSuggestionsAd => 'Watch ad to see player suggestions';

  @override
  String get unlockPlayerSuggestionsPremium => 'Show player suggestions';

  @override
  String get searchCompetitiveEmpty =>
      'Type a player name — suggestions stay hidden until you unlock help.';

  @override
  String get practiceLimitReached =>
      'Daily training limit reached. Come back tomorrow or upgrade to Premium.';

  @override
  String get practiceAdRequiredTitle => 'Next training';

  @override
  String get practiceAdRequired =>
      'Watch a short ad to start your next training session.';

  @override
  String get practiceWatchAdForNewSession => 'Watch ad for new training';

  @override
  String get practiceNewSession => 'New training';

  @override
  String get practiceCompleteDesc => 'Fresh club combinations every session.';

  @override
  String get practiceFinishTraining => 'Finish training';

  @override
  String get practiceFinishConfirmTitle => 'Finish training?';

  @override
  String get practiceFinishConfirmBody =>
      'This session ends and uses 1 of your daily training credits.';

  @override
  String get practiceResultTitle => 'Training complete';

  @override
  String get practiceResultEarlyDesc =>
      'You finished early — your score and progress were saved.';

  @override
  String practiceSessionProgress(int current, int limit) {
    return 'Training $current/$limit';
  }

  @override
  String practiceDailyProgress(int used, int limit) {
    return '$used/$limit training sessions used today';
  }

  @override
  String get practiceAdGateHint =>
      'On the free plan, watch a short ad before each new training session.';

  @override
  String get practicePremiumSkipAds =>
      'Premium: up to 10 training sessions per day, no ads between rounds.';

  @override
  String get cancel => 'Cancel';

  @override
  String practiceSessionsRemaining(int count) {
    return '$count training sessions left today';
  }

  @override
  String get premiumFeatureGrid => '4×4 premium grids';

  @override
  String get premiumFeaturePractice => '10 ad-free training sessions per day';

  @override
  String get premiumFeatureStats => 'Advanced stats';

  @override
  String get premiumFeatureThemes => 'Exclusive themes';

  @override
  String get premiumFeatureNoAds => 'No ads';

  @override
  String get premiumActivated => 'Premium activated!';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get premiumPurchaseFailed =>
      'Could not activate Premium. Please try again.';

  @override
  String get premiumVerificationFailed =>
      'Purchase could not be verified. Try Restore Purchases or contact support.';

  @override
  String get premiumPurchaseUnavailable =>
      'Premium is not available in the store yet. Check App Store setup or try again later.';

  @override
  String get premiumDevNotConfigured =>
      'Dev premium is not enabled on the server. Set IAP_SKIP_VERIFY=true in Supabase, or use IAP_ENABLED=true with StoreKit.';

  @override
  String get premiumPurchasePending =>
      'Finishing your pending App Store purchase. Try again in a moment or tap Restore Purchases.';

  @override
  String get restorePurchases => 'Restore purchases';

  @override
  String get completeDailyFirst =>
      'Complete today\'s daily puzzle first to create a challenge.';

  @override
  String get challengeYouWon => 'You won the challenge!';

  @override
  String get challengeYouLost => 'You lost this round.';

  @override
  String get challengeTie => 'It\'s a tie!';

  @override
  String get challengeCreator => 'Creator';

  @override
  String get challengeYou => 'You';

  @override
  String get playerNickname => 'Nickname';

  @override
  String get playerNicknameDesc =>
      'Optional name for challenges and future leaderboards.';

  @override
  String get playerNicknameHint => '3–20 characters';

  @override
  String get playerNicknameSaved => 'Nickname saved';

  @override
  String get playerNicknameTaken => 'This nickname is already taken';

  @override
  String get playerNicknameInvalid =>
      'Use 3–20 letters, numbers, dots, dashes or underscores';

  @override
  String get gridSelectCell => 'SELECT';

  @override
  String get achievements => 'Achievements';

  @override
  String get achievementPoints => 'Achievement Points';

  @override
  String get achievementUnlocked => 'Achievement unlocked!';

  @override
  String get noAchievementsYet => 'Complete puzzles to unlock achievements.';

  @override
  String get dailyMissions => 'Daily Missions';

  @override
  String missionsProgress(int completed, int total) {
    return '$completed/$total done';
  }

  @override
  String get shareResult => 'Share result';

  @override
  String get leaderboard => 'Leaderboard';

  @override
  String get leaderboardEmpty =>
      'No ranked players yet. Complete puzzles to appear on the board.';

  @override
  String get pushNotifications => 'Notifications';

  @override
  String get pushNotificationsOn => 'Streak reminders enabled';

  @override
  String get pushNotificationsOff => 'Notifications off';

  @override
  String get hintAdRequired => 'Watch an ad to unlock this hint.';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get themeDarkGold => 'Gold Stadium';

  @override
  String get themeLightClassic => 'Classic Pitch';

  @override
  String get themeDarkGoldDesc => 'Premium: black pitch with gold accents';

  @override
  String get themeLightClassicDesc =>
      'Premium: warm white pitch with gold accents';

  @override
  String get mythicCelebration => 'MYTHIC!';

  @override
  String get mythicCelebrationBody => 'Ultra-rare pick — elite football IQ.';

  @override
  String get challengeFromAnySession =>
      'Share your last completed puzzle with a friend.';

  @override
  String get challengeNeedSession =>
      'Complete any puzzle first to create a challenge.';

  @override
  String get challengeRematch => 'Rematch — share new link';

  @override
  String get dailyChallengeEasyDesc =>
      'Easier puzzle while you learn — build your streak.';

  @override
  String seasonPoints(int points) {
    return '$points SP';
  }

  @override
  String seasonNextReward(int points, String reward) {
    return 'Next reward at $points SP: $reward';
  }

  @override
  String get clubMastery => 'Club Mastery';

  @override
  String get clubMasteryEmpty => 'Solve intersections to build club mastery.';

  @override
  String get hintCareerClubTaste =>
      'Free weekly taste: reveal another career club';

  @override
  String get practiceGrid4Title => '4×4 Premium Grid';

  @override
  String get practiceGrid4Desc => 'Larger grid with more club combinations.';

  @override
  String get premiumGridRequired => '4×4 grids are a Premium feature.';

  @override
  String get timelineMode => 'Timeline Training';

  @override
  String get timelineModeDesc => 'See career years after each correct answer.';

  @override
  String timelineSheetTitle(String name) {
    return '$name — career timeline';
  }

  @override
  String get timelineEmpty =>
      'No senior career data available for this player.';

  @override
  String get present => 'Present';

  @override
  String get activityFeed => 'Community Activity';

  @override
  String activityDailyCompleted(String name, String score) {
    return '$name completed the daily puzzle ($score pts)';
  }

  @override
  String activityChallengeCompleted(String name) {
    return '$name finished a friend challenge';
  }

  @override
  String activityTimelineCompleted(String name, String score) {
    return '$name finished timeline training ($score pts)';
  }

  @override
  String activityGeneric(String name, String action) {
    return '$name: $action';
  }

  @override
  String get footballFactTitle => 'Did you know?';

  @override
  String get tournament => 'Tournament';

  @override
  String get tournamentDesc => 'Weekly high-score competition';

  @override
  String get tournamentInactive =>
      'No active tournament right now. Check back soon.';

  @override
  String get tournamentEmpty => 'No scores yet — be the first to play!';

  @override
  String tournamentYourRank(int rank) {
    return 'Your rank: #$rank';
  }
}
