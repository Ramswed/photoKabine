// Widget pour afficher les photos dans le style photobooth avec filtres sépia et layouts adaptatifs
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../services/image_cache_service.dart';
import 'photo_grid_2x2_widget.dart';
import 'photo_grid_3x2_widget.dart';
import 'photo_strip_widget.dart';

class PhotoboothPhotoWidget extends StatelessWidget {
  final File file;
  final bool exists;
  final int photoCount;

  const PhotoboothPhotoWidget({
    super.key,
    required this.file,
    required this.exists,
    required this.photoCount,
  });

  Future<ui.Image> _loadImage(File file) async {
    return ImageCacheService.loadImage(file);
  }

  Widget _buildErrorWidget() {
    return Container(
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
          color: Colors.grey.shade800,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 80,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePhoto() {
    return Container(
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
        child: ColorFiltered(
          colorFilter: AppConstants.sepiaMatrix,
          child: Image.file(
            file,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: double.infinity,
                color: AppColors.grey800,
                child: const Center(
                  child: Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 80,
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
    if (!exists) {
      return _buildErrorWidget();
    }

    if (photoCount == 1) {
      return _buildSinglePhoto();
    }

    if (photoCount == 2) {
      return PhotoStripWidget(
        file: file,
        photoCount: photoCount,
        sepiaMatrix: AppConstants.sepiaMatrix,
        whiteSeparatorWidth: AppConstants.whiteSeparatorWidth,
        loadImage: _loadImage,
      );
    }

    if (photoCount == 4) {
      return PhotoGrid2x2Widget(
        file: file,
        sepiaMatrix: AppConstants.sepiaMatrix,
        whiteSeparatorWidth: AppConstants.whiteSeparatorWidth,
        loadImage: _loadImage,
      );
    }

    if (photoCount == 6) {
      return PhotoGrid3x2Widget(
        file: file,
        sepiaMatrix: AppConstants.sepiaMatrix,
        whiteSeparatorWidth: AppConstants.whiteSeparatorWidth,
        loadImage: _loadImage,
      );
    }

    return PhotoStripWidget(
      file: file,
      photoCount: photoCount,
      sepiaMatrix: AppConstants.sepiaMatrix,
      whiteSeparatorWidth: AppConstants.whiteSeparatorWidth,
      loadImage: _loadImage,
    );
  }
}
