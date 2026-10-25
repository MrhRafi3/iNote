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
    'iNote app launches with header, navigation dock, and empty state',
    (WidgetTester tester) async {
      await tester.pumpWidget(const NotepadApp());
      await tester.pumpAndSettle();

      // Verify Title and author attribution
      expect(find.text('iNote'), findsOneWidget);
      expect(find.text('By Mrh Rafi'), findsOneWidget);

      // Verify Navigation Dock items
      expect(find.text('Notes'), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

      // Verify empty state view is visible initially
      expect(find.text('No notes in All'), findsOneWidget);

      // Verify Floating Action Button for creating note is present
      expect(find.byIcon(Icons.add_rounded), findsWidgets);
    },
  );

  testWidgets('Can tap on Folders tab and navigate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NotepadApp());
    await tester.pumpAndSettle();

    // Tap on Folders dock item
    await tester.tap(find.byIcon(Icons.folder_outlined));
    await tester.pumpAndSettle();

    // Verify Folders screen header
    expect(find.text('Folders'), findsWidgets);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Ideas'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });
}
