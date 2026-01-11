// Tests unitaires pour CameraService
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/services/camera_service.dart';

void main() {
  group('CameraService Tests', () {
    tearDown(() async {
      await CameraService.dispose();
    });

    test('isInitialized retourne false initialement', () {
      expect(CameraService.isInitialized, false);
    });

    test('controller retourne null initialement', () {
      expect(CameraService.controller, isNull);
    });

    test('dispose nettoie le controller', () async {
      await CameraService.dispose();
      expect(CameraService.controller, isNull);
      expect(CameraService.isInitialized, false);
    });

    test('takePicture retourne null si la caméra n\'est pas initialisée', () async {
      final result = await CameraService.takePicture();
      expect(result, isNull);
    });

    test('requestPermission gère les erreurs gracieusement', () async {
      final result = await CameraService.requestPermission();
      expect(result, isA<bool>());
    });
  });
}
