// Tests unitaires pour le modèle Photo
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/models/photo_model.dart';

void main() {
  group('Photo Model Tests', () {
    test('Photo.create crée une photo avec les valeurs par défaut', () {
      final photo = Photo.create(
        imagePath: '/path/to/image.png',
      );

      expect(photo.imagePath, '/path/to/image.png');
      expect(photo.isStrip, false);
      expect(photo.photoCount, 1);
      expect(photo.individualPhotoPaths, isNull);
      expect(photo.id, isNotEmpty);
      expect(photo.dateTaken, isA<DateTime>());
    });

    test('Photo.create crée une photo avec date personnalisée', () {
      final customDate = DateTime(2024, 1, 1, 12, 0, 0);
      final photo = Photo.create(
        imagePath: '/path/to/image.png',
        dateTaken: customDate,
      );

      expect(photo.dateTaken, customDate);
    });

    test('Photo.create crée une photo avec isStrip true', () {
      final photo = Photo.create(
        imagePath: '/path/to/strip.png',
        isStrip: true,
        photoCount: 4,
        individualPhotoPaths: ['/path/1.png', '/path/2.png'],
      );

      expect(photo.isStrip, true);
      expect(photo.photoCount, 4);
      expect(photo.individualPhotoPaths, ['/path/1.png', '/path/2.png']);
    });

    test('Photo.create génère un ID unique', () {
      final photo1 = Photo.create(imagePath: '/path/1.png');
      final photo2 = Photo.create(imagePath: '/path/2.png');

      expect(photo1.id, isNot(photo2.id));
    });

    test('Photo constructor crée une photo avec tous les paramètres', () {
      final date = DateTime(2024, 1, 1);
      final photo = Photo(
        imagePath: '/path/to/image.png',
        dateTaken: date,
        id: 'test-id',
        isStrip: true,
        photoCount: 2,
        individualPhotoPaths: ['/path/1.png'],
      );

      expect(photo.imagePath, '/path/to/image.png');
      expect(photo.dateTaken, date);
      expect(photo.id, 'test-id');
      expect(photo.isStrip, true);
      expect(photo.photoCount, 2);
      expect(photo.individualPhotoPaths, ['/path/1.png']);
    });
  });
}
