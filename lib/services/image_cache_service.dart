// Service de cache pour les images décodées afin d'éviter les re-décodages et améliorer les performances
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

class ImageCacheService {
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(hours: 1);

  static Future<ui.Image> loadImage(File file) async {
    final filePath = file.path;

    if (_imageCache.containsKey(filePath)) {
      final cachedImage = _imageCache[filePath]!;
      final cacheTime = _cacheTimestamps[filePath]!;

      if (DateTime.now().difference(cacheTime) < cacheExpiration) {
        return cachedImage;
      }
      _removeFromCache(filePath);
    }

    final Uint8List bytes = await file.readAsBytes();
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frameInfo = await codec.getNextFrame();
    final ui.Image image = frameInfo.image;

    _addToCache(filePath, image);

    return image;
  }

  static void _addToCache(String filePath, ui.Image image) {
    if (_imageCache.length >= maxCacheSize) {
      _evictOldest();
    }

    _imageCache[filePath] = image;
    _cacheTimestamps[filePath] = DateTime.now();
  }

  static void _removeFromCache(String filePath) {
    final image = _imageCache.remove(filePath);
    _cacheTimestamps.remove(filePath);
    image?.dispose();
  }

  static void _evictOldest() {
    if (_cacheTimestamps.isEmpty) return;

    String? oldestPath;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestPath = entry.key;
      }
    }

    if (oldestPath != null) {
      _removeFromCache(oldestPath);
    }
  }

  static void clearCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  static int get cacheSize => _imageCache.length;

  static Future<void> preloadImage(File file) async {
    if (!file.existsSync()) return;
    try {
      await loadImage(file);
    } catch (e) {
    }
  }
}
