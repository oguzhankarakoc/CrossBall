import 'package:crossball/core/club_identity/club_identity.dart';
import 'package:crossball/core/club_identity/club_identity_registry.dart';
import 'package:crossball/features/puzzle/domain/puzzle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Barcelona resolves to abstract stripes identity', () {
    const club = Club(
      id: '1',
      name: 'FC Barcelona',
      slug: 'barcelona',
      badgePrimaryColor: '#A50044',
      badgeSecondaryColor: '#004D98',
      badgeInitials: 'BAR',
    );
    final identity = ClubIdentityRegistry.resolve(club);
    expect(identity.symbolType, ClubSymbolType.abstractStripes);
    expect(identity.shortCode, 'BAR');
  });

  test('Chelsea resolves to abstract lion-inspired identity', () {
    const club = Club(
      id: '2',
      name: 'Chelsea FC',
      slug: 'chelsea',
    );
    final identity = ClubIdentityRegistry.resolve(club);
    expect(identity.symbolType, ClubSymbolType.abstractLion);
    expect(identity.shortCode, 'CHE');
  });

  test('Unknown club gets deterministic fallback', () {
    const club = Club(id: '3', name: 'Test FC', slug: 'test-fc-unknown');
    final a = ClubIdentityRegistry.resolve(club);
    final b = ClubIdentityRegistry.resolve(club);
    expect(a.shortCode, isNotEmpty);
    expect(a.symbolType, isNotNull);
    expect(a.primaryColor, b.primaryColor);
  });
}
