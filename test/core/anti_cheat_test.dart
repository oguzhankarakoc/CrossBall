import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/anti_cheat_tracker.dart';
import 'package:crossball/core/constants/game_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AntiCheatTracker metadata includes required fields', () {
    final tracker = AntiCheatTracker(gridSize: GameConstants.freeGridSize);
    tracker.recordInteraction();
    final metadata = tracker.toMetadata();
    expect(metadata.containsKey('total_duration_ms'), isTrue);
    expect(metadata['is_suspicious'], isFalse);
    tracker.dispose();
  });

  test('AntiCheatTracker evaluate runs without error', () {
    final tracker = AntiCheatTracker(gridSize: GameConstants.freeGridSize);
    tracker.recordInteraction();
    tracker.evaluate();
    tracker.dispose();
  });
}
