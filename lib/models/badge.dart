import 'enums.dart';
import 'species.dart' show localizedText;

/// Mirrors backend BadgeResponseDto (the full catalog, publicly readable).
class BadgeDefinition {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final String icon;
  final BadgeCriteriaType criteriaType;
  final int criteriaValue;
  final Map<String, dynamic>? criteriaMetadata;
  final BadgeTier tier;

  BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.criteriaType,
    required this.criteriaValue,
    this.criteriaMetadata,
    required this.tier,
  });

  String displayName(String locale) => localizedText(
      name.map((k, v) => MapEntry(k, v.toString())), locale);
  String displayDescription(String locale) => localizedText(
      description.map((k, v) => MapEntry(k, v.toString())), locale);

  factory BadgeDefinition.fromJson(Map<String, dynamic> json) {
    return BadgeDefinition(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] as Map? ?? {}),
      description: Map<String, String>.from(json['description'] as Map? ?? {}),
      icon: json['icon'] as String? ?? 'emoji_events',
      criteriaType: BadgeCriteriaType.fromJson(json['criteriaType'] as String?),
      criteriaValue: (json['criteriaValue'] as num?)?.toInt() ?? 0,
      criteriaMetadata: json['criteriaMetadata'] as Map<String, dynamic>?,
      tier: BadgeTier.fromJson(json['tier'] as String?),
    );
  }
}
