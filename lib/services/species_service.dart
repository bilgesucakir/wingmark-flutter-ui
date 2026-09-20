import '../core/api_client.dart';
import '../models/species.dart';
import '../models/species_recording.dart';

/// Wraps the public read endpoints of /api/species (see
/// SpeciesController.java). The admin-only mutation/curation endpoints
/// (create/update/delete species & images, photo-candidates) are out of
/// scope for the end-user app.
class SpeciesService {
  SpeciesService(this._client);

  final ApiClient _client;

  /// GET /api/species?search=&page=&size=&sort= — paginated (a versioned
  /// {content, page} envelope). [sort] is a Spring-style "field,direction"
  /// string, e.g. "commonName.en,asc" or "scientificName,desc".
  Future<SpeciesPage> search({
    String? query,
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    final json = await _client.get(
      '/api/species',
      query: {
        if (query != null && query.isNotEmpty) 'search': query,
        'page': page.toString(),
        'size': size.toString(),
        if (sort != null) 'sort': sort,
      },
      auth: false,
    );
    return SpeciesPage.fromJson(json as Map<String, dynamic>);
  }

  Future<Species> getById(String id) async {
    final json = await _client.get('/api/species/$id', auth: false);
    return Species.fromJson(json as Map<String, dynamic>);
  }

  Future<List<SpeciesRecording>> getSounds(String id) async {
    final json = await _client.get('/api/species/$id/sound', auth: false);
    return (json as List<dynamic>)
        .map((e) => SpeciesRecording.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
