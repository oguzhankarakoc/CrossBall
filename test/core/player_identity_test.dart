import 'package:flutter_test/flutter_test.dart';

import 'package:crossball/core/utils/player_identity.dart';

void main() {
  group('playerIdentityKey', () {
    test('groups abbreviated and full names', () {
      expect(
        playerIdentityKey('Z. Ibrahimović'),
        playerIdentityKey('Zlatan Ibrahimović'),
      );
      expect(
        playerIdentityKey('Z.Ibrahimovic'),
        playerIdentityKey('Zlatan Ibrahimovic'),
      );
    });

    test('uses significant surname for Portuguese names', () {
      expect(
        playerIdentityKey('Cristiano Ronaldo dos Santos Aveiro'),
        'aveiro|c',
      );
      expect(playerIdentityKey('Cristiano Ronaldo'), 'ronaldo|c');
    });

    test('playerIdentityKeys merges short and full legal names', () {
      final shortKeys = playerIdentityKeys('Cristiano Ronaldo');
      final fullKeys = playerIdentityKeys('Cristiano Ronaldo dos Santos Aveiro');
      expect(shortKeys.any(fullKeys.contains), isTrue);

      final morataShort = playerIdentityKeys('Álvaro Morata');
      final morataFull = playerIdentityKeys('Álvaro Borja Morata Martín');
      expect(morataShort.any(morataFull.contains), isTrue);

      final coutinhoShort = playerIdentityKeys('Philippe Coutinho');
      final coutinhoFull = playerIdentityKeys('Philippe Coutinho Correia');
      expect(coutinhoShort.any(coutinhoFull.contains), isTrue);
    });
  });
}
