// Widget pour afficher une bande verticale de photos (2 photos ou plus)
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'photo_segment_painter.dart';

class PhotoStripWidget extends StatelessWidget {
  final File file;
  final int photoCount;
  final ColorFilter sepiaMatrix;
  final double whiteSeparatorWidth;
  final Future<ui.Image> Function(File) loadImage;

  const PhotoStripWidget({
    super.key,
    required this.file,
    required this.photoCount,
    required this.sepiaMatrix,
    required this.whiteSeparatorWidth,
    required this.loadImage,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image>(
      future: loadImage(file),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: photoCount == 2 ? 50.0 : 0.0,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.photoFrame,
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: 8.0,
                  right: photoCount == 2 ? 2.0 : 8.0,
                  bottom: 40.0,
                  left: photoCount == 2 ? 2.0 : 8.0,
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
        final segmentHeight = stripHeight / photoCount;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: photoCount == 2 ? 50.0 : 0.0,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.photoFrame,
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: 8.0,
                right: photoCount == 2 ? 2.0 : 8.0,
                bottom: 40.0,
                left: photoCount == 2 ? 2.0 : 8.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(photoCount * 2 - 1, (index) {
                  if (index.isEven) {
                    final photoIndex = index ~/ 2;
                    final segmentY = photoIndex * segmentHeight;
                    return Expanded(
                      child: ColorFiltered(
                        colorFilter: sepiaMatrix,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final segmentAspectRatio =
                                fullImage.width / segmentHeight;
                            final displayHeight = constraints.maxHeight;
                            final availableWidth = constraints.maxWidth;
                            final naturalWidth =
                                displayHeight * segmentAspectRatio;
                            final displayWidth = naturalWidth < availableWidth
                                ? naturalWidth
                                : availableWidth;

                            return Center(
                              child: SizedBox(
                                width: displayWidth,
                                height: displayHeight,
                                child: CustomPaint(
                                  painter: PhotoSegmentPainter(
                                    image: fullImage,
                                    sourceRect: Rect.fromLTWH(
                                      0,
                                      segmentY,
                                      fullImage.width.toDouble(),
                                      segmentHeight,
                                    ),
                                    destinationSize:
                                        Size(displayWidth, displayHeight),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } else {
                    return Container(
                      width: double.infinity,
                      height: whiteSeparatorWidth,
                      color: AppColors.photoFrame,
                    );
                  }
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
