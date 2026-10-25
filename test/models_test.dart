import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/models/checklist_item.dart';
import 'package:inote/data/models/note_color.dart';
import 'package:inote/data/models/note_model.dart';

void main() {
  group('NoteModel Tests', () {
    test('Correctly computes displayTitle from explicit title', () {
      final note = NoteModel(
        id: 1,
        title: 'Meeting Notes',
        content: 'Discussing roadmap for Q4',
        createdAt: DateTime(2026, 10, 22),
        updatedAt: DateTime(2026, 10, 22),
      );

      expect(note.displayTitle, 'Meeting Notes');
      expect(note.wordCount, 6);
    });

    test(
      'Correctly falls back displayTitle to first line of content if title is empty',
      () {
        final note = NoteModel(
          id: 2,
          title: '',
          content: 'Buy groceries\nMilk, eggs, and bread',
          createdAt: DateTime(2026, 10, 22),
          updatedAt: DateTime(2026, 10, 22),
        );

        expect(note.displayTitle, 'Buy groceries');
        expect(note.previewSnippet, 'Buy groceries\nMilk, eggs, and bread');
      },
    );

    test('Fallback to "Untitled Note" if both title and content are empty', () {
      final note = NoteModel(
        id: 3,
        title: '',
        content: '',
        createdAt: DateTime(2026, 10, 22),
        updatedAt: DateTime(2026, 10, 22),
      );

      expect(note.displayTitle, 'Untitled Note');
      expect(note.previewSnippet, 'No additional text');
    });

    test('100% Backward compatibility with legacy text map structure', () {
      final legacyMap = {
        'id': 42,
        'text': 'Legacy Title\nThis is the legacy note body.',
        'category': 'Ideas',
        'pinned': true,
        'createdAt': '2025-11-27T19:44:21.000',
      };

      final note = NoteModel.fromMap(legacyMap);

      expect(note.id, 42);
      expect(note.title, 'Legacy Title');
      expect(note.content, 'This is the legacy note body.');
      expect(note.category, 'Ideas');
      expect(note.pinned, true);
      expect(note.favorite, false);
      expect(note.archived, false);
      expect(note.isTrash, false);

      // Serializing back retains 'text' key for legacy compatibility
      final serialized = note.toMap();
      expect(serialized['text'], 'Legacy Title\nThis is the legacy note body.');
      expect(serialized['id'], 42);
      expect(serialized['category'], 'Ideas');
    });

    test('Checklist item toggling and preview snippet', () {
      final items = [
        const ChecklistItem(id: '1', text: 'Task 1', isDone: true),
        const ChecklistItem(id: '2', text: 'Task 2', isDone: false),
        const ChecklistItem(id: '3', text: 'Task 3', isDone: true),
      ];

      final note = NoteModel(
        id: 10,
        title: 'Sprint Checklist',
        content: '',
        isChecklist: true,
        checklist: items,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(note.previewSnippet, contains('2/3 completed'));
    });
  });

  group('NoteAccent Tests', () {
    test('Resolves proper accent by ID', () {
      expect(NoteAccent.fromId(1).name, 'Coral');
      expect(NoteAccent.fromId(2).name, 'Amber');
      expect(NoteAccent.fromId(3).name, 'Emerald');
      expect(NoteAccent.fromId(99), NoteAccent.defaultSlate);
    });
  });
}
