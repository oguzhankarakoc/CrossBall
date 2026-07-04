import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/player_progression.dart';

/// New achievements detected after a completed session; UI clears after showing.
final newlyUnlockedAchievementsProvider =
    StateProvider<List<PlayerAchievement>>((ref) => const []);
