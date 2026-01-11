// Widget pour afficher une grille 3x2 de photos (6 photos)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'photo_segment_painter.dart';

class PhotoGrid3x2Widget extends StatelessWidget {
  final File file;
  final ColorFilter sepiaMatrix;
  final double whiteSeparatorWidth;
  final Future<ui.Image> Function(File) loadImage;

  const PhotoGrid3x2Widget({
    super.key,
    required this.file,
    required this.sepiaMatrix,
    required this.whiteSeparatorWidth,
    required this.loadImage,
  });

  Widget _buildPhotoSegment({
    required ui.Image fullImage,
    required double segmentHeight,
    required double segmentWidth,
    required int segmentIndex,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(
          right: segmentIndex % 2 == 0 ? 2.0 : 0.0,
          left: segmentIndex % 2 == 1 ? 2.0 : 0.0,
        ),
        child: ColorFiltered(
          colorFilter: sepiaMatrix,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final displayHeight = constraints.maxHeight;
              final displayWidth = constraints.maxWidth;
              final segmentAspectRatio = segmentWidth / segmentHeight;
              final naturalWidth = displayHeight * segmentAspectRatio;
              final finalWidth =
                  naturalWidth < displayWidth ? naturalWidth : displayWidth;

              return Center(
                child: SizedBox(
                  width: finalWidth,
                  height: displayHeight,
                  child: CustomPaint(
                    painter: PhotoSegmentPainter(
                      image: fullImage,
                      sourceRect: Rect.fromLTWH(
                        0,
                        segmentIndex * segmentHeight,
                        segmentWidth,
                        segmentHeight,
                      ),
                      destinationSize: Size(finalWidth, displayHeight),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: loadImage(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42.0),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.photoFrame,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  right: 8.0,
                  bottom: 40.0,
                  left: 8.0,
                ),
                child: Container(
                  width: double.infinity,
                  color: AppColors.grey800,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        }

        final fullImage = snapshot.data!;
        final stripHeight = fullImage.height.toDouble();
        final segmentHeight = stripHeight / 6;
        final segmentWidth = fullImage.width.toDouble();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42.0),
          child: Container(
            decoration: const BoxDecoration(
                color: AppColors.photoFrame,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                right: 8.0,
                bottom: 40.0,
                left: 8.0,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 0,
                            ),
                            Container(
                              width: whiteSeparatorWidth,
                              color: AppColors.photoFrame,
                            ),
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 3,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: whiteSeparatorWidth,
                        width: double.infinity,
                        color: AppColors.photoFrame,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 1,
                            ),
                            Container(
                              width: whiteSeparatorWidth,
                              color: AppColors.photoFrame,
                            ),
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 4,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: whiteSeparatorWidth,
                        width: double.infinity,
                        color: AppColors.photoFrame,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 2,
                            ),
                            Container(
                              width: whiteSeparatorWidth,
                              color: AppColors.photoFrame,
                            ),
                            _buildPhotoSegment(
                              fullImage: fullImage,
                              segmentHeight: segmentHeight,
                              segmentWidth: segmentWidth,
                              segmentIndex: 5,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
