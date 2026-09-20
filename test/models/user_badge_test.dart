import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/user_badge.dart';

void main() {
  group('UserBadge.fromJson', () {
    test('parses an earned badge', () {
      final badge = UserBadge.fromJson({
        'badgeId': 'b1',
        'badgeName': 'First Sighting',
        'badgeIcon': 'trophy.fill',
        'earned': true,
        'earnedAt': '2026-09-19T19:34:41.770Z',
        'progress': 2,
        'targetValue': 1,
      });

      expect(badge.badgeId, 'b1');
      expect(badge.badgeName, 'First Sighting');
      expect(badge.earned, isTrue);
      expect(badge.earnedAt, DateTime.parse('2026-09-19T19:34:41.770Z'));
      expect(badge.progress, 2);
      expect(badge.targetValue, 1);
    });

    test('parses an unearned badge with null earnedAt', () {
      final badge = UserBadge.fromJson({
        'badgeId': 'b2',
        'badgeName': 'Species Master',
        'badgeIcon': 'trophy.fill',
        'earned': false,
        'earnedAt': null,
        'progress': 0,
        'targetValue': 50,
      });

      expect(badge.earned, isFalse);
      expect(badge.earnedAt, isNull);
    });

    test('defaults missing numeric/bool fields to zero/false', () {
      final badge = UserBadge.fromJson({
        'badgeId': 'b3',
      });
      expect(badge.badgeName, '');
      expect(badge.earned, isFalse);
      expect(badge.progress, 0);
      expect(badge.targetValue, 0);
    });
  });
}
