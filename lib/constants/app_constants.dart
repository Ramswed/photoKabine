// Constantes générales de l'application
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  static const double whiteSeparatorWidth = 4.0;
  static const int rideauTotalFrames = 21;
  static const int countdownSeconds = 5;
  static const double photoMaxWidthRatio = 0.5;
  static const double photoMaxHeightRatio = 0.4;
  static const double arrowHeight = 60.0;
  static const double downloadButtonSize = 60.0;
  static const double downloadIconSize = 28.0;
  static const double arrowIconSize = 50.0;
  static const int photoAlphaThreshold = 128;
  static const int imagePreloadRange = 2;
  static const int initialPreloadCount = 3;

  static const sepiaMatrix = ColorFilter.matrix([
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]);
}
