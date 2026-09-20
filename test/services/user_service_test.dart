import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/models/user_settings.dart';
import 'package:wingmark_flutter/services/user_service.dart';

import 'fake_api_client.dart';

Map<String, dynamic> _userJson() => {
      'id': 'u1',
      'email': 'a@b.com',
      'username': 'bilgesu',
      'firstName': 'Bilgesu',
      'lastName': 'Cakir',
      'role': 'USER',
      'emailVerified': true,
      'createdAt': '2026-01-01T00:00:00Z',
    };

void main() {
  late FakeApiClient client;
  late UserService service;

  setUp(() {
    client = FakeApiClient();
    service = UserService(client);
  });

  test('getProfile GETs /api/users/{id} and parses the profile', () async {
    client.response = _userJson();

    final profile = await service.getProfile('u1');

    expect(client.lastMethod, 'GET');
    expect(client.lastPath, '/api/users/u1');
    expect(profile.username, 'bilgesu');
  });

  test('updateProfile PUTs the given fields to /api/users/{id}', () async {
    client.response = _userJson();

    await service.updateProfile(
      'u1',
      firstName: 'New',
      lastName: 'Name',
      favoriteSpeciesId: 'sp1',
    );

    expect(client.lastMethod, 'PUT');
    expect(client.lastPath, '/api/users/u1');
    expect(client.lastBody, {
      'firstName': 'New',
      'lastName': 'Name',
      'profilePicture': null,
      'favoriteSpeciesId': 'sp1',
    });
  });

  test('getSettings GETs /api/users/{id}/settings and parses it', () async {
    client.response = {'unitPreference': 'IMPERIAL', 'locale': 'en'};

    final settings = await service.getSettings('u1');

    expect(client.lastPath, '/api/users/u1/settings');
    expect(settings.unitPreference, UnitPreference.imperial);
  });

  test('updateSettings PUTs the serialized settings', () async {
    client.response = {'unitPreference': 'METRIC', 'locale': 'tr'};

    await service.updateSettings(
        'u1', UserSettings(unitPreference: UnitPreference.metric, locale: 'tr'));

    expect(client.lastMethod, 'PUT');
    expect(client.lastPath, '/api/users/u1/settings');
    expect(client.lastBody, {'unitPreference': 'METRIC', 'locale': 'tr'});
  });
}
