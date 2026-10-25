import 'package:flutter_test/flutter_test.dart';
import 'package:inote/data/models/note_filter.dart';
import 'package:inote/data/repositories/notes_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotesRepository.instance.init();
  });

  group('NotesRepository Tests', () {
    test('Create note, read note, and update note', () async {
      final repo = NotesRepository.instance;

      final created = await repo.createNote(
        title: 'Alpha Note',
        content: 'Alpha note content',
        category: 'Work',
      );

      expect(created.id, isPositive);
      expect(created.title, 'Alpha Note');
      expect(repo.activeNotes.length, 1);

      // Update
      await repo.updateNote(created.copyWith(title: 'Alpha Updated'));
      final updated = repo.activeNotes.first;
      expect(updated.title, 'Alpha Updated');
    });

    test('Pinning and unpinning notes', () async {
      final repo = NotesRepository.instance;

      final note = await repo.createNote(
        title: 'Important Note',
        content: 'Content',
      );

      expect(note.pinned, false);
      await repo.togglePin(note.id);

      expect(repo.pinnedNotes.length, 1);
      expect(repo.pinnedNotes.first.id, note.id);

      await repo.togglePin(note.id);
      expect(repo.pinnedNotes.isEmpty, true);
    });

    test('Moving to trash, restoring, and permanently deleting', () async {
      final repo = NotesRepository.instance;

      final note = await repo.createNote(title: 'Trash Me');
      expect(repo.activeNotes.length, 1);
      expect(repo.trashNotes.isEmpty, true);

      // Move to trash
      await repo.moveToTrash(note.id);
      expect(repo.activeNotes.isEmpty, true);
      expect(repo.trashNotes.length, 1);

      // Restore
      await repo.restoreFromTrash(note.id);
      expect(repo.activeNotes.length, 1);
      expect(repo.trashNotes.isEmpty, true);

      // Move to trash and permanently delete
      await repo.moveToTrash(note.id);
      await repo.permanentlyDelete(note.id);
      expect(repo.activeNotes.isEmpty, true);
      expect(repo.trashNotes.isEmpty, true);
    });

    test('Search and category filtering', () async {
      final repo = NotesRepository.instance;

      await repo.createNote(
        title: 'Flutter Roadmap',
        content: 'State management and testing',
        category: 'Ideas',
      );
      await repo.createNote(
        title: 'Weekly Groceries',
        content: 'Apples, milk, bread',
        category: 'Personal',
      );
      await repo.createNote(
        title: 'Client Invoice',
        content: 'Payment receipt #1042',
        category: 'Work',
      );

      // Search query filter
      final results1 = repo.filterNotes(
        const NoteFilter(searchQuery: 'groceries'),
      );
      expect(results1.length, 1);
      expect(results1.first.title, 'Weekly Groceries');

      // Category filter
      final results2 = repo.filterNotes(const NoteFilter(category: 'Work'));
      expect(results2.length, 1);
      expect(results2.first.title, 'Client Invoice');
    });

    test('Export to JSON and import from JSON backup', () async {
      final repo = NotesRepository.instance;

      await repo.createNote(title: 'Backup Note 1', content: 'Testing backup');
      await repo.createNote(
        title: 'Backup Note 2',
        content: 'Testing backup 2',
      );

      final exportedJson = repo.exportToJson();
      expect(exportedJson, contains('Backup Note 1'));
      expect(exportedJson, contains('Backup Note 2'));

      // Simulate clear and import
      final count = await repo.importFromJson(exportedJson);
      expect(count, 2);
    });

    test('Backward compatibility: NotesDB.instance returns map list', () async {
      final legacyDb = NotesDB.instance;
      expect(legacyDb.notes, isA<List<Map<String, dynamic>>>());
    });
  });
}
