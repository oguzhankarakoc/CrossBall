import 'package:crossball/core/constants/liveops_constants.dart';
import 'package:crossball/features/liveops/domain/liveops_event_extensions.dart';
import 'package:crossball/features/liveops/domain/liveops_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('locked liveops event slugs include themed placeholders', () {
    expect(LiveOpsConstants.isEventLocked('champions_league_week'), isTrue);
    expect(LiveOpsConstants.isEventLocked('matchday-weekend'), isTrue);
    expect(LiveOpsConstants.isEventLocked('tournament_week'), isFalse);
  });

  test('LiveOpsEvent extension marks locked slugs', () {
    const event = LiveOpsEvent(
      slug: 'champions_league_week',
      eventType: 'limited',
      title: 'Champions League Week',
      description: 'Test',
    );
    expect(event.isLocked, isTrue);
  });
}
