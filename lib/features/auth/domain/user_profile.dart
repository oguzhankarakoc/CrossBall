import 'package:equatable/equatable.dart';

import '../../../core/utils/player_display_name.dart';

/// Anonymous user profile (no mandatory login).
class UserProfile extends Equatable {
  const UserProfile({
    required this.userUuid,
    this.displayName,
    this.isPremium = false,
    this.onboardingComplete = false,
    this.pushOptIn = true,
  });

  final String userUuid;
  final String? displayName;
  final bool isPremium;
  final bool onboardingComplete;
  final bool pushOptIn;

  /// Nickname or anonymous fallback (e.g. Player #A1B2).
  String get displayLabel => resolvePlayerDisplayLabel(
        displayName: displayName,
        userUuid: userUuid,
      );

  UserProfile copyWith({
    String? userUuid,
    String? displayName,
    bool? isPremium,
    bool? onboardingComplete,
    bool? pushOptIn,
    bool clearDisplayName = false,
  }) {
    return UserProfile(
      userUuid: userUuid ?? this.userUuid,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      isPremium: isPremium ?? this.isPremium,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      pushOptIn: pushOptIn ?? this.pushOptIn,
    );
  }

  @override
  List<Object?> get props => [userUuid, displayName, isPremium, onboardingComplete, pushOptIn];
}
