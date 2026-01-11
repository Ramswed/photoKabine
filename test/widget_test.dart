// Tests d'intégration pour l'application principale
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photobooth/main.dart';
import 'package:photobooth/models/photo_model.dart';
import 'package:photobooth/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    Hive.registerAdapter(PhotoAdapter());
    await StorageService.init();
  });

  group('PhotoboothApp Tests', () {
    testWidgets('PhotoboothApp se lance sans erreur', (WidgetTester tester) async {
      await tester.pumpWidget(const PhotoboothApp());

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('PhotoboothApp a le titre correct', (WidgetTester tester) async {
      await tester.pumpWidget(const PhotoboothApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'PhotoKabine');
    });

    testWidgets('PhotoboothApp a debugShowCheckedModeBanner à false', (WidgetTester tester) async {
      await tester.pumpWidget(const PhotoboothApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
    });

    testWidgets('PhotoboothApp utilise Material3', (WidgetTester tester) async {
      await tester.pumpWidget(const PhotoboothApp());

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.useMaterial3, true);
    });
  });
}
