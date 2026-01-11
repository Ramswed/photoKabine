// Service centralisé pour gérer l'initialisation de la caméra, les permissions et la prise de photos. Utilise la caméra frontale par défaut et gère automatiquement les cas de simulateur.
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class CameraService {
  static CameraController? _controller;
  static List<CameraDescription>? _cameras;
  static bool _initializationAttempted = false;

  static Future<bool> initialize() async {
    if (_controller != null && _controller!.value.isInitialized) {
      return true;
    }

    if (_initializationAttempted &&
        (_controller == null || !_controller!.value.isInitialized)) {
      return false;
    }

    _initializationAttempted = true;

    try {
      if (_controller != null) {
        await _controller!.dispose();
        _controller = null;
      }

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        return false;
      }

      CameraDescription frontCamera;
      if (_cameras!.length > 1) {
        frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras![_cameras!.length - 1],
        );
      } else {
        frontCamera = _cameras![0];
      }

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      return true;
    } catch (e) {
      await _controller?.dispose();
      _controller = null;
      return false;
    }
  }

  static CameraController? get controller => _controller;

  static Future<File?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  static Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  static bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  static Future<bool> requestPermission() async {
    try {
      PermissionStatus status = await Permission.camera.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        return false;
      }

      status = await Permission.camera.request();

      if (!status.isGranted) {
        return false;
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
