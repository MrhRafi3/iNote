import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/models/note_filter.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:inote/data/repositories/preferences_repository.dart';
import 'package:inote/presentation/screens/settings_screen.dart';
import 'package:inote/presentation/screens/trash_archive_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
    await PreferencesRepository.instance.init();
  });

  group('SettingsScreen Liquid Glass Redesign Tests', () {
    testWidgets('Renders all four organized sections with clear hierarchy', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Top section headers & items
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Haptic Micro-feedback'), findsOneWidget);

      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Default Notes Layout'), findsOneWidget);
      expect(find.text('Default Sort Order'), findsOneWidget);

      expect(find.text('DATA & STORAGE'), findsOneWidget);
      expect(find.text('Notes in Storage'), findsOneWidget);

      // Scroll to reveal lower items
      await tester.scrollUntilVisible(find.text('Clear All Notes'), 200);
      await tester.pumpAndSettle();
      expect(find.text('Trash & Archive'), findsOneWidget);
      expect(find.text('Export Backup (JSON)'), findsOneWidget);
      expect(find.text('Import Backup (JSON)'), findsOneWidget);
      expect(find.text('Clear All Notes'), findsOneWidget);

      // Scroll to reveal About section
      await tester.scrollUntilVisible(find.text('ABOUT'), 200);
      await tester.pumpAndSettle();
      expect(find.text('ABOUT'), findsOneWidget);
    });

    testWidgets('Theme selector switches theme mode immediately and persists', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final prefs = PreferencesRepository.instance;
      expect(prefs.themeMode, ThemeMode.system);

      // Tap 'Light' option
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, ThemeMode.light);

      // Tap 'Dark' option
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, ThemeMode.dark);

      // Tap 'System' option
      await tester.tap(find.text('System'));
      await tester.pumpAndSettle();
      expect(prefs.themeMode, ThemeMode.system);
    });

    testWidgets('Layout toggle updates NotesRepository viewMode immediately', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final repo = NotesRepository.instance;
      expect(repo.viewMode, NotesViewMode.grid);

      // Tap list view option in layout toggle
      await tester.tap(find.byIcon(Icons.view_agenda_rounded));
      await tester.pumpAndSettle();
      expect(repo.viewMode, NotesViewMode.list);

      // Tap grid view option
      await tester.tap(find.byIcon(Icons.grid_view_rounded));
      await tester.pumpAndSettle();
      expect(repo.viewMode, NotesViewMode.grid);
    });

    testWidgets('Haptic toggle updates PreferencesRepository hapticsEnabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final prefs = PreferencesRepository.instance;
      expect(prefs.hapticsEnabled, true);

      // Toggle switch off
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(prefs.hapticsEnabled, false);

      // Toggle switch back on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(prefs.hapticsEnabled, true);
    });

    testWidgets('Default Sort Order opens bottom sheet and selects option', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      final repo = NotesRepository.instance;
      expect(repo.sortOption, NoteSortOption.dateModifiedNewest);

      // Tap sort order tile
      await tester.tap(find.text('Default Sort Order'));
      await tester.pumpAndSettle();

      // Verify modal sheet is open with title
      expect(find.text('Default Sort Order'), findsWidgets);
      expect(find.text('Last Modified (Oldest)'), findsOneWidget);

      // Select 'Last Modified (Oldest)'
      await tester.tap(find.text('Last Modified (Oldest)'));
      await tester.pumpAndSettle();

      expect(repo.sortOption, NoteSortOption.dateModifiedOldest);
    });

    testWidgets(
      'Data and storage displays active and pinned notes statistics',
      (WidgetTester tester) async {
        final repo = NotesRepository.instance;
        await repo.createNote(title: 'Note 1', pinned: true);
        await repo.createNote(title: 'Note 2', pinned: false);

        await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('2 active • 1 pinned'), findsOneWidget);
        expect(find.text('2 total'), findsOneWidget);
      },
    );

    testWidgets('Trash & Archive navigates to TrashArchiveScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Trash & Archive'));
      await tester.pumpAndSettle();

      expect(find.byType(TrashArchiveScreen), findsOneWidget);
    });

    testWidgets('Developer credit Mrh Rafi is properly rendered inside About', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      // Scroll down to reveal About section
      await tester.scrollUntilVisible(find.text('Mrh Rafi'), 250);
      await tester.pumpAndSettle();

      expect(find.text('Mrh Rafi'), findsOneWidget);
      expect(find.text('Designed & Created by '), findsOneWidget);
      expect(find.text('iNote'), findsWidgets);
      expect(find.text('Version 2.0.0'), findsOneWidget);
      expect(find.text('Feedback & Support'), findsOneWidget);
    });

    testWidgets('Clear all notes triggers confirmation dialog', (
      WidgetTester tester,
    ) async {
      final repo = NotesRepository.instance;
      await repo.createNote(title: 'To Be Cleared');
      expect(repo.activeNotes.length, 1);

      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Clear All Notes'), 250);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Clear All Notes'));
      await tester.pumpAndSettle();

      // Verify dialog is presented
      expect(find.text('Clear All Notes?'), findsOneWidget);
      expect(
        find.text(
          'This will permanently delete all notes from storage. Make sure to export a backup first if you want to keep your data.',
        ),
        findsOneWidget,
      );

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Note still exists
      expect(repo.activeNotes.length, 1);
    });
  });
}
