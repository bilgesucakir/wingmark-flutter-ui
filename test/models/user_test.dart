import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/models/user.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('parses a full response', () {
      final user = UserProfile.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'username': 'bilgesu',
        'firstName': 'Bilgesu',
        'lastName': 'Cakir',
        'profilePicture': '/uploads/pic.jpg',
        'favoriteSpeciesId': 'sp1',
        'favoriteSpeciesName': 'Great Tit',
        'role': 'ADMIN',
        'emailVerified': true,
        'createdAt': '2026-01-01T00:00:00Z',
      });

      expect(user.id, 'u1');
      expect(user.email, 'a@b.com');
      expect(user.username, 'bilgesu');
      expect(user.firstName, 'Bilgesu');
      expect(user.lastName, 'Cakir');
      expect(user.profilePicture, '/uploads/pic.jpg');
      expect(user.favoriteSpeciesId, 'sp1');
      expect(user.favoriteSpeciesName, 'Great Tit');
      expect(user.role, Role.admin);
      expect(user.emailVerified, isTrue);
      expect(user.createdAt, DateTime.parse('2026-01-01T00:00:00Z'));
    });

    test('handles missing optional fields', () {
      final user = UserProfile.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'username': 'bilgesu',
        'role': 'USER',
        'emailVerified': false,
        'createdAt': '2026-01-01T00:00:00Z',
      });

      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.profilePicture, isNull);
      expect(user.favoriteSpeciesId, isNull);
      expect(user.favoriteSpeciesName, isNull);
    });

    test('fullName prefers first+last, falls back to @username', () {
      final withName = UserProfile.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'username': 'bilgesu',
        'firstName': 'Bilgesu',
        'lastName': 'Cakir',
        'role': 'USER',
        'emailVerified': true,
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(withName.fullName, 'Bilgesu Cakir');

      final withoutName = UserProfile.fromJson({
        'id': 'u1',
        'email': 'a@b.com',
        'username': 'bilgesu',
        'role': 'USER',
        'emailVerified': true,
        'createdAt': '2026-01-01T00:00:00Z',
      });
      expect(withoutName.fullName, '@bilgesu');
    });
  });
}
