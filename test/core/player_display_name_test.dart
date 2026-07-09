import 'package:crossball/core/utils/player_display_name.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolvePlayerDisplayLabel', () {
    test('uses nickname when set', () {
      expect(
        resolvePlayerDisplayLabel(displayName: 'MessiFan', userUuid: 'abc-123'),
        'MessiFan',
      );
    });

    test('truncates long nicknames to 20 chars', () {
      expect(
        resolvePlayerDisplayLabel(
          displayName: 'abcdefghijklmnopqrstuvwxyz',
          userUuid: 'abc-123',
        ),
        'abcdefghijklmnopqrst',
      );
    });

    test('falls back to Player #UUID prefix when nickname missing', () {
      expect(
        resolvePlayerDisplayLabel(
          displayName: null,
          userUuid: '68a1b2c3-d4e5-6789-abcd-ef0123456789',
        ),
        'Player #68A1',
      );
    });

    test('treats generic Player as anonymous', () {
      expect(
        resolvePlayerDisplayLabel(
          displayName: 'Player',
          userUuid: '68a1b2c3-d4e5-6789-abcd-ef0123456789',
        ),
        'Player #68A1',
      );
    });

    test('treats blank nickname as anonymous', () {
      expect(
        resolvePlayerDisplayLabel(
          displayName: '   ',
          userUuid: 'deadbeef-0000-4000-8000-000000000001',
        ),
        'Player #DEAD',
      );
    });
  });

  group('playerAvatarInitial', () {
    test('uses first letter of nickname', () {
      expect(playerAvatarInitial('MessiFan'), 'M');
    });

    test('uses P for anonymous label', () {
      expect(playerAvatarInitial('Player #68A1'), 'P');
    });
  });
}
