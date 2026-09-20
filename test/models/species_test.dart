import 'package:flutter_test/flutter_test.dart';
import 'package:wingmark_flutter/models/species.dart';

Map<String, dynamic> _speciesJson({List<dynamic>? images}) {
  return {
    'id': 'sp1',
    'commonName': {'en': 'House Sparrow', 'tr': 'Serçe'},
    'scientificName': 'Passer domesticus',
    'family': 'Passeridae',
    'order': 'Passeriformes',
    'description': {'en': 'A small bird.'},
    'lifespan': {'en': '3-5 years'},
    'diet': {'en': 'Seeds'},
    'habitat': {'en': 'Urban areas'},
    'sizeDescription': {'en': '14-18cm'},
    'conservationStatus': {'en': 'Least Concern'},
    'nativeRange': {'en': 'Europe'},
    'images': images ?? [],
  };
}

void main() {
  group('localizedText', () {
    test('returns the requested locale when present', () {
      expect(localizedText({'en': 'Sparrow', 'tr': 'Serçe'}, 'tr'), 'Serçe');
    });
    test('falls back to en when requested locale missing', () {
      expect(localizedText({'en': 'Sparrow'}, 'tr'), 'Sparrow');
    });
    test('falls back to any value when neither locale nor en present', () {
      expect(localizedText({'fr': 'Moineau'}, 'tr'), 'Moineau');
    });
    test('returns empty string for null or empty map', () {
      expect(localizedText(null, 'en'), '');
      expect(localizedText({}, 'en'), '');
    });
  });

  group('Species.fromJson', () {
    test('parses all locale-map fields and plain fields', () {
      final species = Species.fromJson(_speciesJson());
      expect(species.id, 'sp1');
      expect(species.commonName, {'en': 'House Sparrow', 'tr': 'Serçe'});
      expect(species.scientificName, 'Passer domesticus');
      expect(species.family, 'Passeridae');
      expect(species.order, 'Passeriformes');
      expect(species.description, {'en': 'A small bird.'});
      expect(species.images, isEmpty);
    });

    test('name() resolves via localizedText', () {
      final species = Species.fromJson(_speciesJson());
      expect(species.name('tr'), 'Serçe');
      expect(species.name('fr'), 'House Sparrow'); // falls back to en
    });

    test('parses nested images', () {
      final species = Species.fromJson(_speciesJson(images: [
        {
          'id': 'img1',
          'lifeStage': 'ADULT',
          'gender': 'MALE',
          'imageUrl': 'https://example.com/a.jpg',
        }
      ]));
      expect(species.images, hasLength(1));
      expect(species.images.first.imageUrl, 'https://example.com/a.jpg');
    });

    test('handles missing optional locale-map fields', () {
      final json = _speciesJson()
        ..remove('description')
        ..remove('family');
      final species = Species.fromJson(json);
      expect(species.description, isNull);
      expect(species.family, isNull);
    });
  });

  group('SpeciesPage.fromJson', () {
    test('parses the new nested pagination envelope', () {
      final page = SpeciesPage.fromJson({
        'content': [_speciesJson()],
        'page': {
          'totalElements': 3,
          'totalPages': 2,
          'number': 0,
          'size': 2,
        },
      });
      expect(page.content, hasLength(1));
      expect(page.totalElements, 3);
      expect(page.totalPages, 2);
      expect(page.number, 0);
      expect(page.isLastPage, isFalse);
    });

    test('isLastPage is true on the final page', () {
      final page = SpeciesPage.fromJson({
        'content': <dynamic>[],
        'page': {
          'totalElements': 3,
          'totalPages': 2,
          'number': 1,
          'size': 2,
        },
      });
      expect(page.isLastPage, isTrue);
    });

    test('defaults gracefully when page metadata is missing', () {
      final page = SpeciesPage.fromJson({'content': <dynamic>[]});
      expect(page.number, 0);
      expect(page.totalPages, 1);
      expect(page.totalElements, 0);
      expect(page.isLastPage, isTrue);
    });
  });
}
