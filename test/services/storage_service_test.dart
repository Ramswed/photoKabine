// Tests unitaires pour StorageService
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photobooth/models/photo_model.dart';
import 'package:photobooth/services/storage_service.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    Box<Photo>? box;

    setUpAll(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(PhotoAdapter());
    });

    setUp(() async {
      await StorageService.init();
      box = await Hive.openBox<Photo>('photos_box');
      await box!.clear();
    });

    tearDown(() async {
      await box?.clear();
      await box?.close();
    });

    test('init initialise le repository', () async {
      await StorageService.init();
      final photos = StorageService.getAllPhotos();
      expect(photos, isA<List<Photo>>());
    });

    test('getAllPhotos retourne une liste vide initialement', () {
      final photos = StorageService.getAllPhotos();
      expect(photos, isEmpty);
    });

    test('getAllPhotos trie les photos par date décroissante', () async {
      final photo1 = Photo.create(
        imagePath: '/path/1.png',
        dateTaken: DateTime(2024, 1, 1),
      );
      final photo2 = Photo.create(
        imagePath: '/path/2.png',
        dateTaken: DateTime(2024, 1, 2),
      );
      final photo3 = Photo.create(
        imagePath: '/path/3.png',
        dateTaken: DateTime(2024, 1, 3),
      );

      await box!.put(photo1.id, photo1);
      await box!.put(photo2.id, photo2);
      await box!.put(photo3.id, photo3);

      final photos = StorageService.getAllPhotos();
      expect(photos.length, 3);
      expect(photos[0].dateTaken, photo3.dateTaken);
      expect(photos[1].dateTaken, photo2.dateTaken);
      expect(photos[2].dateTaken, photo1.dateTaken);
    });

    test('deletePhoto supprime une photo de la box', () async {
      final photo = Photo.create(imagePath: '/path/to/image.png');
      await box!.put(photo.id, photo);

      expect(box!.get(photo.id), isNotNull);
      await StorageService.deletePhoto(photo.id);
      expect(box!.get(photo.id), isNull);
    });

    test('generateBlackPhoto crée une image noire', () async {
      final blackPhoto = await StorageService.generateBlackPhoto(
        width: 100,
        height: 100,
      );

      expect(blackPhoto, isA<File>());
      expect(await blackPhoto.exists(), true);
      expect(blackPhoto.path, contains('black_photo_'));
      
      await blackPhoto.delete();
    });

    test('generateBlackPhoto crée une image avec les dimensions par défaut', () async {
      final blackPhoto = await StorageService.generateBlackPhoto();

      expect(blackPhoto, isA<File>());
      expect(await blackPhoto.exists(), true);
      
      await blackPhoto.delete();
    });
  });
}
