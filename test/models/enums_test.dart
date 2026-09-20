import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/enums.dart';

void main() {
  group('Role', () {
    test('fromJson maps known values', () {
      expect(Role.fromJson('USER'), Role.user);
      expect(Role.fromJson('ADMIN'), Role.admin);
    });
    test('fromJson falls back to user for unknown/null', () {
      expect(Role.fromJson(null), Role.user);
      expect(Role.fromJson('WHATEVER'), Role.user);
    });
  });

  group('Gender', () {
    test('fromJson round-trips every value', () {
      for (final g in Gender.values) {
        expect(Gender.fromJson(g.value), g);
      }
    });
    test('fromJson falls back to unknown', () {
      expect(Gender.fromJson(null), Gender.unknown);
      expect(Gender.fromJson('bogus'), Gender.unknown);
    });
    test('label differs by locale', () {
      expect(Gender.male.label('en'), 'Male');
      expect(Gender.male.label('tr'), 'Erkek');
    });
  });

  group('LifeStage', () {
    test('fromJson round-trips every value', () {
      for (final s in LifeStage.values) {
        expect(LifeStage.fromJson(s.value), s);
      }
    });
    test('fromJson falls back to unknown', () {
      expect(LifeStage.fromJson(null), LifeStage.unknown);
    });
  });

  group('ImageGender', () {
    test('fromJson round-trips every value', () {
      for (final g in ImageGender.values) {
        expect(ImageGender.fromJson(g.value), g);
      }
    });
    test('fromJson falls back to notApplicable', () {
      expect(ImageGender.fromJson(null), ImageGender.notApplicable);
      expect(ImageGender.fromJson('UNKNOWN'), ImageGender.notApplicable);
    });
  });

  group('LifeStageImage', () {
    test('fromJson round-trips every value', () {
      for (final s in LifeStageImage.values) {
        expect(LifeStageImage.fromJson(s.value), s);
      }
    });
    test('fromJson falls back to adult', () {
      expect(LifeStageImage.fromJson(null), LifeStageImage.adult);
    });
  });

  group('SpeciesStatus', () {
    test('fromJson round-trips every value', () {
      for (final s in SpeciesStatus.values) {
        expect(SpeciesStatus.fromJson(s.value), s);
      }
    });
    test('fromJson returns null for null input (nullable field)', () {
      expect(SpeciesStatus.fromJson(null), isNull);
    });
    test('fromJson falls back to guess for unknown non-null value', () {
      expect(SpeciesStatus.fromJson('bogus'), SpeciesStatus.guess);
    });
  });

  group('SightingVisibility', () {
    test('fromJson round-trips every value', () {
      for (final v in SightingVisibility.values) {
        expect(SightingVisibility.fromJson(v.value), v);
      }
    });
    test('fromJson falls back to private', () {
      expect(SightingVisibility.fromJson(null), SightingVisibility.private);
    });
  });

  group('BadgeTier', () {
    test('fromJson round-trips every value', () {
      for (final t in BadgeTier.values) {
        expect(BadgeTier.fromJson(t.value), t);
      }
    });
    test('label differs by locale', () {
      expect(BadgeTier.gold.label('en'), 'Gold');
      expect(BadgeTier.gold.label('tr'), 'Altın');
    });
  });

  group('BadgeCriteriaType', () {
    test('fromJson round-trips every value', () {
      for (final c in BadgeCriteriaType.values) {
        expect(BadgeCriteriaType.fromJson(c.value), c);
      }
    });
    test('fromJson falls back to totalLogs', () {
      expect(BadgeCriteriaType.fromJson(null), BadgeCriteriaType.totalLogs);
    });
  });

  group('UnitPreference', () {
    test('fromJson round-trips every value', () {
      for (final u in UnitPreference.values) {
        expect(UnitPreference.fromJson(u.value), u);
      }
    });
    test('fromJson falls back to metric', () {
      expect(UnitPreference.fromJson(null), UnitPreference.metric);
    });
  });

  group('AppLanguage', () {
    test('fromStorage round-trips every value', () {
      for (final l in AppLanguage.values) {
        expect(AppLanguage.fromStorage(l.value), l);
      }
    });
    test('fromStorage falls back to system', () {
      expect(AppLanguage.fromStorage(null), AppLanguage.system);
      expect(AppLanguage.fromStorage('fr'), AppLanguage.system);
    });
  });
}
