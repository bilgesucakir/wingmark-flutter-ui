import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/badge.dart';
import 'package:wingmark_flutter/models/enums.dart';

void main() {
  group('BadgeDefinition.fromJson', () {
    test('parses a full badge', () {
      final badge = BadgeDefinition.fromJson({
        'id': 'b1',
        'name': {'en': 'First Sighting', 'tr': 'İlk Gözlem'},
        'description': {'en': 'Log your first bird'},
        'icon': 'trophy.fill',
        'criteriaType': 'TOTAL_LOGS',
        'criteriaValue': 1,
        'criteriaMetadata': {'radiusMeters': 5000},
        'tier': 'BRONZE',
      });

      expect(badge.id, 'b1');
      expect(badge.icon, 'trophy.fill');
      expect(badge.criteriaType, BadgeCriteriaType.totalLogs);
      expect(badge.criteriaValue, 1);
      expect(badge.criteriaMetadata, {'radiusMeters': 5000});
      expect(badge.tier, BadgeTier.bronze);
    });

    test('displayName/displayDescription resolve by locale with en fallback', () {
      final badge = BadgeDefinition.fromJson({
        'id': 'b1',
        'name': {'en': 'First Sighting', 'tr': 'İlk Gözlem'},
        'description': {'en': 'Log your first bird'},
        'icon': 'trophy.fill',
        'criteriaType': 'TOTAL_LOGS',
        'criteriaValue': 1,
        'tier': 'BRONZE',
      });

      expect(badge.displayName('tr'), 'İlk Gözlem');
      expect(badge.displayName('fr'), 'First Sighting');
      expect(badge.displayDescription('en'), 'Log your first bird');
    });

    test('defaults missing fields sensibly', () {
      final badge = BadgeDefinition.fromJson({
        'id': 'b1',
        'name': {'en': 'X'},
        'description': {'en': 'Y'},
      });
      expect(badge.icon, 'emoji_events');
      expect(badge.criteriaType, BadgeCriteriaType.totalLogs);
      expect(badge.criteriaValue, 0);
      expect(badge.criteriaMetadata, isNull);
      expect(badge.tier, BadgeTier.bronze);
    });
  });
}
