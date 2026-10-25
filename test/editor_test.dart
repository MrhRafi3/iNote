import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/models/checklist_item.dart';
import 'package:inote/data/models/note_model.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:inote/data/repositories/preferences_repository.dart';
import 'package:inote/presentation/screens/note_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
    await PreferencesRepository.instance.init();
  });

  testWidgets('NoteEditorScreen loads existing note and edits title and body', (
    WidgetTester tester,
  ) async {
    final note = await NotesRepository.instance.createNote(
      title: 'Initial Title',
      content: 'Initial Content',
      category: 'Ideas',
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(initialNote: note)),
    );
    await tester.pumpAndSettle();

    // Verify initial fields rendered
    expect(find.text('Initial Title'), findsOneWidget);
    expect(find.text('Initial Content'), findsOneWidget);
    expect(find.text('Ideas'), findsOneWidget);

    // Enter new title
    await tester.enterText(find.byType(TextField).first, 'Super Charged Title');
    await tester.pump(const Duration(milliseconds: 800));

    // Verify title text updated
    expect(find.text('Super Charged Title'), findsOneWidget);
  });

  testWidgets('NoteEditorScreen displays checklist items in checklist mode', (
    WidgetTester tester,
  ) async {
    final note = NoteModel(
      id: 99,
      title: 'Groceries',
      content: '',
      isChecklist: true,
      checklist: const [
        ChecklistItem(id: '1', text: 'Almond Milk', isDone: false),
        ChecklistItem(id: '2', text: 'Oats', isDone: true),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(home: NoteEditorScreen(initialNote: note)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Almond Milk'), findsOneWidget);
    expect(find.text('Oats'), findsOneWidget);
    expect(find.byType(Checkbox), findsNWidgets(2));
  });
}
