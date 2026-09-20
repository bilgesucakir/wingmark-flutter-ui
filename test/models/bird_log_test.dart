import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/bird_log.dart';
import 'package:wingmark_flutter/models/enums.dart';

Map<String, dynamic> _baseJson({
  String? speciesId,
  String? speciesCommonName,
  String? speciesStatus,
  String? customName,
  bool pet = false,
}) {
  return {
    'id': 'log1',
    'userId': 'u1',
    'speciesId': speciesId,
    'speciesCommonName': speciesCommonName,
    'speciesStatus': speciesStatus,
    'pet': pet,
    'customName': customName,
    'lifeStage': 'ADULT',
    'gender': 'MALE',
    'photoUrl': '/uploads/x.jpg',
    'note': 'a note',
    'latitude': 37.42,
    'longitude': -122.08,
    'locationName': 'The Park',
    'observedAt': '2026-09-19T19:34:41.769Z',
    'visibility': 'PRIVATE',
    'createdAt': '2026-09-19T19:34:41.770Z',
  };
}

void main() {
  group('BirdLog.fromJson', () {
    test('parses a fully-populated log', () {
      final log = BirdLog.fromJson(_baseJson(
        speciesId: 'sp1',
        speciesCommonName: 'House Sparrow',
        speciesStatus: 'CONFIDENT',
      ));

      expect(log.id, 'log1');
      expect(log.userId, 'u1');
      expect(log.speciesId, 'sp1');
      expect(log.speciesCommonName, 'House Sparrow');
      expect(log.speciesStatus, SpeciesStatus.confident);
      expect(log.pet, isFalse);
      expect(log.lifeStage, LifeStage.adult);
      expect(log.gender, Gender.male);
      expect(log.photoUrl, '/uploads/x.jpg');
      expect(log.note, 'a note');
      expect(log.latitude, 37.42);
      expect(log.longitude, -122.08);
      expect(log.locationName, 'The Park');
      expect(log.visibility, SightingVisibility.private);
      expect(log.observedAt, DateTime.parse('2026-09-19T19:34:41.769Z'));
    });

    test('handles null speciesId/speciesStatus/customName', () {
      final log = BirdLog.fromJson(_baseJson());
      expect(log.speciesId, isNull);
      expect(log.speciesStatus, isNull);
      expect(log.customName, isNull);
    });

    test('defaults pet to false when missing', () {
      final json = _baseJson()..remove('pet');
      final log = BirdLog.fromJson(json);
      expect(log.pet, isFalse);
    });
  });

  group('BirdLog.displayName', () {
    test('prefers customName over species name', () {
      final log = BirdLog.fromJson(_baseJson(
        speciesCommonName: 'House Sparrow',
        customName: 'logum',
      ));
      expect(log.displayName('en'), 'logum');
    });

    test('falls back to speciesCommonName when no customName', () {
      final log = BirdLog.fromJson(_baseJson(speciesCommonName: 'House Sparrow'));
      expect(log.displayName('en'), 'House Sparrow');
    });

    test('falls back to a locale-aware placeholder when neither is set', () {
      final log = BirdLog.fromJson(_baseJson());
      expect(log.displayName('en'), 'Not sure yet');
      expect(log.displayName('tr'), 'Henüz emin değilim');
    });

    test('blank customName is treated as unset', () {
      final log = BirdLog.fromJson(_baseJson(
        speciesCommonName: 'House Sparrow',
        customName: '   ',
      ));
      expect(log.displayName('en'), 'House Sparrow');
    });
  });

  group('BirdLogRequest.toJson', () {
    test('serializes every field with the correct backend keys', () {
      final request = BirdLogRequest(
        speciesId: 'sp1',
        speciesStatus: SpeciesStatus.guess,
        pet: true,
        customName: 'Bud',
        lifeStage: LifeStage.baby,
        gender: Gender.female,
        photoUrl: '/uploads/y.jpg',
        note: 'note text',
        latitude: 1.5,
        longitude: -2.5,
        locationName: 'Backyard',
      );

      expect(request.toJson(), {
        'speciesId': 'sp1',
        'speciesStatus': 'GUESS',
        'pet': true,
        'customName': 'Bud',
        'lifeStage': 'BABY',
        'gender': 'FEMALE',
        'photoUrl': '/uploads/y.jpg',
        'note': 'note text',
        'latitude': 1.5,
        'longitude': -2.5,
        'locationName': 'Backyard',
      });
    });

    test('pet defaults to false and optional fields default to null', () {
      final request = BirdLogRequest(
        lifeStage: LifeStage.unknown,
        gender: Gender.unknown,
        latitude: 0,
        longitude: 0,
      );

      final json = request.toJson();
      expect(json['pet'], isFalse);
      expect(json['speciesId'], isNull);
      expect(json['speciesStatus'], isNull);
      expect(json['customName'], isNull);
      expect(json['photoUrl'], isNull);
      expect(json['note'], isNull);
      expect(json['locationName'], isNull);
    });
  });
}
