// Écran journal affichant toutes les photos prises dans un style cabine photo. Permet de naviguer entre les photos avec des flèches, applique un filtre sépia et gère l'affichage des bandes multiples avec séparations blanches.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import '../constants/app_colors.dart';
import '../constants/app_assets.dart';
import '../constants/app_constants.dart';
import '../constants/app_durations.dart';
import '../models/photo_model.dart';
import '../services/storage_service.dart';
import '../widgets/transparent_image_button.dart';
import '../widgets/photo_page_widget.dart';
import '../services/image_cache_service.dart';
import '../errors/error_handler.dart';
import '../errors/app_exceptions.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<Photo> _photos = [];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _preloadInitialImages();
  }

  void _preloadInitialImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_photos.isNotEmpty) {
        final preloadCount = _photos.length > AppConstants.initialPreloadCount
            ? AppConstants.initialPreloadCount
            : _photos.length;
        for (int i = 0; i < preloadCount; i++) {
          final photo = _photos[i];
          final file = File(photo.imagePath);
          if (file.existsSync()) {
            ImageCacheService.preloadImage(file);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _loadPhotos() {
    setState(() {
      _photos = StorageService.getAllPhotos();
      if (_photos.isNotEmpty && _currentPage >= _photos.length) {
        _currentPage = _photos.length - 1;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadPhotos();
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDurations.pageTransition,
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNextPage() {
    if (_currentPage < _photos.length - 1) {
      _pageController.nextPage(
        duration: AppDurations.pageTransition,
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    return '${dateFormat.format(dateTime)} ${timeFormat.format(dateTime)}';
  }

  void _preloadAdjacentImages(int currentIndex) {
    for (int i = -AppConstants.imagePreloadRange;
        i <= AppConstants.imagePreloadRange;
        i++) {
      final index = currentIndex + i;
      if (index >= 0 &&
          index < _photos.length &&
          index != currentIndex) {
        final photo = _photos[index];
        final file = File(photo.imagePath);
        if (file.existsSync()) {
          ImageCacheService.preloadImage(file);
        }
      }
    }
  }

  Future<void> _savePhotoToGallery() async {
    if (_photos.isEmpty || _currentPage >= _photos.length) return;

    final photo = _photos[_currentPage];
    final file = File(photo.imagePath);

    if (!file.existsSync()) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          const GalleryException('La photo n\'existe plus'),
        );
      }
      return;
    }

    await ErrorHandler.handleError(
      context,
      () async {
        final hasPermission = await Gal.hasAccess();
        if (!hasPermission) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            throw const PermissionException(
              'Permission d\'accès à la galerie refusée',
            );
          }
        }

        await Gal.putImageBytes(
          await file.readAsBytes(),
          name: 'photobooth_${photo.id}',
        );

        if (mounted) {
          ErrorHandler.showSuccessSnackBar(
            context,
            'Photo sauvegardée dans la galerie',
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final arrowTop = (screenHeight - AppConstants.arrowHeight) / 2;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssets.backgroundAlbum,
              fit: BoxFit.cover,
            ),
          ),
          if (_photos.isEmpty)
            const Center(
              child: Text(
                'Aucune photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            )
          else
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _photos.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _preloadAdjacentImages(index);
                },
                itemBuilder: (context, index) {
                  final photo = _photos[index];
                  return PhotoPageWidget(
                    key: ValueKey(photo.id),
                    photo: photo,
                    formatDateTime: _formatDateTime,
                  );
                },
                allowImplicitScrolling: false,
              ),
            ),
          Positioned.fill(
            child: TransparentImageButton(
              imagePath: AppAssets.flecheAlbum,
              clickedImagePath: AppAssets.flecheAlbumClicked,
              onTap: () {
                _loadPhotos();
                Navigator.pop(context);
              },
            ),
          ),
          if (_photos.isNotEmpty && _currentPage > 0)
            Positioned(
              left: 20,
              top: arrowTop,
              child: GestureDetector(
                onTap: _goToPreviousPage,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.arrowColor,
                  size: AppConstants.arrowIconSize,
                ),
              ),
            ),
          if (_photos.isNotEmpty && _currentPage < _photos.length - 1)
            Positioned(
              right: 20,
              top: arrowTop,
              child: GestureDetector(
                onTap: _goToNextPage,
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.arrowColor,
                  size: AppConstants.arrowIconSize,
                ),
              ),
            ),
          if (_photos.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _savePhotoToGallery,
                  child: Container(
                    width: AppConstants.downloadButtonSize,
                    height: AppConstants.downloadButtonSize,
                    decoration: const BoxDecoration(
                      color: AppColors.downloadButton,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.download,
                      color: AppColors.white,
                      size: AppConstants.downloadIconSize,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
