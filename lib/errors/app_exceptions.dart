// Exceptions personnalisées pour l'application
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

class CameraException extends AppException {
  const CameraException(super.message, {super.code});
}

class ImageProcessingException extends AppException {
  const ImageProcessingException(super.message, {super.code});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code});
}

class GalleryException extends AppException {
  const GalleryException(super.message, {super.code});
}
