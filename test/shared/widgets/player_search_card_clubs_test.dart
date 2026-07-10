import 'package:crossball/shared/widgets/player_search_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('prioritizeClubsForCell', () {
    test('puts puzzle clubs first for long careers', () {
      final ordered = prioritizeClubsForCell(
        const [
          'Ajax',
          'Juventus',
          'Inter',
          'Barcelona',
          'Milan',
          'PSG',
          'Man United',
        ],
        {'Barcelona', 'PSG'},
      );

      expect(ordered.take(2), ['Barcelona', 'PSG']);
      expect(ordered, containsAll(['Ajax', 'Juventus', 'Inter', 'Milan', 'Man United']));
    });

    test('matches short codes to full club names', () {
      final ordered = prioritizeClubsForCell(
        const ['Benfica', 'Arsenal', 'Sporting'],
        {'ARS', 'SCP', 'Arsenal', 'Sporting'},
      );

      expect(ordered.take(2).toSet(), {'Arsenal', 'Sporting'});
    });
  });
}
