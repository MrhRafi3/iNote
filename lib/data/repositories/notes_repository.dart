import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/checklist_item.dart';
import '../models/note_filter.dart';
import '../models/note_model.dart';

/// Robust notes repository handling local persistence with SharedPreferences,
/// backward compatibility with legacy `notes_v2` storage, debounced autosave,
/// export/import, search, and reactive state notifications.
class NotesRepository extends ChangeNotifier {
  NotesRepository._();
  static final NotesRepository instance = NotesRepository._();

  static const String _kNotes = 'notes_v2';
  static const String _kIdCounter = 'notes_id_counter';
  static const String _kFolders = 'notes_folders_v1';
  static const String _kViewMode = 'app_view_mode';
  static const String _kSortOption = 'app_sort_option';

  List<NoteModel> _notes = [];
  int _idCounter = 0;
  List<String> _folders = ['Normal', 'Personal', 'Ideas', 'Work'];
  NotesViewMode _viewMode = NotesViewMode.grid;
  NoteSortOption _sortOption = NoteSortOption.dateModifiedNewest;
  bool _isInitialized = false;

  // Debounced auto-save timer
  Timer? _debounceSaveTimer;
  NoteModel? _pendingSaveNote;

  bool get isInitialized => _isInitialized;
  List<NoteModel> get allNotes => List.unmodifiable(_notes);
  List<String> get folders => List.unmodifiable(_folders);
  NotesViewMode get viewMode => _viewMode;
  NoteSortOption get sortOption => _sortOption;

  /// Active non-trash, non-archived notes
  List<NoteModel> get activeNotes =>
      _notes.where((n) => !n.isTrash && !n.archived).toList();

  /// Pinned active notes
  List<NoteModel> get pinnedNotes =>
      _notes.where((n) => !n.isTrash && !n.archived && n.pinned).toList();

  /// Favorite active notes
  List<NoteModel> get favoriteNotes =>
      _notes.where((n) => !n.isTrash && !n.archived && n.favorite).toList();

  /// Archived notes
  List<NoteModel> get archivedNotes =>
      _notes.where((n) => !n.isTrash && n.archived).toList();

  /// Trash notes
  List<NoteModel> get trashNotes => _notes.where((n) => n.isTrash).toList();

  /// Legacy compatibility getter for older code
  List<Map<String, dynamic>> get notes => _notes.map((n) => n.toMap()).toList();

  /// Initialize database and load persisted notes. Safe to call multiple times.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    _idCounter = prefs.getInt(_kIdCounter) ?? 0;

    // Load folders
    final savedFolders = prefs.getStringList(_kFolders);
    if (savedFolders != null && savedFolders.isNotEmpty) {
      _folders = savedFolders;
    }

    // Load view mode
    final savedViewMode = prefs.getString(_kViewMode);
    if (savedViewMode != null) {
      _viewMode = savedViewMode == 'list'
          ? NotesViewMode.list
          : NotesViewMode.grid;
    }

    // Load sort option
    final savedSortIndex = prefs.getInt(_kSortOption);
    if (savedSortIndex != null &&
        savedSortIndex < NoteSortOption.values.length) {
      _sortOption = NoteSortOption.values[savedSortIndex];
    }

