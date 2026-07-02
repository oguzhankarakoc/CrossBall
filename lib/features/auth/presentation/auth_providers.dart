import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository_impl.dart';
import '../domain/auth_repository.dart';
import '../domain/user_profile.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.watch(authRepositoryProvider).getOrCreateAnonymousUser();
});

final onboardingCompleteProvider = FutureProvider<bool>((ref) async {
  return ref.watch(authRepositoryProvider).isOnboardingComplete();
});
