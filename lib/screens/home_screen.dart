// Écran d'accueil avec deux boutons interactifs (panneau et rideau). Gère la demande de permission caméra au démarrage et affiche l'animation du rideau lors du clic. Utilise la détection de transparence pour gérer les zones cliquables des images superposées.
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_assets.dart';
import '../constants/app_constants.dart';
import '../constants/app_durations.dart';
import '../services/camera_service.dart';
import 'journal_screen.dart';
import 'rideau_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<DualImageButtonState> _dualImageButtonKey =
      GlobalKey<DualImageButtonState>();
  bool _permissionRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestCameraPermission();
    });
  }

  Future<void> _requestCameraPermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    await Future.delayed(AppDurations.permissionRequestDelay);

    if (!mounted) return;

    final granted = await CameraService.requestPermission();

    if (!mounted) return;

    if (!granted) {
      final status = await Permission.camera.status;

      if (status.isPermanentlyDenied && mounted) {
        Future.delayed(AppDurations.permissionDialogDelay, () {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (context) => AlertDialog(
                title: const Text('Permission caméra requise'),
                content: const Text(
                  'L\'accès à la caméra est nécessaire pour utiliser cette fonctionnalité.\n\n'
                  'Pour activer la permission :\n'
                  'Réglages > Confidentialité & Sécurité > Caméra > Photobooth Animé',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Plus tard'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      openAppSettings();
                    },
                    child: const Text('Ouvrir les Réglages'),
                  ),
                ],
              ),
            );
          }
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
          Positioned.fill(
            child: Image.asset(
              AppAssets.backgroundHome,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DualImageButton(
              key: _dualImageButtonKey,
              panneauImagePath: AppAssets.panneau,
              rideauImagePath: AppAssets.rideau,
              onPanneauTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const JournalScreen(),
                  ),
                ).then((_) {
                  Future.delayed(AppDurations.navigationResetDelay, () {
                    _dualImageButtonKey.currentState?.resetPanneauClicked();
                  });
                });
              },
              onRideauTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RideauScreen(),
                  ),
                ).then((_) {
                  Future.delayed(AppDurations.navigationResetDelay, () {
                    _dualImageButtonKey.currentState?.resetRideauClicked();
                  });
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DualImageButton extends StatefulWidget {
  final String panneauImagePath;
  final String rideauImagePath;
  final VoidCallback onPanneauTap;
  final VoidCallback onRideauTap;

  const DualImageButton({
    super.key,
    required this.panneauImagePath,
    required this.rideauImagePath,
    required this.onPanneauTap,
    required this.onRideauTap,
  });

  @override
  DualImageButtonState createState() => DualImageButtonState();
}

class DualImageButtonState extends State<DualImageButton> {
  ui.Image? _panneauImage;
  ui.Image? _rideauImage;
  Uint8List? _panneauPixelData;
  Uint8List? _rideauPixelData;
  int? _panneauWidth;
  int? _panneauHeight;
  int? _rideauWidth;
  int? _rideauHeight;
  bool _isLoading = true;
  bool _isRideauClicked = false;
  bool _isPanneauClicked = false;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final ByteData panneauData =
          await rootBundle.load(widget.panneauImagePath);
      final Uint8List panneauBytes = panneauData.buffer.asUint8List();
      final ui.Codec panneauCodec =
          await ui.instantiateImageCodec(panneauBytes);
      final ui.FrameInfo panneauFrameInfo = await panneauCodec.getNextFrame();
      final ui.Image panneauImage = panneauFrameInfo.image;
      final ByteData? panneauByteData =
          await panneauImage.toByteData(format: ui.ImageByteFormat.rawRgba);

      final ByteData rideauData = await rootBundle.load(widget.rideauImagePath);
      final Uint8List rideauBytes = rideauData.buffer.asUint8List();
      final ui.Codec rideauCodec = await ui.instantiateImageCodec(rideauBytes);
      final ui.FrameInfo rideauFrameInfo = await rideauCodec.getNextFrame();
      final ui.Image rideauImage = rideauFrameInfo.image;
      final ByteData? rideauByteData =
          await rideauImage.toByteData(format: ui.ImageByteFormat.rawRgba);

      setState(() {
        _panneauImage = panneauImage;
        _panneauWidth = panneauImage.width;
        _panneauHeight = panneauImage.height;
        _panneauPixelData = panneauByteData?.buffer.asUint8List();

        _rideauImage = rideauImage;
        _rideauWidth = rideauImage.width;
        _rideauHeight = rideauImage.height;
        _rideauPixelData = rideauByteData?.buffer.asUint8List();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isPixelTransparent(Uint8List? pixelData, int? width, int? height,
      Offset localPosition, Size size) {
    if (pixelData == null || width == null || height == null) {
      return true;
    }

    final double scaleX = width / size.width;
    final double scaleY = height / size.height;

    final int x = (localPosition.dx * scaleX).round().clamp(0, width - 1);
    final int y = (localPosition.dy * scaleY).round().clamp(0, height - 1);

    final int pixelOffset = (y * width + x) * 4;
    if (pixelOffset + 3 >= pixelData.length) return true;

    final int alpha = pixelData[pixelOffset + 3];

    return alpha < 128;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: _isAnimating,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (_isAnimating) return;

          final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox == null) return;

          final Offset localPosition = renderBox.globalToLocal(event.position);
          final Size size = renderBox.size;

          final bool rideauTransparent = _isPixelTransparent(
            _rideauPixelData,
            _rideauWidth,
            _rideauHeight,
            localPosition,
            size,
          );

          if (!rideauTransparent && !_isAnimating && !_isRideauClicked) {
            setState(() {
              _isRideauClicked = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Future.delayed(AppDurations.buttonClickDelay, () {
                if (mounted && _isRideauClicked) {
                  setState(() {
                    _isAnimating = true;
                  });
                }
              });
            });
            return;
          }

          final bool panneauTransparent = _isPixelTransparent(
            _panneauPixelData,
            _panneauWidth,
            _panneauHeight,
            localPosition,
            size,
          );

          if (!panneauTransparent && !_isPanneauClicked) {
            setState(() {
              _isPanneauClicked = true;
            });
            Future.delayed(AppDurations.buttonClickDelay, () {
              if (mounted && _isPanneauClicked) {
                widget.onPanneauTap();
              }
            });
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: _isPanneauClicked
                  ? Image.asset(
                      AppAssets.panneauClicked,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  : Image.asset(
                      widget.panneauImagePath,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
            ),
            if (_isAnimating)
              Positioned.fill(
                child: RideauAnimation(
                  onAnimationComplete: () {
                    widget.onRideauTap();
                  },
                ),
              )
            else
              Positioned.fill(
                child: _isRideauClicked
                    ? Image.asset(
                        AppAssets.rideauClicked,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      )
                    : Image.asset(
                        widget.rideauImagePath,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
              ),
          ],
        ),
      ),
    );
  }

  void resetRideauClicked() {
    setState(() {
      _isRideauClicked = false;
      _isAnimating = false;
    });
  }

  void resetPanneauClicked() {
    setState(() {
      _isPanneauClicked = false;
    });
  }

  @override
  void dispose() {
    _panneauImage?.dispose();
    _rideauImage?.dispose();
    super.dispose();
  }
}

class RideauAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const RideauAnimation({
    super.key,
    required this.onAnimationComplete,
  });

  @override
  State<RideauAnimation> createState() => _RideauAnimationState();
}

class _RideauAnimationState extends State<RideauAnimation> {
  Timer? _timer;
  int _currentFrame = 1;
  static const int _totalFrames = AppConstants.rideauTotalFrames;
  static const Duration _frameDuration = AppDurations.rideauFrame;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
        _startAnimation();
      }
    });
  }

  void _startAnimation() {
    setState(() {
      _currentFrame = 1;
    });

    _timer = Timer.periodic(_frameDuration, (timer) {
      if (mounted) {
        setState(() {
          _currentFrame++;
          if (_currentFrame > _totalFrames) {
            _currentFrame = _totalFrames;
            timer.cancel();
            Future.delayed(AppDurations.rideauAnimationComplete, () {
              if (mounted) {
                widget.onAnimationComplete();
              }
            });
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getFramePath(int frameNumber) {
    return AppAssets.rideauAnimationFrame(frameNumber);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return Container(
        color: Colors.transparent,
        child: Image.asset(
          _getFramePath(1),
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      _getFramePath(_currentFrame),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Erreur frame $_currentFrame',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  error.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
