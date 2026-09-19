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
