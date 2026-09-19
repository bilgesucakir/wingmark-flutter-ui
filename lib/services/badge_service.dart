import '../core/api_client.dart';
import '../models/badge.dart';
import '../models/user_badge.dart';

/// Wraps /api/badges (see BadgeController.java).
class BadgeService {
  BadgeService(this._client);

  final ApiClient _client;

  Future<List<BadgeDefinition>> getCatalog() async {
    final json = await _client.get('/api/badges/catalog', auth: false);
    return (json as List<dynamic>)
        .map((e) => BadgeDefinition.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserBadge>> getForUser(String userId) async {
    final json = await _client.get('/api/badges/user/$userId');
    return (json as List<dynamic>)
        .map((e) => UserBadge.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
