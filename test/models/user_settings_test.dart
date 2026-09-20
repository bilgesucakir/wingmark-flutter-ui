import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('fromJson parses unitPreference and locale', () {
      final settings = UserSettings.fromJson({
        'unitPreference': 'IMPERIAL',
        'locale': 'tr',
      });
      expect(settings.unitPreference, UnitPreference.imperial);
      expect(settings.locale, 'tr');
    });

    test('fromJson defaults to metric when missing', () {
      final settings = UserSettings.fromJson({});
      expect(settings.unitPreference, UnitPreference.metric);
      expect(settings.locale, isNull);
    });

    test('toJson serializes the wire enum value', () {
      final settings = UserSettings(
        unitPreference: UnitPreference.imperial,
        locale: 'en',
      );
      expect(settings.toJson(), {
        'unitPreference': 'IMPERIAL',
        'locale': 'en',
      });
    });
  });
}
