// Écran plein écran pour l'aperçu de la caméra et la prise de photos multiples. Gère un compte à rebours de 5 secondes avant chaque photo et combine les photos en bande verticale si nécessaire.
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../constants/app_durations.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../errors/error_handler.dart';
import 'dart:io';

class CameraPreviewScreen extends StatefulWidget {
  final int photoCount;

  const CameraPreviewScreen({
    super.key,
    required this.photoCount,
  });

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _cameraController;
  bool _isTakingPhotos = false;
  int _currentPhotoIndex = 0;
  int _countdown = AppConstants.countdownSeconds;
  double _countdownProgress = 1.0;
  Timer? _countdownTimer;
  List<File> _capturedPhotos = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (!CameraService.isInitialized) {
      final success = await CameraService.initialize();
      if (!success && mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
    }

    final controller = CameraService.controller;
    if (controller != null && mounted) {
      setState(() {
        _cameraController = controller;
      });
      _startCountdown();
    }
  }

  void _startCountdown() {
    _waitWithCountdown().then((_) {
      if (mounted) {
        _takeMultiplePhotos();
      }
    });
  }

  Future<void> _waitWithCountdown() async {
    _countdownTimer?.cancel();

    setState(() {
      _countdown = AppConstants.countdownSeconds;
      _countdownProgress = 1.0;
    });

    final completer = Completer<void>();
    final startTime = DateTime.now();
    const totalDuration = AppDurations.countdownTotal;

    _countdownTimer = Timer.periodic(AppDurations.countdownUpdate, (timer) {
      if (!mounted) {
        timer.cancel();
        completer.complete();
        return;
      }

      final elapsed = DateTime.now().difference(startTime);
      final remaining = totalDuration - elapsed;

      if (remaining.isNegative || remaining.inMilliseconds <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _countdown = 0;
            _countdownProgress = 0.0;
          });
        }
        completer.complete();
      } else {
        final secondsRemaining = remaining.inSeconds + 1;
        final progress = elapsed.inMilliseconds / totalDuration.inMilliseconds;

        if (mounted) {
          setState(() {
            _countdown = secondsRemaining;
            _countdownProgress = 1.0 - progress;
          });
        }
      }
    });

    return completer.future;
  }

  Future<void> _takeMultiplePhotos() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() {
      _isTakingPhotos = false;
      _currentPhotoIndex = 0;
      _capturedPhotos = [];
    });

    try {
      for (int i = 0; i < widget.photoCount; i++) {
        if (!mounted) break;

        setState(() {
          _isTakingPhotos = true;
          _currentPhotoIndex = i + 1;
        });

        final photoFile = await CameraService.takePicture();
        if (photoFile != null) {
          _capturedPhotos.add(photoFile);
        }

        if (i < widget.photoCount - 1) {
          setState(() {
            _isTakingPhotos = false;
          });
          await _waitWithCountdown();
        }
      }

      if (!mounted) return;

      if (widget.photoCount == 1 && _capturedPhotos.isNotEmpty) {
        await StorageService.savePhoto(_capturedPhotos[0]);
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            'Nouvelle entrée dans le journal !',
          );
        }
      } else if (_capturedPhotos.isNotEmpty) {
        final stripFile =
            await StorageService.combinePhotosIntoStrip(_capturedPhotos);
        final individualPaths = _capturedPhotos.map((f) => f.path).toList();
        await StorageService.savePhotoStrip(
          stripFile: stripFile,
          photoCount: widget.photoCount,
          individualPhotoPaths: individualPaths,
        );
        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            'Nouvelle entrée dans le journal !',
          );
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhotos = false;
          _currentPhotoIndex = 0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_cameraController != null &&
              _cameraController!.value.isInitialized)
            Positioned.fill(
              child: Transform.scale(
                scaleX: 1.20,
                scaleY: 1.0,
                alignment: Alignment.center,
                child: CameraPreview(_cameraController!),
              ),
            ),
          if (_isTakingPhotos)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Photo $_currentPhotoIndex/${widget.photoCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          if (!_isTakingPhotos && _cameraController != null && _countdown > 0)
            Positioned.fill(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: _countdownProgress,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$_countdown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
