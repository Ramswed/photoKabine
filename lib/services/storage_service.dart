// Service de stockage local utilisant le repository pattern. Délègue les opérations au repository pour une meilleure abstraction.
import 'dart:io';
import '../models/photo_model.dart';
import '../repositories/photo_repository.dart';
import '../repositories/hive_photo_repository.dart';

class StorageService {
  static PhotoRepository? _repository;

  static Future<void> init() async {
    _repository = HivePhotoRepository();
    await _repository!.initialize();
  }

  static PhotoRepository get _getRepository {
    if (_repository == null) {
      throw Exception('StorageService not initialized. Call init() first.');
    }
    return _repository!;
  }

  static Future<String> savePhoto(File imageFile) async {
    return await _getRepository.savePhoto(imageFile);
  }

  static List<Photo> getAllPhotos() {
    return _getRepository.getAllPhotos();
  }

  static Future<void> deletePhoto(String photoId) async {
    return await _getRepository.deletePhoto(photoId);
  }

  static Future<File> combinePhotosIntoStrip(List<File> photoFiles) async {
    return await _getRepository.combinePhotosIntoStrip(photoFiles);
  }

  static Future<String> savePhotoStrip({
    required File stripFile,
    required int photoCount,
    required List<String> individualPhotoPaths,
  }) async {
    return await _getRepository.savePhotoStrip(
      stripFile: stripFile,
      photoCount: photoCount,
      individualPhotoPaths: individualPhotoPaths,
    );
  }

  static Future<File> generateBlackPhoto({
    int width = 1920,
    int height = 2560,
  }) async {
    return await _getRepository.generateBlackPhoto(
      width: width,
      height: height,
    );
  }
}
