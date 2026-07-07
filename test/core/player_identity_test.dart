import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/player_identity.dart';

void main() {
  group('playerIdentityKey', () {
    test('groups abbreviated and full names', () {
      expect(
        playerIdentityKey('Z. Ibrahimović'),
        playerIdentityKey('Zlatan Ibrahimović'),
      );
    });

    test('uses significant surname for Portuguese names', () {
      expect(
        playerIdentityKey('Cristiano Ronaldo dos Santos Aveiro'),
        'aveiro|c',
      );
      expect(playerIdentityKey('Cristiano Ronaldo'), 'ronaldo|c');
    });
  });
}
