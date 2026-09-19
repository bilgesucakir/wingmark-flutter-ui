/// Enums mirroring the backend's Java enums (see wingmark-backend
/// src/main/java/com/wingmark/backend/enums/*.java) so wire values match
/// exactly.
library;

enum Role {
  user('USER'),
  admin('ADMIN');

  final String value;
  const Role(this.value);

  static Role fromJson(String? raw) =>
      Role.values.firstWhere((e) => e.value == raw, orElse: () => Role.user);
}

enum Gender {
  male('MALE'),
  female('FEMALE'),
  unknown('UNKNOWN');

  final String value;
  const Gender(this.value);

  static Gender fromJson(String? raw) => Gender.values
      .firstWhere((e) => e.value == raw, orElse: () => Gender.unknown);

  String label(String locale) {
    switch (this) {
      case Gender.male:
        return locale == 'tr' ? 'Erkek' : 'Male';
      case Gender.female:
        return locale == 'tr' ? 'Dişi' : 'Female';
      case Gender.unknown:
        return locale == 'tr' ? 'Bilinmiyor' : 'Unknown';
    }
  }
}

enum LifeStage {
  baby('BABY'),
  adult('ADULT'),
  unknown('UNKNOWN');

  final String value;
  const LifeStage(this.value);

  static LifeStage fromJson(String? raw) => LifeStage.values
      .firstWhere((e) => e.value == raw, orElse: () => LifeStage.unknown);

  String label(String locale) {
    switch (this) {
      case LifeStage.baby:
        return locale == 'tr' ? 'Yavru' : 'Baby';
      case LifeStage.adult:
        return locale == 'tr' ? 'Yetişkin' : 'Adult';
      case LifeStage.unknown:
        return locale == 'tr' ? 'Bilinmiyor' : 'Unknown';
    }
  }
}

/// Species-image-only variant: backend uses NOT_APPLICABLE instead of UNKNOWN.
enum ImageGender {
  male('MALE'),
  female('FEMALE'),
  notApplicable('NOT_APPLICABLE');

  final String value;
  const ImageGender(this.value);

  static ImageGender fromJson(String? raw) => ImageGender.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ImageGender.notApplicable);
}

/// Species-image-only variant: no UNKNOWN option.
enum LifeStageImage {
  baby('BABY'),
  adult('ADULT');

  final String value;
  const LifeStageImage(this.value);

  static LifeStageImage fromJson(String? raw) => LifeStageImage.values
      .firstWhere((e) => e.value == raw, orElse: () => LifeStageImage.adult);
}

enum SpeciesStatus {
  guess('GUESS'),
  confident('CONFIDENT');

  final String value;
  const SpeciesStatus(this.value);

  static SpeciesStatus? fromJson(String? raw) {
    if (raw == null) return null;
    return SpeciesStatus.values.firstWhere((e) => e.value == raw,
        orElse: () => SpeciesStatus.guess);
  }

  String label(String locale) {
    switch (this) {
      case SpeciesStatus.guess:
        return locale == 'tr' ? 'Emin değilim' : 'Guess';
      case SpeciesStatus.confident:
        return locale == 'tr' ? 'Eminim' : 'Confident';
    }
  }
}

/// Named SightingVisibility (not Visibility) because Flutter's widgets
/// library already declares a `Visibility` class — same collision the Swift
/// app dodges by naming its file Visibility.swift but its type
/// SightingVisibility (to avoid clashing with SwiftUI's own Visibility).
enum SightingVisibility {
  private('PRIVATE'),
  public('PUBLIC');

  final String value;
  const SightingVisibility(this.value);

  static SightingVisibility fromJson(String? raw) =>
      SightingVisibility.values.firstWhere((e) => e.value == raw,
          orElse: () => SightingVisibility.private);
}

enum BadgeTier {
  bronze('BRONZE'),
  silver('SILVER'),
  gold('GOLD');

  final String value;
  const BadgeTier(this.value);

  static BadgeTier fromJson(String? raw) => BadgeTier.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => BadgeTier.bronze);

  String label(String locale) {
    switch (this) {
      case BadgeTier.bronze:
        return locale == 'tr' ? 'Bronz' : 'Bronze';
      case BadgeTier.silver:
        return locale == 'tr' ? 'Gümüş' : 'Silver';
      case BadgeTier.gold:
        return locale == 'tr' ? 'Altın' : 'Gold';
    }
  }
}

enum BadgeCriteriaType {
  totalLogs('TOTAL_LOGS'),
  uniqueSpecies('UNIQUE_SPECIES'),
  babyLogs('BABY_LOGS'),
  unknownSpeciesLogs('UNKNOWN_SPECIES_LOGS'),
  petLogs('PET_LOGS'),
  speciesInRadius('SPECIES_IN_RADIUS'),
  sightingsInRadius('SIGHTINGS_IN_RADIUS'),
  speciesLogs('SPECIES_LOGS');

  final String value;
  const BadgeCriteriaType(this.value);

  static BadgeCriteriaType fromJson(String? raw) =>
      BadgeCriteriaType.values.firstWhere((e) => e.value == raw,
          orElse: () => BadgeCriteriaType.totalLogs);
}

enum UnitPreference {
  metric('METRIC'),
  imperial('IMPERIAL');

  final String value;
  const UnitPreference(this.value);

  static UnitPreference fromJson(String? raw) => UnitPreference.values
      .firstWhere((e) => e.value == raw, orElse: () => UnitPreference.metric);

  String label(String locale) {
    switch (this) {
      case UnitPreference.metric:
        return locale == 'tr' ? 'Metrik (km, m)' : 'Metric (km, m)';
      case UnitPreference.imperial:
        return locale == 'tr' ? 'İngiliz (mi, ft)' : 'Imperial (mi, ft)';
    }
  }
}

/// App-only, mirrors Swift's AppLanguage (system default vs explicit locale).
enum AppLanguage {
  system('system'),
  english('en'),
  turkish('tr');

  final String value;
  const AppLanguage(this.value);

  static AppLanguage fromStorage(String? raw) => AppLanguage.values
      .firstWhere((e) => e.value == raw, orElse: () => AppLanguage.system);

  String label(String locale) {
    switch (this) {
      case AppLanguage.system:
        return locale == 'tr' ? 'Sistem Varsayılanı' : 'System Default';
      case AppLanguage.english:
        return 'English';
      case AppLanguage.turkish:
        return 'Türkçe';
    }
  }
}
