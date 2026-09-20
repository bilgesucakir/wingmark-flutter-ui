import 'enums.dart';

/// Mirrors backend UserProfileResponseDto.
class UserProfile {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String? favoriteSpeciesId;
  final String? favoriteSpeciesName;
  final Role role;
  final bool emailVerified;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    this.favoriteSpeciesId,
    this.favoriteSpeciesName,
    required this.role,
    required this.emailVerified,
    required this.createdAt,
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? '@$username' : name;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      profilePicture: json['profilePicture'] as String?,
      favoriteSpeciesId: json['favoriteSpeciesId'] as String?,
      favoriteSpeciesName: json['favoriteSpeciesName'] as String?,
      role: Role.fromJson(json['role'] as String?),
      emailVerified: json['emailVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
