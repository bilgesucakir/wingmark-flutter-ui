import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/bird_log.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/services/bird_log_service.dart';

import 'fake_api_client.dart';

Map<String, dynamic> _logJson({String id = 'log1'}) => {
      'id': id,
      'userId': 'u1',
      'speciesId': null,
      'speciesCommonName': null,
      'speciesStatus': null,
      'pet': false,
      'customName': null,
      'lifeStage': 'ADULT',
      'gender': 'UNKNOWN',
      'photoUrl': null,
      'note': null,
      'latitude': 1.0,
      'longitude': 2.0,
      'locationName': null,
      'observedAt': '2026-01-01T00:00:00Z',
      'visibility': 'PRIVATE',
      'createdAt': '2026-01-01T00:00:00Z',
    };

void main() {
  late FakeApiClient client;
  late BirdLogService service;

  setUp(() {
    client = FakeApiClient();
    service = BirdLogService(client);
  });

  test('getForUser GETs /api/bird-logs/user/{id} and parses a list', () async {
    client.response = [_logJson(id: 'a'), _logJson(id: 'b')];

    final logs = await service.getForUser('u1');

    expect(client.lastMethod, 'GET');
    expect(client.lastPath, '/api/bird-logs/user/u1');
    expect(logs.map((l) => l.id), ['a', 'b']);
  });

  test('getInBounds sends the bounding box as query params', () async {
    client.response = <dynamic>[];

    await service.getInBounds(minLat: 1, maxLat: 2, minLng: 3, maxLng: 4);

    expect(client.lastPath, '/api/bird-logs/location');
    expect(client.lastQuery, {
      'minLat': '1.0',
      'maxLat': '2.0',
      'minLng': '3.0',
      'maxLng': '4.0',
    });
  });

  test('getById GETs /api/bird-logs/{id}', () async {
    client.response = _logJson(id: 'x');

    final log = await service.getById('x');

    expect(client.lastPath, '/api/bird-logs/x');
    expect(log.id, 'x');
  });

  test('create POSTs the serialized request to /api/bird-logs', () async {
    client.response = _logJson(id: 'new');
    final request = BirdLogRequest(
      lifeStage: LifeStage.adult,
      gender: Gender.male,
      latitude: 1,
      longitude: 2,
    );

    final result = await service.create(request);

    expect(client.lastMethod, 'POST');
    expect(client.lastPath, '/api/bird-logs');
    expect(client.lastBody, request.toJson());
    expect(result.id, 'new');
  });

  test('update PUTs the serialized request to /api/bird-logs/{id}', () async {
    client.response = _logJson(id: 'log1');
    final request = BirdLogRequest(
      lifeStage: LifeStage.baby,
      gender: Gender.female,
      latitude: 1,
      longitude: 2,
    );

    await service.update('log1', request);

    expect(client.lastMethod, 'PUT');
    expect(client.lastPath, '/api/bird-logs/log1');
    expect(client.lastBody, request.toJson());
  });

  test('delete DELETEs /api/bird-logs/{id}', () async {
    client.response = null;
    await service.delete('log1');

    expect(client.lastMethod, 'DELETE');
    expect(client.lastPath, '/api/bird-logs/log1');
  });
}
