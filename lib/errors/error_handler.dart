// Service centralisé pour gérer les erreurs de l'application
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_durations.dart';
import 'app_exceptions.dart';

class ErrorHandler {
  ErrorHandler._();

  static String getErrorMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString();
    } else {
      return 'Une erreur inattendue s\'est produite';
    }
  }

  static String getUserFriendlyMessage(dynamic error) {
    if (error is StorageException) {
      return 'Erreur de stockage : ${error.message}';
    } else if (error is CameraException) {
      return 'Erreur de caméra : ${error.message}';
    } else if (error is ImageProcessingException) {
      return 'Erreur de traitement d\'image : ${error.message}';
    } else if (error is PermissionException) {
      return 'Permission refusée : ${error.message}';
    } else if (error is GalleryException) {
      return 'Erreur de galerie : ${error.message}';
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'Une erreur s\'est produite. Veuillez réessayer.';
    }
  }

  static void showErrorSnackBar(
    BuildContext context,
    dynamic error, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final message = getUserFriendlyMessage(error);
    final screenHeight = MediaQuery.of(context).size.height;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: AppColors.errorBackground,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? AppDurations.snackbar,
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

  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    final screenHeight = MediaQuery.of(context).size.height;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: AppColors.snackbarBackground,
        behavior: SnackBarBehavior.floating,
        duration: duration ?? AppDurations.snackbar,
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

  static Future<T?> handleError<T>(
    BuildContext? context,
    Future<T> Function() operation, {
    T? defaultValue,
    bool showError = true,
  }) async {
    try {
      return await operation();
    } catch (error) {
      if (context != null && context.mounted && showError) {
        showErrorSnackBar(context, error);
      }
      return defaultValue;
    }
  }
}
