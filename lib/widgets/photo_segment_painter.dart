// CustomPainter pour dessiner un segment d'image dans une bande de photos
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class PhotoSegmentPainter extends CustomPainter {
  final ui.Image image;
  final Rect sourceRect;
  final Size destinationSize;

  PhotoSegmentPainter({
    required this.image,
    required this.sourceRect,
    required this.destinationSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.high;
    final destinationRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      paint,
    );
  }

  @override
  bool shouldRepaint(PhotoSegmentPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.sourceRect != sourceRect ||
        oldDelegate.destinationSize != destinationSize;
  }
}
