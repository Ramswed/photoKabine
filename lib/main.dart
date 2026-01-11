// Point d'entrée de l'application. Initialise Hive pour le stockage local, configure l'orientation portrait et lance l'application.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/app_colors.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'models/photo_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(PhotoAdapter());
  await StorageService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const PhotoboothApp());
}

class PhotoboothApp extends StatelessWidget {
  const PhotoboothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhotoKabine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          surface: AppColors.background,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
