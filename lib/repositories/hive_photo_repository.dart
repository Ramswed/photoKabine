// Implémentation du repository utilisant Hive pour le stockage
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../models/photo_model.dart';
import '../errors/app_exceptions.dart';
import 'photo_repository.dart';

class HivePhotoRepository implements PhotoRepository {
  static const String _boxName = 'photos_box';
  Box<Photo>? _box;

  @override
  Future<void> initialize() async {
    try {
      _box = await Hive.openBox<Photo>(_boxName);
    } catch (e) {
      throw StorageException(
        'Impossible d\'initialiser le stockage',
        code: 'INIT_ERROR',
      );
    }
  }

  Box<Photo> get _getBox {
    if (_box == null) {
      throw StorageException(
        'Le stockage n\'est pas initialisé. Appelez initialize() d\'abord.',
        code: 'NOT_INITIALIZED',
      );
    }
    return _box!;
  }

  @override
  Future<String> savePhoto(File imageFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');

      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final Uint8List bytes = await imageFile.readAsBytes();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image originalImage = frameInfo.image;

      final ui.Image flippedImage = await flipImageHorizontally(originalImage);

      final ByteData? pngByteData =
          await flippedImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngByteData == null) {
        originalImage.dispose();
        flippedImage.dispose();
        throw ImageProcessingException(
          'Impossible de convertir l\'image en PNG',
          code: 'PNG_CONVERSION_ERROR',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'photo_$timestamp.png';
      final savedPath = '${photosDir.path}/$fileName';

      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(pngByteData.buffer.asUint8List());

      originalImage.dispose();
      flippedImage.dispose();

      final photo = Photo.create(
        imagePath: savedPath,
        dateTaken: DateTime.now(),
      );

      await _getBox.put(photo.id, photo);

      return savedPath;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw StorageException(
        'Erreur lors de la sauvegarde de la photo: ${e.toString()}',
        code: 'SAVE_ERROR',
      );
    }
  }

  @override
  List<Photo> getAllPhotos() {
    try {
      final photos = _getBox.values.toList();
      photos.sort((a, b) => b.dateTaken.compareTo(a.dateTaken));
      return photos;
    } catch (e) {
      throw StorageException(
        'Erreur lors de la récupération des photos: ${e.toString()}',
        code: 'GET_ALL_ERROR',
      );
    }
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    try {
      final photo = _getBox.get(photoId);
      if (photo != null) {
        final file = File(photo.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
        await _getBox.delete(photoId);
      }
    } catch (e) {
      throw StorageException(
        'Erreur lors de la suppression de la photo: ${e.toString()}',
        code: 'DELETE_ERROR',
      );
    }
  }

  Future<ui.Image> flipImageHorizontally(ui.Image image) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    canvas.translate(image.width.toDouble(), 0);
    canvas.scale(-1.0, 1.0);
    canvas.drawImage(image, Offset.zero, Paint());

    final ui.Picture picture = recorder.endRecording();
    final ui.Image flippedImage =
        await picture.toImage(image.width, image.height);

    return flippedImage;
  }

  @override
  Future<File> combinePhotosIntoStrip(List<File> photoFiles) async {
    if (photoFiles.isEmpty) {
      throw ImageProcessingException(
        'La liste de photos ne peut pas être vide',
        code: 'EMPTY_LIST',
      );
    }

    try {
      final List<ui.Image> images = [];
      for (final file in photoFiles) {
        final Uint8List bytes = await file.readAsBytes();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image originalImage = frameInfo.image;

        final ui.Image flippedImage = await flipImageHorizontally(originalImage);
        images.add(flippedImage);

        originalImage.dispose();
      }

      final int stripWidth = images[0].width;
      final int stripHeight =
          images.fold<int>(0, (sum, img) => sum + img.height);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      double currentY = 0;
      for (final image in images) {
        canvas.drawImage(image, Offset(0, currentY), Paint());
        currentY += image.height.toDouble();
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image stripImage =
          await picture.toImage(stripWidth, stripHeight);

      final ByteData? byteData =
          await stripImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        for (final image in images) {
          image.dispose();
        }
        stripImage.dispose();
        throw ImageProcessingException(
          'Impossible de convertir la bande en PNG',
          code: 'PNG_CONVERSION_ERROR',
        );
      }
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory('${appDir.path}/photos');

      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'strip_$timestamp.png';
      final savedPath = '${photosDir.path}/$fileName';
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(pngBytes);

      for (final image in images) {
        image.dispose();
      }
      stripImage.dispose();

      return savedFile;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ImageProcessingException(
        'Erreur lors de la combinaison des photos: ${e.toString()}',
        code: 'COMBINE_ERROR',
      );
    }
  }

  @override
  Future<String> savePhotoStrip({
    required File stripFile,
    required int photoCount,
    required List<String> individualPhotoPaths,
  }) async {
    try {
      final photo = Photo.create(
        imagePath: stripFile.path,
        dateTaken: DateTime.now(),
        isStrip: true,
        photoCount: photoCount,
        individualPhotoPaths: individualPhotoPaths,
      );

      await _getBox.put(photo.id, photo);
      return stripFile.path;
    } catch (e) {
      throw StorageException(
        'Erreur lors de la sauvegarde de la bande: ${e.toString()}',
        code: 'SAVE_STRIP_ERROR',
      );
    }
  }

  @override
  Future<File> generateBlackPhoto({
    int width = 1920,
    int height = 2560,
  }) async {
    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = Colors.black,
      );

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(width, height);

      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        image.dispose();
        throw ImageProcessingException(
          'Impossible de convertir l\'image en PNG',
          code: 'PNG_CONVERSION_ERROR',
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDir.path}/temp');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'black_photo_$timestamp.png';
      final savedPath = '${tempDir.path}/$fileName';
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(byteData.buffer.asUint8List());

      image.dispose();

      return savedFile;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ImageProcessingException(
        'Erreur lors de la génération de la photo noire: ${e.toString()}',
        code: 'GENERATE_BLACK_ERROR',
      );
    }
  }
}
