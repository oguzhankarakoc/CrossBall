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
  String get dailyAlreadyCompletedTitle => 'Today\'s Puzzle Complete';

  @override
  String get dailyAlreadyCompletedBody =>
      'You\'ve already finished today\'s daily puzzle. Come back after the next refresh for a new grid.';

  @override
  String dailyAlreadyCompletedNextPuzzle(String localTime, String countdown) {
    return 'Next puzzle around $localTime · $countdown to go';
  }

  @override
  String get dailyAlreadyCompletedBadge => 'Completed';

  @override
  String get dailyAlreadyCompletedHomeSubtitle =>
      'You finished today\'s puzzle. A new grid arrives tomorrow.';

  @override
  String get dailyAlreadyCompletedViewSummary => 'View Summary';

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
  String get onboarding1Body =>
      'Tap any empty cell on the 3×3 grid to open player search.';

  @override
  String get onboarding2Title => 'Connect both clubs';

  @override
  String get onboarding2Body =>
      'The answer must have played for the row club and the column club.';

  @override
  String get onboarding3Title => 'Rare picks score higher';

  @override
  String get onboarding3Body =>
      'Obscure players beat obvious names — build your streak every day.';

  @override
  String get firstPuzzleCoachTitle => 'Quick tip';

  @override
  String get firstPuzzleCoachSubtitle =>
      'You’re on today’s grid. Here’s how a cell works.';

  @override
  String get firstPuzzleCoachStep1Title => 'Tap a cell';

  @override
  String get firstPuzzleCoachStep1Body =>
      'Each square sits between one row club and one column club.';

  @override
  String get firstPuzzleCoachStep2Title => 'Name the link';

  @override
  String get firstPuzzleCoachStep2Body =>
      'Search a player who appeared for both clubs.';

  @override
  String get firstPuzzleCoachStep3Title => 'Chase rarity';

  @override
  String get firstPuzzleCoachStep3Body =>
      'Less common answers score more. Finish the grid for your streak.';

  @override
  String get firstPuzzleCoachCta => 'Got it — let’s play';

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
  String get homeWeeklyScoreLabel => 'This week';

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
  String get rarityBreakdownEmpty =>
      'Your rarity mix appears after competitive puzzles (Daily & Challenges).';

  @override
  String get rarityBreakdownHint =>
      'Obscure picks push rare tiers up — that\'s how you climb.';

  @override
  String get statsCareerTitle => 'Career';

  @override
  String get statsActivityTitle => 'Activity';

  @override
  String get statsProgressUnavailable =>
      'Couldn\'t load your level. Pull to refresh.';

  @override
  String get createChallenge => 'Create Challenge';

  @override
  String get createAndShareChallenge => 'Create & Share Challenge';

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
  String get hintCareerClub => 'Watch ad for career club hint';

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
  String get hintCareerClubPremium => 'Reveal career club hint';

  @override
  String get hintChipNationality => 'Nationality';

  @override
  String get hintChipPosition => 'Position';

  @override
  String get hintChipFirstLetter => 'First letter';

  @override
  String get hintChipStatus => 'Status';

  @override
  String get hintChipClub => 'Club';

  @override
  String get hintValueUnknown => 'Unknown';

  @override
  String get hintStatusActive => 'Active';

  @override
  String get hintStatusRetired => 'Retired';

  @override
  String get hintLimitReached =>
      'All hints for this cell are already revealed.';

  @override
  String get hintUnavailable => 'Hint unavailable right now. Please try again.';

  @override
  String get hintPossibleAnswerLabel => 'Possible answer';

  @override
  String get hintPossibleAnswerNote =>
      'Hints describe one possible answer — other correct players still count.';

  @override
  String get searchCompetitiveEmpty =>
      'Type a player name to search. Use the hint button above for help.';

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
  String get adUnavailable =>
      'Ad isn’t available right now. Try again in a moment.';

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
  String get missionDailyPlayOneTitle => 'Daily Player';

  @override
  String get missionDailyPlayOneDesc => 'Complete today\'s daily puzzle';

  @override
  String get missionDailyNoHintsTitle => 'No Help Needed';

  @override
  String get missionDailyNoHintsDesc => 'Finish a puzzle without using hints';

  @override
  String get missionDailyLegendaryTitle => 'Legend Hunter';

  @override
  String get missionDailyLegendaryDesc =>
      'Find one legendary or better answer today';

  @override
  String get missionWeeklyHard3Title => 'Hard Mode';

  @override
  String get missionWeeklyHard3Desc => 'Complete 3 hard puzzles this week';

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
  String get answerCellNotFound =>
      'This cell cannot be validated right now. Refresh the puzzle and try again.';

  @override
  String get errorNetwork => 'Network error. Check your connection.';

  @override
  String get errorOffline =>
      'You\'re offline. Check your connection and try again.';

  @override
  String get errorTimeout => 'The request took too long. Please try again.';

  @override
  String get errorServer =>
      'Our servers are having trouble. Please try again shortly.';

  @override
  String get errorAuth => 'Your session expired. Restart the app to continue.';

  @override
  String get errorValidation => 'Please check your input and try again.';

  @override
  String get errorNotFound => 'We couldn\'t find what you\'re looking for.';

  @override
  String get bootLoading => 'Loading CrossBall…';

  @override
  String get bootFailed => 'CrossBall couldn\'t start. Please try again.';

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
  String get challengeShareFailed =>
      'Could not create the challenge. Please try again.';

  @override
  String get weeklyDailyScores => 'This Week (Daily Scores)';

  @override
  String get noDailyScore => '—';

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
  String get quickGridMode => 'Quick Grid';

  @override
  String get quickGridModeDesc =>
      'Same CrossBall grid — pick from 5 players. 120 seconds. No typing.';

  @override
  String get quickGridPickTitle => 'Pick the player';

  @override
  String get quickGridChoicesError => 'Couldn\'t load choices. Try again.';

  @override
  String get quickGridEliminateAd => 'Watch ad — remove 1 wrong';

  @override
  String get quickGridEliminateFree => 'Remove 1 wrong answer';

  @override
  String get matchGridMode => 'Match Grid';

  @override
  String get matchGridModeDesc =>
      'Drag the correct players onto the club intersections. 120 seconds.';

  @override
  String get matchGridTrayHint =>
      'Long-press a player, then drop them on the matching cell.';

  @override
  String get matchGridTrayEmpty => 'All players placed — nice work!';

  @override
  String get matchGridBankError =>
      'Couldn\'t load Match Grid players. Check your connection and retry.';

  @override
  String get practiceUnlimitedHint =>
      'Unlimited training. Watch a short ad to start each new session.';

  @override
  String practiceSessionsPlayedToday(int count) {
    return '$count training sessions today';
  }

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
  String activityDailyCompletedAction(String score) {
    return 'Completed the daily puzzle ($score pts)';
  }

  @override
  String get activityChallengeCompletedAction => 'Finished a friend challenge';

  @override
  String activityTimelineCompletedAction(String score) {
    return 'Finished timeline training ($score pts)';
  }

  @override
  String activityGenericAction(String action) {
    return '$action';
  }

  @override
  String get footballFactTitle => 'Did you know?';

  @override
  String get footballFactTip1 =>
      'The rarest names at a club crossing often score highest — bold picks beat obvious ones.';

  @override
  String get footballFactTip2 =>
      'Football IQ is not just knowing stars; it is remembering the hidden career paths.';

  @override
  String get footballFactTip3 =>
      'Trust your memory, not the badges. Uncommon answers unlock the leaderboard.';

  @override
  String get footballFactTip4 =>
      'Popular names rarely give easy points — the deep cuts shine brightest.';

  @override
  String get footballFactTip5 =>
      'Every cell hides a football story. The right player is the right intersection.';

  @override
  String get footballFactTimeline1 =>
      'In timeline mode, the right year unlocks the right player — read the career order carefully.';

  @override
  String get footballFactTimeline2 =>
      'Watch transfer years closely; one season can change the whole grid.';

  @override
  String get footballFactTimeline3 =>
      'Chronology rewards quick recall — line up club spells in your head.';

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

  @override
  String get leaderboardWeeklyTab => 'This Week';

  @override
  String get leaderboardRatingTab => 'Rating';

  @override
  String get weeklyLeaderboardTitle => 'Weekly Daily Challenge';

  @override
  String get weeklyLeaderboardEmpty =>
      'No daily scores this week yet. Complete today\'s puzzle to join the board.';

  @override
  String get weekResetsMonday =>
      'Scores reset every Monday 00:00 UTC. Tie-break: fewer hints, then fewer mistakes.';

  @override
  String daysPlayedCount(int count) {
    return '$count days played';
  }

  @override
  String weeklyLeaderboardPenalties(int hints, int mistakes) {
    return 'Hints $hints · Mistakes $mistakes';
  }

  @override
  String get communityHubTitle => 'Community';

  @override
  String get communityHubSubtitle =>
      'Daily missions, shared goals, and what players are doing right now.';

  @override
  String get communityHubOpen => 'Open';

  @override
  String get communityHubTeaserEmpty =>
      'Missions, community goals & player activity';

  @override
  String communityHubTeaserMissionLine(int completed, int total) {
    return '$completed/$total missions';
  }

  @override
  String communityHubTeaserGoalLine(int count) {
    return '$count community goals';
  }

  @override
  String communityHubTeaserActivityLine(int count) {
    return '$count recent plays';
  }

  @override
  String get communityGoalsEmpty =>
      'No active community goals right now. Check back during special events.';

  @override
  String get communityMissionsEmpty =>
      'No daily missions available yet. Play a puzzle to unlock today\'s tasks.';

  @override
  String get activityFeedEmpty =>
      'No recent activity from friends yet. Complete daily puzzles to appear on the feed.';

  @override
  String get moreGameModes => 'More Modes';

  @override
  String get comingModesTitle => 'Coming soon';

  @override
  String get comingModesSubtitle =>
      'New grid axes and event modes are on the way.';

  @override
  String get comingModesLearnMore => 'Learn more';

  @override
  String get modeWorldXiTitle => 'World XI';

  @override
  String get modeWorldXiBody =>
      'Same grid, new axes — find players who fit both the club and the country.';

  @override
  String get modeThemedWeekTitle => 'Themed Week';

  @override
  String get modeThemedWeekBody =>
      'Calendar-tied club grids for big football moments.';

  @override
  String get modeBlitzTitle => 'Blitz';

  @override
  String get modeBlitzBody =>
      'Faster sessions with a tighter clock — hardcore week energy.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }
}
