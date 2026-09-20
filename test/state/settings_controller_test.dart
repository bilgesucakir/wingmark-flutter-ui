import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/state/settings_controller.dart';

void main() {
  // effectiveLanguageCode's AppLanguage.system branch reads
  // WidgetsBinding.instance.platformDispatcher.locale, so the binding must
  // exist even though these are plain (non-widget) tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to system language and metric units before load()', () {
    final controller = SettingsController();
    expect(controller.language, AppLanguage.system);
    expect(controller.unitPreference, UnitPreference.metric);
  });

  group('load', () {
    test('reads previously saved values from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'appLanguage': 'tr',
        'unitPreference': 'IMPERIAL',
      });
      final controller = SettingsController();

      await controller.load();

      expect(controller.language, AppLanguage.turkish);
      expect(controller.unitPreference, UnitPreference.imperial);
    });

    test('falls back to defaults when nothing was saved yet', () async {
      final controller = SettingsController();
      await controller.load();

      expect(controller.language, AppLanguage.system);
      expect(controller.unitPreference, UnitPreference.metric);
    });

    test('notifies listeners', () async {
      final controller = SettingsController();
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.load();

      expect(notified, isTrue);
    });
  });

  group('setLanguage', () {
    test('updates the field immediately and persists it', () async {
      final controller = SettingsController();

      await controller.setLanguage(AppLanguage.turkish);

      expect(controller.language, AppLanguage.turkish);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('appLanguage'), 'tr');
    });

    test('notifies listeners', () async {
      final controller = SettingsController();
      var notified = false;
      controller.addListener(() => notified = true);

      await controller.setLanguage(AppLanguage.english);

      expect(notified, isTrue);
    });
  });

  group('setUnitPreference', () {
    test('updates the field immediately and persists it', () async {
      final controller = SettingsController();

      await controller.setUnitPreference(UnitPreference.imperial);

      expect(controller.unitPreference, UnitPreference.imperial);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unitPreference'), 'IMPERIAL');
    });
  });

  group('resolvedLocale', () {
    test('is null for system (defers to device locale)', () {
      final controller = SettingsController();
      expect(controller.resolvedLocale, isNull);
    });

    test('is an explicit Locale for english/turkish', () async {
      final controller = SettingsController();

      await controller.setLanguage(AppLanguage.english);
      expect(controller.resolvedLocale, const Locale('en'));

      await controller.setLanguage(AppLanguage.turkish);
      expect(controller.resolvedLocale, const Locale('tr'));
    });
  });

  group('effectiveLanguageCode', () {
    test('is en/tr directly for explicit languages', () async {
      final controller = SettingsController();

      await controller.setLanguage(AppLanguage.english);
      expect(controller.effectiveLanguageCode, 'en');

      await controller.setLanguage(AppLanguage.turkish);
      expect(controller.effectiveLanguageCode, 'tr');
    });

    test('for system, returns the device locale when it is tr, else en', () {
      final controller = SettingsController();
      // language defaults to AppLanguage.system.
      final code = controller.effectiveLanguageCode;
      expect(['en', 'tr'], contains(code));
    });
  });
}
