// Écran de sélection du nombre de photos à prendre (1, 2, 4 ou 6). Gère la détection de simulateur et génère des photos noires si nécessaire. Utilise la détection de transparence pour gérer les boutons cliquables.
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../constants/app_assets.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import '../services/camera_service.dart';
import '../services/storage_service.dart';
import '../errors/error_handler.dart';
import 'camera_preview_screen.dart';

class RideauScreen extends StatefulWidget {
  const RideauScreen({super.key});

  @override
  State<RideauScreen> createState() => _RideauScreenState();
}

class _RideauScreenState extends State<RideauScreen> {
  Future<void> _takeMultiplePhotos(int count) async {
    bool isSimulator = false;
    if (!CameraService.isInitialized) {
      final success = await CameraService.initialize();
      if (!success) {
        isSimulator = true;
      }
    }

    if (isSimulator) {
      await _generateBlackPhotos(count);
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPreviewScreen(photoCount: count),
        ),
      );
    }
  }

  Future<void> _generateBlackPhotos(int count) async {
    if (!mounted) return;

    bool dialogShown = false;
    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
        dialogShown = true;
      }

      final List<File> blackPhotos = [];
      for (int i = 0; i < count; i++) {
        if (!mounted) break;
        final blackPhoto = await StorageService.generateBlackPhoto();
        blackPhotos.add(blackPhoto);
      }

      if (mounted && dialogShown) {
        Navigator.of(context).pop();
        dialogShown = false;
      }

      if (count == 1 && blackPhotos.isNotEmpty) {
        await StorageService.savePhoto(blackPhotos[0]);
        if (mounted) {
          final screenHeight = MediaQuery.of(context).size.height;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Nouvelle entrée dans le journal !',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              backgroundColor: AppColors.snackbarBackground,
              behavior: SnackBarBehavior.floating,
              duration: AppDurations.snackbar,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: screenHeight - 130,
              ),
            ),
          );
        }
      } else if (blackPhotos.isNotEmpty) {
        final stripFile =
            await StorageService.combinePhotosIntoStrip(blackPhotos);
        final individualPaths = blackPhotos.map((f) => f.path).toList();
        await StorageService.savePhotoStrip(
          stripFile: stripFile,
          photoCount: count,
          individualPhotoPaths: individualPaths,
        );
        if (mounted) {
          final screenHeight = MediaQuery.of(context).size.height;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Center(
                child: Text(
                  'Nouvelle entrée dans le journal !',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ),
              backgroundColor: AppColors.snackbarBackground,
              behavior: SnackBarBehavior.floating,
              duration: AppDurations.snackbar,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: EdgeInsets.only(
                top: 40,
                left: 20,
                right: 20,
                bottom: screenHeight - 130,
              ),
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted && dialogShown) {
        Navigator.of(context).pop();
      }
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
        Navigator.of(context).popUntil((route) => route.isFirst);
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
              AppAssets.backgroundCabine,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: _UnifiedTransparentButtons(
              photoButtons: [
                _ButtonInfo(
                  imagePath: AppAssets.boutonHg,
                  clickedImagePath: AppAssets.boutonHgClicked,
                  onTap: () => _takeMultiplePhotos(1),
                ),
                _ButtonInfo(
                  imagePath: AppAssets.boutonHd,
                  clickedImagePath: AppAssets.boutonHdClicked,
                  onTap: () => _takeMultiplePhotos(2),
                ),
                _ButtonInfo(
                  imagePath: AppAssets.boutonBg,
                  clickedImagePath: AppAssets.boutonBgClicked,
                  onTap: () => _takeMultiplePhotos(4),
                ),
                _ButtonInfo(
                  imagePath: AppAssets.boutonBd,
                  clickedImagePath: AppAssets.boutonBdClicked,
                  onTap: () => _takeMultiplePhotos(6),
                ),
              ],
              exitButton: _ButtonInfo(
                imagePath: AppAssets.flecheCabine,
                clickedImagePath: AppAssets.flecheCabineClicked,
                onTap: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ButtonInfo {
  final String imagePath;
  final String? clickedImagePath;
  final VoidCallback onTap;

  _ButtonInfo({
    required this.imagePath,
    this.clickedImagePath,
    required this.onTap,
  });
}

class _UnifiedTransparentButtons extends StatefulWidget {
  final List<_ButtonInfo> photoButtons;
  final _ButtonInfo exitButton;

  const _UnifiedTransparentButtons({
    required this.photoButtons,
    required this.exitButton,
  });

  @override
  State<_UnifiedTransparentButtons> createState() =>
      _UnifiedTransparentButtonsState();
}

class _UnifiedTransparentButtonsState
    extends State<_UnifiedTransparentButtons> {
  final Map<String, ui.Image> _images = {};
  final Map<String, Uint8List> _pixelData = {};
  final Map<String, int> _imageWidths = {};
  final Map<String, int> _imageHeights = {};
  bool _isLoading = true;
  bool _exitButtonClicked = false;
  String? _clickedPhotoButtonPath;

  @override
  void initState() {
    super.initState();
    _loadAllImages();
  }

  Future<void> _loadAllImages() async {
    try {
      final allButtons = [...widget.photoButtons, widget.exitButton];
      for (final button in allButtons) {
        final ByteData data = await rootBundle.load(button.imagePath);
        final Uint8List bytes = data.buffer.asUint8List();
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image image = frameInfo.image;
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.rawRgba);

        setState(() {
          _images[button.imagePath] = image;
          _imageWidths[button.imagePath] = image.width;
          _imageHeights[button.imagePath] = image.height;
          _pixelData[button.imagePath] =
              byteData?.buffer.asUint8List() ?? Uint8List(0);
        });
      }
      _isLoading = false;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isPixelTransparent(
    String imagePath,
    Offset localPosition,
    Size size,
  ) {
    final pixelData = _pixelData[imagePath];
    final imageWidth = _imageWidths[imagePath];
    final imageHeight = _imageHeights[imagePath];

    if (pixelData == null || imageWidth == null || imageHeight == null) {
      return true;
    }

    final double scaleX = imageWidth / size.width;
    final double scaleY = imageHeight / size.height;

    final int x = (localPosition.dx * scaleX).round().clamp(0, imageWidth - 1);
    final int y = (localPosition.dy * scaleY).round().clamp(0, imageHeight - 1);

    final int pixelOffset = (y * imageWidth + x) * 4;
    if (pixelOffset + 3 >= pixelData.length) return true;

    final int alpha = pixelData[pixelOffset + 3];
    return alpha < 128;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox == null) return;

        final Offset localPosition = renderBox.globalToLocal(event.position);
        final Size size = renderBox.size;

        for (int i = widget.photoButtons.length - 1; i >= 0; i--) {
          final button = widget.photoButtons[i];
          final isTransparent =
              _isPixelTransparent(button.imagePath, localPosition, size);

          if (!isTransparent) {
            if (button.clickedImagePath != null &&
                _clickedPhotoButtonPath == null) {
              setState(() {
                _clickedPhotoButtonPath = button.imagePath;
              });
              Future.delayed(AppDurations.buttonClickDelayLong, () {
                if (mounted && _clickedPhotoButtonPath == button.imagePath) {
                  setState(() {
                    _clickedPhotoButtonPath = null;
                  });
                  button.onTap();
                }
              });
            } else {
              button.onTap();
            }
            return;
          }
        }

        final exitTransparent = _isPixelTransparent(
            widget.exitButton.imagePath, localPosition, size);

        if (!exitTransparent) {
          if (widget.exitButton.clickedImagePath != null &&
              !_exitButtonClicked) {
            setState(() {
              _exitButtonClicked = true;
            });
            Future.delayed(AppDurations.buttonClickDelay, () {
              if (mounted && _exitButtonClicked) {
                widget.exitButton.onTap();
              }
            });
          } else {
            widget.exitButton.onTap();
          }
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              _exitButtonClicked && widget.exitButton.clickedImagePath != null
                  ? widget.exitButton.clickedImagePath!
                  : widget.exitButton.imagePath,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
          ...widget.photoButtons.map((button) {
            final isClicked = _clickedPhotoButtonPath == button.imagePath;
            return Positioned.fill(
              child: Image.asset(
                isClicked && button.clickedImagePath != null
                    ? button.clickedImagePath!
                    : button.imagePath,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }
}
