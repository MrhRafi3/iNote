import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:inote/data/repositories/preferences_repository.dart';
import 'package:inote/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
    await PreferencesRepository.instance.init();
  });

  testWidgets(
    'iNote app launches with clean header, 3-tab liquid glass dock, and empty state',
    (WidgetTester tester) async {
      await tester.pumpWidget(const NotepadApp());
      await tester.pumpAndSettle();

      // Verify Title (without developer badge on header)
      expect(find.text('iNote'), findsOneWidget);
      expect(find.text('By Mrh Rafi'), findsNothing);

      // Verify Navigation Dock items
      expect(find.text('Notes'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify empty state view is visible initially
      expect(find.text('No notes in All'), findsOneWidget);

      // Verify Floating Action Button for creating note is present
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
    },
  );

  testWidgets('Can navigate to Pinned tab and view pinned notes', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pumpAndSettle();

    // Tap on Pinned dock item
    await tester.tap(find.byIcon(Icons.push_pin_outlined));
    await tester.pumpAndSettle();

    // Verify Pinned / Important notes header
    expect(find.text('Important Notes'), findsOneWidget);
    expect(find.text('No pinned notes'), findsOneWidget);
  });

  testWidgets(
    'Can navigate to Settings tab and view Mrh Rafi developer credit',
    (WidgetTester tester) async {
      await tester.pumpWidget(const NotepadApp());
      await tester.pumpAndSettle();

      // Tap on Settings dock item
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Verify Settings screen options
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Theme Mode'), findsOneWidget);

      // Scroll to reveal About section
      await tester.scrollUntilVisible(find.text('Mrh Rafi'), 200);
      await tester.pumpAndSettle();

      // Verify Mrh Rafi developer credit inside About section
      expect(find.text('Mrh Rafi'), findsOneWidget);
      expect(find.text('Designed & Created by '), findsOneWidget);
    },
  );
}
