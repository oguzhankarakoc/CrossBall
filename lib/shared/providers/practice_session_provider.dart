import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/game_constants.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/practice/data/practice_quota_api.dart';

/// Server-synced daily practice quota with rewarded-ad unlock for free users.
class PracticeSessionState {
  const PracticeSessionState({
    required this.dateKey,
    required this.completedToday,
    required this.dailyLimit,
    required this.isPremium,
    this.adUnlockGranted = false,
    this.isSyncing = false,
    this.syncError,
  });

  final String dateKey;
  final int completedToday;
  final int dailyLimit;
  final bool isPremium;
  final bool adUnlockGranted;
  final bool isSyncing;
  final String? syncError;

  int get remaining => (dailyLimit - completedToday).clamp(0, dailyLimit);

  bool get hasReachedLimit => completedToday >= dailyLimit;

  /// Free users need a rewarded ad before sessions 2..N (first session of the day is free).
  bool get needsRewardedAdForNextSession =>
      !isPremium && completedToday > 0 && !adUnlockGranted && !hasReachedLimit;

  bool get canStartSession =>
      !hasReachedLimit && (!needsRewardedAdForNextSession || adUnlockGranted);

  PracticeSessionState copyWith({
    String? dateKey,
    int? completedToday,
    int? dailyLimit,
    bool? isPremium,
    bool? adUnlockGranted,
    bool? isSyncing,
    String? syncError,
    bool clearSyncError = false,
  }) =>
      PracticeSessionState(
        dateKey: dateKey ?? this.dateKey,
        completedToday: completedToday ?? this.completedToday,
        dailyLimit: dailyLimit ?? this.dailyLimit,
        isPremium: isPremium ?? this.isPremium,
        adUnlockGranted: adUnlockGranted ?? this.adUnlockGranted,
        isSyncing: isSyncing ?? this.isSyncing,
        syncError: clearSyncError ? null : (syncError ?? this.syncError),
      );

  factory PracticeSessionState.fromQuotaJson(Map<String, dynamic> json) {
    return PracticeSessionState(
      dateKey: json['usage_date'] as String? ?? '',
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? GameConstants.freePracticeDailyLimit,
      isPremium: json['is_premium'] as bool? ?? false,
      adUnlockGranted: json['ad_unlock_granted'] as bool? ?? false,
    );
  }

  static const initial = PracticeSessionState(
    dateKey: '',
    completedToday: 0,
    dailyLimit: GameConstants.freePracticeDailyLimit,
    isPremium: false,
  );
}

final practiceQuotaApiProvider = Provider<PracticeQuotaApi>((ref) => PracticeQuotaApi());

final practiceSessionProvider =
    StateNotifierProvider<PracticeSessionNotifier, PracticeSessionState>(
  (ref) => PracticeSessionNotifier(ref),
);

class PracticeSessionNotifier extends StateNotifier<PracticeSessionState> {
  PracticeSessionNotifier(this._ref) : super(PracticeSessionState.initial);

  final Ref _ref;

  PracticeQuotaApi get _api => _ref.read(practiceQuotaApiProvider);

  Future<void> syncFromServer(String userUuid) async {
    state = state.copyWith(isSyncing: true, clearSyncError: true);
    try {
      final quota = await _api.fetchQuota(userUuid);
      state = PracticeSessionState.fromQuotaJson(quota);
    } catch (e) {
      state = state.copyWith(
        isSyncing: false,
        syncError: e.toString(),
      );
    }
  }

  Future<void> grantAdUnlock(String userUuid) async {
    final quota = await _api.grantAdUnlock(userUuid);
    state = PracticeSessionState.fromQuotaJson(quota);
  }

  /// Optimistic bump until [complete-session] flushes; reconciled on next sync.
  Future<void> onPracticeSessionCompleted(String userUuid) async {
    state = state.copyWith(
      completedToday: state.completedToday + 1,
      adUnlockGranted: false,
    );
    await syncFromServer(userUuid);
  }

  Future<void> syncForCurrentUser() async {
    final profile = await _ref.read(userProfileProvider.future);
    await syncFromServer(profile.userUuid);
  }
}
