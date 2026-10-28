import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inote/core/theme/app_colors.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:inote/data/repositories/preferences_repository.dart';
import 'package:inote/presentation/screens/app_shell.dart';
import 'package:inote/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
    await PreferencesRepository.instance.init();
  });

  group('SplashScreen Visual & Animation Tests', () {
    testWidgets('Renders solid brand background and vector custom painter', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(minDuration: Duration(milliseconds: 300)),
        ),
      );

      // Verify solid background color matches brand palette
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.lightBackground);

      // Verify custom painter is present
      expect(find.byType(CustomPaint), findsWidgets);
      final customPaint = tester.widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(SizedBox),
              matching: find.byType(CustomPaint),
            )
            .first,
      );
      expect(customPaint.painter is NoteVectorMarkPainter, true);

      // Verify exact app name 'iNote' wordmark is rendered
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasINote = richTexts.any((rt) => rt.text.toPlainText() == 'iNote');
      expect(hasINote, true);

      await tester.pumpAndSettle();
    });

    testWidgets(
      'Respects strict branding requirements: no developer credits or slogans',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(minDuration: Duration(milliseconds: 300)),
          ),
        );

        // Must NOT display developer name or personal credits on the splash screen
        expect(find.text('Mrh Rafi'), findsNothing);
        expect(find.text('Designed & Created by'), findsNothing);
        expect(find.text('By Mrh Rafi'), findsNothing);

        // Must NOT have marketing slogans or version numbers
        expect(find.text('v1.0.0'), findsNothing);
        expect(find.text('Version 1.0.0'), findsNothing);

        await tester.pumpAndSettle();
      },
    );

    testWidgets('Renders dark background in dark mode', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const SplashScreen(minDuration: Duration(milliseconds: 300)),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.darkBackground);

      await tester.pumpAndSettle();
    });

    testWidgets(
      'Smoothly transitions to destination screen and prevents back navigation',
      (WidgetTester tester) async {
        const destinationKey = ValueKey('destination_screen');
        final dummyDestination = Scaffold(
          key: destinationKey,
          body: const Center(child: Text('Home Content')),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: SplashScreen(
              minDuration: const Duration(milliseconds: 200),
              nextScreen: dummyDestination,
            ),
          ),
        );

        // Initially on SplashScreen
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byKey(destinationKey), findsNothing);

        // Advance through signature animation and fade transition
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();

        // After completion, destination is displayed
        expect(find.byKey(destinationKey), findsOneWidget);
        expect(find.text('Home Content'), findsOneWidget);

        // SplashScreen is replaced and disposed
        expect(find.byType(SplashScreen), findsNothing);
      },
    );

    testWidgets('Default launch transitions into AppShell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SplashScreen(minDuration: Duration(milliseconds: 200)),
        ),
      );

      await tester.pumpAndSettle();

      // Settles into AppShell
      expect(find.byType(AppShell), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
