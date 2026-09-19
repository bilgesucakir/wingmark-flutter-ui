import 'enums.dart';

/// Mirrors backend BirdLogResponseDto.
class BirdLog {
  final String id;
  final String userId;
  final String? speciesId;
  final String? speciesCommonName;
  final SpeciesStatus? speciesStatus;
  final bool pet;
  final String? customName;
  final LifeStage lifeStage;
  final Gender gender;
  final String? photoUrl;
  final String? note;
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final DateTime observedAt;
  final SightingVisibility visibility;
  final DateTime createdAt;

  BirdLog({
    required this.id,
    required this.userId,
    this.speciesId,
    this.speciesCommonName,
    this.speciesStatus,
    required this.pet,
    this.customName,
    required this.lifeStage,
    required this.gender,
    this.photoUrl,
    this.note,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.observedAt,
    required this.visibility,
    required this.createdAt,
  });

  /// Display name shown in the diary list / map pins.
  String displayName(String locale) {
    if (customName != null && customName!.trim().isNotEmpty) {
      return customName!;
    }
    if (speciesCommonName != null && speciesCommonName!.trim().isNotEmpty) {
      return speciesCommonName!;
    }
    return locale == 'tr' ? 'Henüz emin değilim' : 'Not sure yet';
  }

  factory BirdLog.fromJson(Map<String, dynamic> json) {
    return BirdLog(
      id: json['id'] as String,
      userId: json['userId'] as String,
      speciesId: json['speciesId'] as String?,
      speciesCommonName: json['speciesCommonName'] as String?,
      speciesStatus: SpeciesStatus.fromJson(json['speciesStatus'] as String?),
      pet: json['pet'] as bool? ?? false,
      customName: json['customName'] as String?,
      lifeStage: LifeStage.fromJson(json['lifeStage'] as String?),
      gender: Gender.fromJson(json['gender'] as String?),
      photoUrl: json['photoUrl'] as String?,
      note: json['note'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationName: json['locationName'] as String?,
      observedAt: DateTime.parse(json['observedAt'] as String),
      visibility: SightingVisibility.fromJson(json['visibility'] as String?),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// Mirrors backend CreateBirdLogRequestDto / UpdateBirdLogRequestDto (same
/// shape). Latitude/longitude are required by the backend even though the
/// original Swift UI never actually collected them.
class BirdLogRequest {
  final String? speciesId;
  final SpeciesStatus? speciesStatus;
  final bool pet;
  final String? customName;
  final LifeStage lifeStage;
  final Gender gender;
  final String? photoUrl;
  final String? note;
  final double latitude;
  final double longitude;
  final String? locationName;

  BirdLogRequest({
    this.speciesId,
    this.speciesStatus,
    this.pet = false,
    this.customName,
    required this.lifeStage,
    required this.gender,
    this.photoUrl,
    this.note,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  Map<String, dynamic> toJson() => {
        'speciesId': speciesId,
        'speciesStatus': speciesStatus?.value,
        'pet': pet,
        'customName': customName,
        'lifeStage': lifeStage.value,
        'gender': gender.value,
        'photoUrl': photoUrl,
        'note': note,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
      };
}
