// Interface du repository pour l'abstraction du stockage des photos
import 'dart:io';
import '../models/photo_model.dart';

abstract class PhotoRepository {
  Future<void> initialize();
  Future<String> savePhoto(File imageFile);
  Future<String> savePhotoStrip({
    required File stripFile,
    required int photoCount,
    required List<String> individualPhotoPaths,
  });
  List<Photo> getAllPhotos();
  Future<void> deletePhoto(String photoId);
  Future<File> combinePhotosIntoStrip(List<File> photoFiles);
  Future<File> generateBlackPhoto({int width = 1920, int height = 2560});
}
