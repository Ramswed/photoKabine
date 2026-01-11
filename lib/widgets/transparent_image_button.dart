// Widget pour bouton avec détection de transparence des pixels
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';
import '../constants/app_durations.dart';

class TransparentImageButton extends StatefulWidget {
  final String imagePath;
  final String? clickedImagePath;
  final VoidCallback onTap;

  const TransparentImageButton({
    super.key,
    required this.imagePath,
    this.clickedImagePath,
    required this.onTap,
  });

  @override
  State<TransparentImageButton> createState() => _TransparentImageButtonState();
}

class _TransparentImageButtonState extends State<TransparentImageButton> {
  ui.Image? _image;
  Uint8List? _pixelData;
  int? _imageWidth;
  int? _imageHeight;
  bool _isLoading = true;
  bool _isClicked = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final ByteData data = await rootBundle.load(widget.imagePath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);

      setState(() {
        _image = image;
        _imageWidth = image.width;
        _imageHeight = image.height;
        _pixelData = byteData?.buffer.asUint8List();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isPixelTransparent(Offset localPosition, Size size) {
    if (_pixelData == null || _imageWidth == null || _imageHeight == null) {
      return true;
    }

    final double scaleX = _imageWidth! / size.width;
    final double scaleY = _imageHeight! / size.height;

    final int x =
        (localPosition.dx * scaleX).round().clamp(0, _imageWidth! - 1);
    final int y =
        (localPosition.dy * scaleY).round().clamp(0, _imageHeight! - 1);

    final int pixelOffset = (y * _imageWidth! + x) * 4;
    if (pixelOffset + 3 >= _pixelData!.length) return true;

    final int alpha = _pixelData![pixelOffset + 3];
    return alpha < AppConstants.photoAlphaThreshold;
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

        final screenHeight = size.height;
        final arrowCenterY = screenHeight / 2;
        const arrowHeight = 60;
        final isInArrowVerticalZone =
            (localPosition.dy >= arrowCenterY - arrowHeight / 2 - 10) &&
                (localPosition.dy <= arrowCenterY + arrowHeight / 2 + 10);

        if (isInArrowVerticalZone &&
            (localPosition.dx < 100 || localPosition.dx > size.width - 100)) {
          return;
        }

        final bool isTransparent = _isPixelTransparent(localPosition, size);

        if (!isTransparent) {
          if (widget.clickedImagePath != null && !_isClicked) {
            setState(() {
              _isClicked = true;
            });
            Future.delayed(AppDurations.buttonClickDelay, () {
              if (mounted && _isClicked) {
                widget.onTap();
              }
            });
          } else {
            widget.onTap();
          }
        }
      },
      child: Image.asset(
        _isClicked && widget.clickedImagePath != null
            ? widget.clickedImagePath!
            : widget.imagePath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}
