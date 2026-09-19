import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';

/// Local-only language + unit preference, mirroring the Swift app's
/// AppStorage("appLanguage") / AppStorage("unitPreference"). SettingsScreen
/// is responsible for additionally syncing unit preference with the backend
/// (GET/PUT /api/users/{id}/settings) once the user is authenticated.
class SettingsController extends ChangeNotifier {
  static const _languageKey = 'appLanguage';
  static const _unitKey = 'unitPreference';

  AppLanguage language = AppLanguage.system;
  UnitPreference unitPreference = UnitPreference.metric;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    language = AppLanguage.fromStorage(prefs.getString(_languageKey));
    unitPreference =
        UnitPreference.fromJson(prefs.getString(_unitKey));
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value.value);
  }

  Future<void> setUnitPreference(UnitPreference value) async {
    unitPreference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_unitKey, value.value);
  }

  /// Locale for MaterialApp — null means "defer to system".
  Locale? get resolvedLocale {
    switch (language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.turkish:
        return const Locale('tr');
    }
  }
}
