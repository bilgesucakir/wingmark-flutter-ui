import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/services/species_service.dart';

import 'fake_api_client.dart';

Map<String, dynamic> _speciesJson(String id) => {
      'id': id,
      'commonName': {'en': 'House Sparrow'},
      'scientificName': 'Passer domesticus',
      'images': <dynamic>[],
    };

void main() {
  late FakeApiClient client;
  late SpeciesService service;

  setUp(() {
    client = FakeApiClient();
    service = SpeciesService(client);
  });

  test('search GETs /api/species without auth, always including page/size',
      () async {
    client.response = {
      'content': [_speciesJson('sp1')],
      'page': {'totalElements': 1, 'totalPages': 1, 'number': 0, 'size': 20},
    };

    final page = await service.search();

    expect(client.lastMethod, 'GET');
    expect(client.lastPath, '/api/species');
    expect(client.lastAuth, isFalse);
    expect(client.lastQuery, {'page': '0', 'size': '20'});
    expect(page.content, hasLength(1));
  });

  test('search omits the search param when query is null/empty, includes it otherwise',
      () async {
    client.response = {
      'content': <dynamic>[],
      'page': {'totalElements': 0, 'totalPages': 1, 'number': 0, 'size': 20},
    };

    await service.search(query: '');
    expect(client.lastQuery!.containsKey('search'), isFalse);

    await service.search(query: 'sparrow', page: 2, size: 10);
    expect(client.lastQuery, {'search': 'sparrow', 'page': '2', 'size': '10'});
  });

  test('getById GETs /api/species/{id} without auth', () async {
    client.response = _speciesJson('sp1');

    final species = await service.getById('sp1');

    expect(client.lastPath, '/api/species/sp1');
    expect(client.lastAuth, isFalse);
    expect(species.id, 'sp1');
  });

  test('getSounds GETs /api/species/{id}/sound without auth and parses the list',
      () async {
    client.response = [
      {
        'id': 1,
        'recordingUrl': 'https://xeno-canto.org/1.mp3',
      }
    ];

    final sounds = await service.getSounds('sp1');

    expect(client.lastPath, '/api/species/sp1/sound');
    expect(client.lastAuth, isFalse);
    expect(sounds, hasLength(1));
    expect(sounds.first.recordingUrl, 'https://xeno-canto.org/1.mp3');
  });
}
