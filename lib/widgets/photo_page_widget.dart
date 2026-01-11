// Widget pour afficher une page complète de photo dans le journal
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/photo_model.dart';
import '../services/image_cache_service.dart';
import 'photobooth_photo_widget.dart';

class PhotoPageWidget extends StatefulWidget {
  final Photo photo;
  final String Function(DateTime) formatDateTime;

  const PhotoPageWidget({
    super.key,
    required this.photo,
    required this.formatDateTime,
  });

  @override
  State<PhotoPageWidget> createState() => _PhotoPageWidgetState();
}

class _PhotoPageWidgetState extends State<PhotoPageWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImage();
    });
  }

  void _preloadImage() {
    final file = File(widget.photo.imagePath);
    if (file.existsSync()) {
      ImageCacheService.preloadImage(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.photo.imagePath);
    final exists = file.existsSync();
    final screenSize = MediaQuery.of(context).size;
    final maxPhotoWidth = screenSize.width * AppConstants.photoMaxWidthRatio;
    final maxPhotoHeight = screenSize.height * AppConstants.photoMaxHeightRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Flexible(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxPhotoWidth,
                        maxHeight: maxPhotoHeight,
                      ),
                      child: PhotoboothPhotoWidget(
                        file: file,
                        exists: exists,
                        photoCount: widget.photo.photoCount,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.formatDateTime(widget.photo.dateTaken),
                    style: GoogleFonts.poppins(
                      color: AppColors.dateText,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
