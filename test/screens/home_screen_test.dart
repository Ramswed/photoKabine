// Tests widget pour HomeScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/screens/home_screen.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    testWidgets('HomeScreen affiche l\'image de fond', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('HomeScreen contient un Scaffold avec fond noir', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('HomeScreen contient un Stack', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });
  });
}
