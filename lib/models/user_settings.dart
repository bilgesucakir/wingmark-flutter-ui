import 'enums.dart';

/// Mirrors backend SettingsResponseDto / UpdateSettingsRequestDto.
class UserSettings {
  final UnitPreference unitPreference;
  final String? locale;

  UserSettings({required this.unitPreference, this.locale});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      unitPreference: UnitPreference.fromJson(json['unitPreference'] as String?),
      locale: json['locale'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'unitPreference': unitPreference.value,
        'locale': locale,
      };
}
