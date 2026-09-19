/// Mirrors backend SpeciesRecordingResponseDto (live Xeno-canto proxy).
class SpeciesRecording {
  final String id;
  final String recordingUrl;
  final String? type;
  final String? quality;
  final String? recordist;
  final String? licenseUrl;

  SpeciesRecording({
    required this.id,
    required this.recordingUrl,
    this.type,
    this.quality,
    this.recordist,
    this.licenseUrl,
  });

  factory SpeciesRecording.fromJson(Map<String, dynamic> json) {
    return SpeciesRecording(
      id: json['id'].toString(),
      recordingUrl: json['recordingUrl'] as String,
      type: json['type'] as String?,
      quality: json['quality'] as String?,
      recordist: json['recordist'] as String?,
      licenseUrl: json['licenseUrl'] as String?,
    );
  }
}
