import 'enums.dart';

/// Mirrors backend SpeciesImageResponseDto.
class SpeciesImage {
  final String id;
  final LifeStageImage lifeStage;
  final ImageGender gender;
  final String imageUrl;
  final String? caption;

  SpeciesImage({
    required this.id,
    required this.lifeStage,
    required this.gender,
    required this.imageUrl,
    this.caption,
  });

  factory SpeciesImage.fromJson(Map<String, dynamic> json) {
    return SpeciesImage(
      id: json['id'] as String,
      lifeStage: LifeStageImage.fromJson(json['lifeStage'] as String?),
      gender: ImageGender.fromJson(json['gender'] as String?),
      imageUrl: json['imageUrl'] as String,
      caption: json['caption'] as String?,
    );
  }
}
