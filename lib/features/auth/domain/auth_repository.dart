import 'user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile> getOrCreateAnonymousUser();
  Future<void> setOnboardingComplete(bool value);
  Future<bool> isOnboardingComplete();
}
