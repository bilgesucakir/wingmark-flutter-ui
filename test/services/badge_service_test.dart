import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/services/badge_service.dart';

import 'fake_api_client.dart';

void main() {
  late FakeApiClient client;
  late BadgeService service;

  setUp(() {
    client = FakeApiClient();
    service = BadgeService(client);
  });

  test('getCatalog GETs /api/badges/catalog without auth', () async {
    client.response = [
      {
        'id': 'b1',
        'name': {'en': 'First Sighting'},
        'description': {'en': 'Log your first bird'},
        'icon': 'trophy.fill',
        'criteriaType': 'TOTAL_LOGS',
        'criteriaValue': 1,
        'tier': 'BRONZE',
      }
    ];

    final catalog = await service.getCatalog();

    expect(client.lastMethod, 'GET');
    expect(client.lastPath, '/api/badges/catalog');
    expect(client.lastAuth, isFalse);
    expect(catalog, hasLength(1));
    expect(catalog.first.id, 'b1');
  });

  test('getForUser GETs /api/badges/user/{id} with auth', () async {
    client.response = [
      {
        'badgeId': 'b1',
        'badgeName': 'First Sighting',
        'badgeIcon': 'trophy.fill',
        'earned': true,
        'earnedAt': '2026-01-01T00:00:00Z',
        'progress': 1,
        'targetValue': 1,
      }
    ];

    final badges = await service.getForUser('u1');

    expect(client.lastPath, '/api/badges/user/u1');
    expect(client.lastAuth, isNot(false));
    expect(badges, hasLength(1));
    expect(badges.first.earned, isTrue);
  });
}
