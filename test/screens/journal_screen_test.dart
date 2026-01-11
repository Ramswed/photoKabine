// Tests widget pour JournalScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/screens/journal_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:photobooth/models/photo_model.dart';
import 'package:photobooth/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JournalScreen Widget Tests', () {
    setUpAll(() async {
      await Hive.initFlutter();
      Hive.registerAdapter(PhotoAdapter());
    });

    setUp(() async {
      await StorageService.init();
      final box = await Hive.openBox<Photo>('photos_box');
      await box.clear();
    });

    tearDown(() async {
      final box = await Hive.openBox<Photo>('photos_box');
      await box.clear();
    });

    testWidgets('JournalScreen affiche "Aucune photo" quand la liste est vide',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JournalScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucune photo'), findsOneWidget);
    });

    testWidgets('JournalScreen contient un Scaffold avec fond noir',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JournalScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('JournalScreen contient l\'image de fond album',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: JournalScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    });
  });
}
