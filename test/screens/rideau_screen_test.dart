// Tests widget pour RideauScreen
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photobooth/screens/rideau_screen.dart';

void main() {
  group('RideauScreen Widget Tests', () {
    testWidgets('RideauScreen affiche l\'image de fond cabine', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RideauScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('RideauScreen contient un Scaffold avec fond noir', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RideauScreen(),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.black);
    });

    testWidgets('RideauScreen contient un Stack', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RideauScreen(),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });
  });
}
