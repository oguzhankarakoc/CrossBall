import 'package:equatable/equatable.dart';

/// Anonymous user profile (no mandatory login).
class UserProfile extends Equatable {
  const UserProfile({
    required this.userUuid,
    this.isPremium = false,
    this.onboardingComplete = false,
  });

  final String userUuid;
  final bool isPremium;
  final bool onboardingComplete;

  UserProfile copyWith({
    String? userUuid,
    bool? isPremium,
    bool? onboardingComplete,
  }) {
    return UserProfile(
      userUuid: userUuid ?? this.userUuid,
      isPremium: isPremium ?? this.isPremium,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }

  @override
  List<Object?> get props => [userUuid, isPremium, onboardingComplete];
}