    final raw = prefs.getString(_kNotes);
    if (raw == null || raw.isEmpty) {
      _notes = [];
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = <NoteModel>[];

      for (var item in list) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (map['id'] == null) {
            map['id'] = ++_idCounter;
          }
          final note = NoteModel.fromMap(map);
          parsed.add(note);
          if (note.id > _idCounter) {
            _idCounter = note.id;
          }
        }
      }

      _notes = parsed;
      await prefs.setInt(_kIdCounter, _idCounter);
    } catch (e) {
      debugPrint('Error decoding notes: $e');
      // If corrupted, do not clear data blindly; keep what parsed
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_notes.map((n) => n.toMap()).toList());
    await prefs.setString(_kNotes, jsonString);
    await prefs.setInt(_kIdCounter, _idCounter);
  }

  Future<int> _nextId() async {
    _idCounter++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kIdCounter, _idCounter);
    return _idCounter;
  }

  /// Create a new note
  Future<NoteModel> createNote({
    String title = '',
    String content = '',
    String category = 'Normal',
    List<String> tags = const [],
    bool pinned = false,
    bool favorite = false,
    int colorId = 0,
    bool isChecklist = false,
    List<ChecklistItem> checklist = const [],
  }) async {
    await flushPendingSave();
    final id = await _nextId();
    final now = DateTime.now();

    final newNote = NoteModel(
      id: id,
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
      favorite: favorite,
      archived: false,
      isTrash: false,
      colorId: colorId,
      isChecklist: isChecklist,
      checklist: checklist,
      createdAt: now,
      updatedAt: now,
    );

    _notes.insert(0, newNote);
    await _persist();
    notifyListeners();
    return newNote;
  }

  /// Legacy support for adding a map payload
  Future<void> addNote(Map<String, dynamic> payload) async {
    await createNote(
      title: (payload['title'] ?? '').toString(),
      content: (payload['content'] ?? payload['text'] ?? '').toString(),
      category: (payload['category'] ?? 'Normal').toString(),
      pinned: payload['pinned'] == true,
      colorId: (payload['colorId'] is int) ? payload['colorId'] as int : 0,
    );
  }

  /// Update an existing note immediately
  Future<void> updateNote(NoteModel note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index >= 0) {
      _notes[index] = note.copyWith(updatedAt: DateTime.now());
      await _persist();
      notifyListeners();
    }
  }

  /// Legacy support for updating note by id and map payload
  Future<void> updateNoteMap(int id, Map<String, dynamic> payload) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final existing = _notes[index];
      final updated = existing.copyWith(
        title: payload['title'] != null
            ? payload['title'].toString()
            : existing.title,
        content: payload['content'] != null
            ? payload['content'].toString()
            : (payload['text'] != null
                  ? payload['text'].toString()
                  : existing.content),
        category: payload['category'] != null
            ? payload['category'].toString()
            : existing.category,
        pinned: payload['pinned'] != null
            ? payload['pinned'] as bool
            : existing.pinned,
        favorite: payload['favorite'] != null
            ? payload['favorite'] as bool
            : existing.favorite,
        archived: payload['archived'] != null
            ? payload['archived'] as bool
            : existing.archived,
        isTrash: payload['isTrash'] != null
            ? payload['isTrash'] as bool
            : existing.isTrash,
        colorId: payload['colorId'] != null
            ? payload['colorId'] as int
            : existing.colorId,
        updatedAt: DateTime.now(),
      );
      _notes[index] = updated;
      await _persist();
      notifyListeners();
    }
  }

  /// Debounced auto-save for continuous typing in editor
  void scheduleDebouncedAutoSave(
    NoteModel note, {
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _pendingSaveNote = note;
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = Timer(delay, () async {
      await flushPendingSave();
    });
  }

  /// Safely flush any pending debounced autosave immediately
  Future<void> flushPendingSave() async {
    _debounceSaveTimer?.cancel();
    _debounceSaveTimer = null;
    if (_pendingSaveNote != null) {
      final note = _pendingSaveNote!;
      _pendingSaveNote = null;
      await updateNote(note);
    }
  }

  /// Toggle pin state
  Future<void> togglePin(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(
        pinned: !note.pinned,
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  /// Toggle favorite state
  Future<void> toggleFavorite(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(
        favorite: !note.favorite,
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  /// Toggle archive state
  Future<void> toggleArchive(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(
        archived: !note.archived,
        isTrash: false,
        updatedAt: DateTime.now(),
      );
      await _persist();
      notifyListeners();
    }
  }

  /// Move note to trash (safe delete with recovery)
  Future<void> moveToTrash(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(isTrash: true, updatedAt: DateTime.now());
      await _persist();
      notifyListeners();
    }
  }

  /// Restore note from trash
  Future<void> restoreFromTrash(int id) async {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      final note = _notes[index];
      _notes[index] = note.copyWith(isTrash: false, updatedAt: DateTime.now());
      await _persist();
      notifyListeners();
    }
  }

  /// Permanently delete note
  Future<void> permanentlyDelete(int id) async {
    _notes.removeWhere((n) => n.id == id);
    await _persist();
    notifyListeners();
  }

  /// Legacy support for removing a note
  Future<void> removeNote(int id) async {
    await permanentlyDelete(id);
  }

  /// Empty trash bin completely
  Future<void> emptyTrash() async {
    _notes.removeWhere((n) => n.isTrash);
    await _persist();
    notifyListeners();
  }

  /// Duplicate a note
  Future<NoteModel> duplicateNote(int id) async {
    final existing = _notes.firstWhere((n) => n.id == id);
    return await createNote(
      title: '${existing.title} (Copy)',
      content: existing.content,
      category: existing.category,
      tags: List.from(existing.tags),
      pinned: false,
      favorite: false,
      colorId: existing.colorId,
      isChecklist: existing.isChecklist,
      checklist: existing.checklist.map((e) => e.copyWith()).toList(),
    );
  }

  /// Filter & sort notes according to user criteria
  List<NoteModel> filterNotes(NoteFilter filter) {
    var result = _notes.where((n) {
      if (filter.onlyTrash) {
        return n.isTrash;
      }
      if (n.isTrash) return false;

      if (filter.onlyArchived) {
        return n.archived;
      }
      if (n.archived) return false;

      if (filter.onlyPinned && !n.pinned) return false;
      if (filter.onlyFavorite && !n.favorite) return false;

      if (filter.category != 'All' && n.category != filter.category) {
        return false;
      }

      if (filter.selectedTag != null && !n.tags.contains(filter.selectedTag)) {
        return false;
      }

      if (filter.searchQuery.trim().isNotEmpty) {
        final query = filter.searchQuery.trim().toLowerCase();
        final matchesTitle = n.title.toLowerCase().contains(query);
        final matchesContent = n.content.toLowerCase().contains(query);
        final matchesCategory = n.category.toLowerCase().contains(query);
        final matchesTags = n.tags.any((t) => t.toLowerCase().contains(query));
        final matchesChecklist = n.checklist.any(
          (item) => item.text.toLowerCase().contains(query),
        );

        if (!matchesTitle &&
            !matchesContent &&
            !matchesCategory &&
            !matchesTags &&
            !matchesChecklist) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort notes
    result.sort((a, b) {
      // Pinned notes always surface to top unless sorting trash/archive
      if (!filter.onlyTrash && !filter.onlyArchived) {
        if (a.pinned && !b.pinned) return -1;
        if (!a.pinned && b.pinned) return 1;
      }

      switch (filter.sortOption) {
        case NoteSortOption.dateModifiedNewest:
          return b.updatedAt.compareTo(a.updatedAt);
        case NoteSortOption.dateModifiedOldest:
          return a.updatedAt.compareTo(b.updatedAt);
        case NoteSortOption.dateCreatedNewest:
          return b.createdAt.compareTo(a.createdAt);
        case NoteSortOption.dateCreatedOldest:
          return a.createdAt.compareTo(b.createdAt);
        case NoteSortOption.titleAZ:
          return a.displayTitle.toLowerCase().compareTo(
            b.displayTitle.toLowerCase(),
          );
        case NoteSortOption.titleZA:
          return b.displayTitle.toLowerCase().compareTo(
            a.displayTitle.toLowerCase(),
          );
      }
    });

    return result;
  }

  /// Change view mode (grid vs list)
  Future<void> setViewMode(NotesViewMode mode) async {
    _viewMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kViewMode,
      mode == NotesViewMode.list ? 'list' : 'grid',
    );
  }

  /// Change sorting
  Future<void> setSortOption(NoteSortOption option) async {
    _sortOption = option;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kSortOption, option.index);
  }

  /// Add custom folder
  Future<void> addFolder(String name) async {
    final clean = name.trim();
    if (clean.isNotEmpty && !_folders.contains(clean)) {
      _folders.add(clean);
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kFolders, _folders);
    }
  }

  /// Delete folder (notes are reassigned to 'Normal')
  Future<void> deleteFolder(String name) async {
    if (name == 'Normal' || !_folders.contains(name)) return;
    _folders.remove(name);
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].category == name) {
        _notes[i] = _notes[i].copyWith(category: 'Normal');
      }
    }
    await _persist();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kFolders, _folders);
    notifyListeners();
  }

  /// Export all notes to JSON string for backup
  String exportToJson() {
    final payload = {
      'app': 'iNote',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'folders': _folders,
      'notes': _notes.map((n) => n.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Import notes from JSON backup string. Returns count of imported notes.
  Future<int> importFromJson(String rawJson, {bool replaceAll = false}) async {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final rawNotes = map['notes'] as List<dynamic>? ?? [];
      final rawFolders = map['folders'] as List<dynamic>? ?? [];

      if (rawFolders.isNotEmpty) {
        for (var f in rawFolders) {
          final str = f.toString().trim();
          if (str.isNotEmpty && !_folders.contains(str)) {
            _folders.add(str);
          }
        }
      }

      int count = 0;
      final imported = <NoteModel>[];

      for (var item in rawNotes) {
        if (item is Map) {
          final noteMap = Map<String, dynamic>.from(item);
          final id = await _nextId();
          noteMap['id'] = id;
          final note = NoteModel.fromMap(noteMap);
          imported.add(note);
          count++;
        }
      }

      if (replaceAll) {
        _notes = imported;
      } else {
        _notes.insertAll(0, imported);
      }

      await _persist();
      notifyListeners();
      return count;
    } catch (e) {
      debugPrint('Import error: $e');
      rethrow;
    }
  }

  /// Export single note as formatted Markdown
  String exportToMarkdown(NoteModel note) {
    final buffer = StringBuffer();
    buffer.writeln('# ${note.displayTitle}');
    buffer.writeln();
    buffer.writeln(
      '> Category: ${note.category} | Created: ${note.createdAt.toLocal()}',
    );
    buffer.writeln();

    if (note.isChecklist) {
      for (var item in note.checklist) {
        buffer.writeln('- [${item.isDone ? "x" : " "}] ${item.text}');
      }
    } else {
      buffer.writeln(note.content);
    }

    return buffer.toString();
  }
}

/// Backward compatibility alias so any legacy code referencing `NotesDB.instance`
/// continues to compile and work identically!
class NotesDB {
  NotesDB._();
  static final NotesRepository instance = NotesRepository.instance;
}
