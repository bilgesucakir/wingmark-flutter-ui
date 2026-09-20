import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/enums.dart';
import 'package:wingmark_flutter/models/species_image.dart';

void main() {
  test('SpeciesImage.fromJson parses all fields', () {
    final image = SpeciesImage.fromJson({
      'id': 'img1',
      'lifeStage': 'BABY',
      'gender': 'FEMALE',
      'imageUrl': 'https://example.com/a.jpg',
      'caption': 'A juvenile',
    });

    expect(image.id, 'img1');
    expect(image.lifeStage, LifeStageImage.baby);
    expect(image.gender, ImageGender.female);
    expect(image.imageUrl, 'https://example.com/a.jpg');
    expect(image.caption, 'A juvenile');
  });

  test('SpeciesImage.fromJson handles missing caption', () {
    final image = SpeciesImage.fromJson({
      'id': 'img1',
      'lifeStage': 'ADULT',
      'gender': 'NOT_APPLICABLE',
      'imageUrl': 'https://example.com/a.jpg',
    });
    expect(image.caption, isNull);
  });
}
