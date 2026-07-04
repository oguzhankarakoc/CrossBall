import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_providers.dart';
import 'app_router.dart';

/// Stable [GoRouter] instance — only recreated when onboarding state changes,
/// not on theme/locale rebuilds (PERF-02).
final appRouterProvider = Provider<GoRouter>((ref) {
  final onboardingComplete = ref.watch(onboardingCompleteProvider).valueOrNull ?? false;
  return createAppRouter(onboardingComplete: onboardingComplete);
});
