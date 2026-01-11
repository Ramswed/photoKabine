// Modèle de données pour représenter une photo dans le journal. Supporte les photos simples et les bandes multiples, avec stockage persistant via Hive.
import 'package:hive/hive.dart';

part 'photo_model.g.dart';
@HiveType(typeId: 0)
class Photo extends HiveObject {
  @HiveField(0)
  final String imagePath;
  
  @HiveField(1)
  final DateTime dateTaken;
  
  @HiveField(2)
  final String id;
  
  @HiveField(3)
  final bool isStrip;
  
  @HiveField(4)
  final int photoCount;
  
  @HiveField(5)
  final List<String>? individualPhotoPaths;

  Photo({
    required this.imagePath,
    required this.dateTaken,
    required this.id,
    this.isStrip = false,
    this.photoCount = 1,
    this.individualPhotoPaths,
  });

  factory Photo.create({
    required String imagePath,
    DateTime? dateTaken,
    bool isStrip = false,
    int photoCount = 1,
    List<String>? individualPhotoPaths,
  }) {
    return Photo(
      imagePath: imagePath,
      dateTaken: dateTaken ?? DateTime.now(),
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      isStrip: isStrip,
      photoCount: photoCount,
      individualPhotoPaths: individualPhotoPaths,
    );
  }
}

