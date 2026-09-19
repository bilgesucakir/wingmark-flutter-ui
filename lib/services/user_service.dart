import '../core/api_client.dart';
import '../models/user.dart';
import '../models/user_settings.dart';

/// Wraps /api/users/{userId} (see UserController.java). Callers must pass
/// the caller's own id — the backend 404s on any other id.
class UserService {
  UserService(this._client);

  final ApiClient _client;

  Future<UserProfile> getProfile(String userId) async {
    final json = await _client.get('/api/users/$userId');
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(
    String userId, {
    String? firstName,
    String? lastName,
    String? profilePicture,
    String? favoriteSpeciesId,
  }) async {
    final json = await _client.put(
      '/api/users/$userId',
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'profilePicture': profilePicture,
        'favoriteSpeciesId': favoriteSpeciesId,
      },
    );
    return UserProfile.fromJson(json as Map<String, dynamic>);
  }

  Future<UserSettings> getSettings(String userId) async {
    final json = await _client.get('/api/users/$userId/settings');
    return UserSettings.fromJson(json as Map<String, dynamic>);
  }

  Future<UserSettings> updateSettings(String userId, UserSettings settings) async {
    final json = await _client.put(
      '/api/users/$userId/settings',
      body: settings.toJson(),
    );
    return UserSettings.fromJson(json as Map<String, dynamic>);
  }
}
