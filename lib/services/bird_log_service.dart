import '../core/api_client.dart';
import '../models/bird_log.dart';
import '../models/enums.dart';

/// Ascending/descending sort on a bird log's observedAt date.
enum SortDirection {
  ascending('ASC'),
  descending('DESC');

  final String value;
  const SortDirection(this.value);
}

/// Wraps /api/bird-logs (see BirdLogController.java) — the user's diary.
class BirdLogService {
  BirdLogService(this._client);

  final ApiClient _client;

  /// All filters are optional and combinable. Note the backend requires
  /// exact-case enum values (e.g. "MALE", not "male") — Gender/LifeStage's
  /// own `.value` already produces that, so this is safe by construction.
  Future<List<BirdLog>> getForUser(
    String userId, {
    SortDirection? sortDirection,
    bool? hasSpecies,
    Gender? gender,
    LifeStage? lifeStage,
  }) async {
    final json = await _client.get('/api/bird-logs/user/$userId', query: {
      if (sortDirection != null) 'sortDirection': sortDirection.value,
      if (hasSpecies != null) 'hasSpecies': hasSpecies.toString(),
      if (gender != null) 'gender': gender.value,
      if (lifeStage != null) 'lifeStage': lifeStage.value,
    });
    return (json as List<dynamic>)
        .map((e) => BirdLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BirdLog>> getInBounds({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final json = await _client.get('/api/bird-logs/location', query: {
      'minLat': minLat.toString(),
      'maxLat': maxLat.toString(),
      'minLng': minLng.toString(),
      'maxLng': maxLng.toString(),
    });
    return (json as List<dynamic>)
        .map((e) => BirdLog.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BirdLog> getById(String id) async {
    final json = await _client.get('/api/bird-logs/$id');
    return BirdLog.fromJson(json as Map<String, dynamic>);
  }

  Future<BirdLog> create(BirdLogRequest request) async {
    final json = await _client.post('/api/bird-logs', body: request.toJson());
    return BirdLog.fromJson(json as Map<String, dynamic>);
  }

  Future<BirdLog> update(String id, BirdLogRequest request) async {
    final json =
        await _client.put('/api/bird-logs/$id', body: request.toJson());
    return BirdLog.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _client.delete('/api/bird-logs/$id');
}
