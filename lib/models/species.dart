import 'species_image.dart';

/// Backend keys most descriptive Species text by locale, e.g.
/// {"en": "...", "tr": "..."}. Falls back to English, then to any value.
String localizedText(Map<String, String>? map, String locale) {
  if (map == null || map.isEmpty) return '';
  return map[locale] ?? map['en'] ?? map.values.first;
}

Map<String, String>? _parseLocaleMap(dynamic raw) {
  if (raw == null) return null;
  return (raw as Map).map((key, value) => MapEntry(key.toString(), value.toString()));
}

/// Mirrors backend SpeciesResponseDto.
class Species {
  final String id;
  final Map<String, String> commonName;
  final String scientificName;
  final String? family;
  final String? order;
  final Map<String, String>? description;
  final Map<String, String>? lifespan;
  final Map<String, String>? diet;
  final Map<String, String>? habitat;
  final Map<String, String>? sizeDescription;
  final Map<String, String>? conservationStatus;
  final Map<String, String>? nativeRange;
  final List<SpeciesImage> images;

  Species({
    required this.id,
    required this.commonName,
    required this.scientificName,
    this.family,
    this.order,
    this.description,
    this.lifespan,
    this.diet,
    this.habitat,
    this.sizeDescription,
    this.conservationStatus,
    this.nativeRange,
    required this.images,
  });

  String name(String locale) => localizedText(commonName, locale);

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'] as String,
      commonName: _parseLocaleMap(json['commonName']) ?? const {},
      scientificName: json['scientificName'] as String,
      family: json['family'] as String?,
      order: json['order'] as String?,
      description: _parseLocaleMap(json['description']),
      lifespan: _parseLocaleMap(json['lifespan']),
      diet: _parseLocaleMap(json['diet']),
      habitat: _parseLocaleMap(json['habitat']),
      sizeDescription: _parseLocaleMap(json['sizeDescription']),
      conservationStatus: _parseLocaleMap(json['conservationStatus']),
      nativeRange: _parseLocaleMap(json['nativeRange']),
      images: (json['images'] as List<dynamic>? ?? [])
          .map((e) => SpeciesImage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Mirrors the backend's versioned pagination envelope for GET /api/species:
/// {content: [...], page: {totalElements, totalPages, number, size}} —
/// replaced Spring's raw internal Page JSON (which had these fields at the
/// root, plus a `last` flag this version dropped; use [isLastPage] instead).
class SpeciesPage {
  final List<Species> content;
  final int number; // current page, 0-indexed
  final int totalPages;
  final int totalElements;

  SpeciesPage({
    required this.content,
    required this.number,
    required this.totalPages,
    required this.totalElements,
  });

  bool get isLastPage => number + 1 >= totalPages;

  factory SpeciesPage.fromJson(Map<String, dynamic> json) {
    final page = json['page'] as Map<String, dynamic>? ?? const {};
    return SpeciesPage(
      content: (json['content'] as List<dynamic>? ?? [])
          .map((e) => Species.fromJson(e as Map<String, dynamic>))
          .toList(),
      number: (page['number'] as num?)?.toInt() ?? 0,
      totalPages: (page['totalPages'] as num?)?.toInt() ?? 1,
      totalElements: (page['totalElements'] as num?)?.toInt() ?? 0,
    );
  }
}
