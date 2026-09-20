import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/species_recording.dart';

void main() {
  test('SpeciesRecording.fromJson parses all fields, id coerced to String', () {
    final recording = SpeciesRecording.fromJson({
      'id': 12345, // Xeno-canto ids come back as numbers
      'recordingUrl': 'https://xeno-canto.org/12345.mp3',
      'type': 'song',
      'quality': 'A',
      'recordist': 'Jane Doe',
      'licenseUrl': 'https://creativecommons.org/licenses/by-nc-sa/4.0/',
    });

    expect(recording.id, '12345');
    expect(recording.recordingUrl, 'https://xeno-canto.org/12345.mp3');
    expect(recording.type, 'song');
    expect(recording.quality, 'A');
    expect(recording.recordist, 'Jane Doe');
    expect(recording.licenseUrl,
        'https://creativecommons.org/licenses/by-nc-sa/4.0/');
  });

  test('SpeciesRecording.fromJson handles missing optional fields', () {
    final recording = SpeciesRecording.fromJson({
      'id': 'abc',
      'recordingUrl': 'https://xeno-canto.org/abc.mp3',
    });
    expect(recording.type, isNull);
    expect(recording.quality, isNull);
    expect(recording.recordist, isNull);
    expect(recording.licenseUrl, isNull);
  });
}
