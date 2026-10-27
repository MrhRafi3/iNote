import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/animations/spring_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/checklist_item.dart';
import '../../data/models/note_color.dart';
import '../../data/models/note_model.dart';
import '../../data/repositories/notes_repository.dart';
import '../widgets/editor_formatting_toolbar.dart';
import '../widgets/note_color_picker.dart';

enum SaveStatus { saved, saving, unsaved }

/// Upgraded writing experience with title & body editing, interactive checklists,
/// formatting tools, undo/redo, auto-save with status indicator, and color tinting.
class NoteEditorScreen extends StatefulWidget {
  final NoteModel? initialNote;
  final String? initialCategory;

  const NoteEditorScreen({super.key, this.initialNote, this.initialCategory});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _contentFocusNode;

  int? _noteId;
  late String _category;
  late bool _pinned;
  late bool _favorite;
  late bool _archived;
  late int _colorId;
  late bool _isChecklist;
  late List<ChecklistItem> _checklist;
  late DateTime _createdAt;
  late DateTime _updatedAt;

  SaveStatus _saveStatus = SaveStatus.saved;
  Timer? _statusResetTimer;

  // Undo / Redo history stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];
  bool _isUndoRedoAction = false;

  @override
  void initState() {
    super.initState();
    final note = widget.initialNote;

    _noteId = note?.id;
    _category = note?.category ?? widget.initialCategory ?? 'Normal';
    _pinned = note?.pinned ?? false;
    _favorite = note?.favorite ?? false;
    _archived = note?.archived ?? false;
    _colorId = note?.colorId ?? 0;
    _isChecklist = note?.isChecklist ?? false;
    _checklist = note != null
        ? note.checklist.map((item) => item.copyWith()).toList()
        : [];
    _createdAt = note?.createdAt ?? DateTime.now();
    _updatedAt = note?.updatedAt ?? DateTime.now();

    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _titleFocusNode = FocusNode();
    _contentFocusNode = FocusNode();

    _undoStack.add(_contentController.text);

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _statusResetTimer?.cancel();
    unawaited(NotesRepository.instance.flushPendingSave());
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onContentChanged);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    _triggerAutoSave();
  }

  void _onContentChanged() {
    if (!_isUndoRedoAction) {
      final current = _contentController.text;
      if (_undoStack.isEmpty || _undoStack.last != current) {
        _undoStack.add(current);
        if (_undoStack.length > 40) _undoStack.removeAt(0);
        _redoStack.clear();
      }
    }
    _triggerAutoSave();
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isUndoRedoAction = true;
      final current = _undoStack.removeLast();
      _redoStack.add(current);
      final previous = _undoStack.last;
      _contentController.value = TextEditingValue(
        text: previous,
        selection: TextSelection.collapsed(offset: previous.length),
      );
      _isUndoRedoAction = false;
      setState(() {});
      _triggerAutoSave();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isUndoRedoAction = true;
      final next = _redoStack.removeLast();
      _undoStack.add(next);
      _contentController.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
      _isUndoRedoAction = false;
      setState(() {});
      _triggerAutoSave();
    }
  }

  NoteModel _buildCurrentNoteModel() {
    return NoteModel(
      id: _noteId ?? 0,
      title: _titleController.text.trim(),
      content: _contentController.text,
      category: _category,
      pinned: _pinned,
      favorite: _favorite,
      archived: _archived,
      colorId: _colorId,
      isChecklist: _isChecklist,
      checklist: _checklist,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
    );
  }

  void _triggerAutoSave() {
    if (_saveStatus != SaveStatus.saving) {
      setState(() => _saveStatus = SaveStatus.saving);
    }

    final note = _buildCurrentNoteModel();

    if (_noteId == null) {
      // First save for new note if title or content non-empty
      if (note.title.isNotEmpty ||
          note.content.isNotEmpty ||
          _checklist.isNotEmpty) {
        NotesRepository.instance
            .createNote(
              title: note.title,
              content: note.content,
              category: _category,
              pinned: _pinned,
              favorite: _favorite,
              colorId: _colorId,
              isChecklist: _isChecklist,
              checklist: _checklist,
            )
            .then((created) {
              if (mounted) {
                setState(() {
                  _noteId = created.id;
                  _saveStatus = SaveStatus.saved;
                });
              }
            });
      }
    } else {
      // Debounce save for existing note
      NotesRepository.instance.scheduleDebouncedAutoSave(note);
      _statusResetTimer?.cancel();
      _statusResetTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() => _saveStatus = SaveStatus.saved);
        }
      });
    }
  }

  Future<void> _flushSave() async {
    final note = _buildCurrentNoteModel();
    if (_noteId == null) {
      if (note.title.isNotEmpty ||
          note.content.isNotEmpty ||
          _checklist.isNotEmpty) {
        final created = await NotesRepository.instance.createNote(
          title: note.title,
          content: note.content,
          category: _category,
          pinned: _pinned,
          favorite: _favorite,
          colorId: _colorId,
          isChecklist: _isChecklist,
          checklist: _checklist,
        );
        _noteId = created.id;
      }
    } else {
      await NotesRepository.instance.flushPendingSave();
      await NotesRepository.instance.updateNote(note);
    }
  }

  void _toggleChecklistMode() {
    setState(() {
      _isChecklist = !_isChecklist;
      if (_isChecklist && _checklist.isEmpty) {
        // Convert content lines into checklist items if available
        final lines = _contentController.text.split('\n');
        for (var line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty) {
            _checklist.add(
              ChecklistItem(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                text: trimmed.replaceFirst(RegExp(r'^[-*•]\s+'), ''),
                isDone: false,
              ),
            );
          }
        }
        if (_checklist.isEmpty) {
          _checklist.add(
            ChecklistItem(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              text: '',
              isDone: false,
            ),
          );
        }
      }
    });
    _triggerAutoSave();
  }

  void _addChecklistItem() {
    setState(() {
      _checklist.add(
        ChecklistItem(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          text: '',
          isDone: false,
        ),
      );
    });
    _triggerAutoSave();
  }

  void _removeChecklistItem(int index) {
    setState(() {
      _checklist.removeAt(index);
    });
    _triggerAutoSave();
  }

  void _toggleChecklistItem(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      final item = _checklist[index];
      _checklist[index] = item.copyWith(isDone: !item.isDone);
    });
    _triggerAutoSave();
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Note Accent',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              NoteColorPicker(
                selectedColorId: _colorId,
                onColorSelected: (id) {
                  setState(() => _colorId = id);
                  _triggerAutoSave();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFolderPicker() {
    final categories = NotesRepository.instance.folders;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Note Category',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(),
              ...categories.map(
                (c) => ListTile(
                  leading: Icon(
                    Icons.bookmark_outline_rounded,
                    size: 22,
                    color: c == _category ? AppColors.primary : null,
                  ),
                  title: Text(c),
                  trailing: c == _category
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    setState(() => _category = c);
                    _triggerAutoSave();
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = NoteAccent.fromId(_colorId);
    final scaffoldBg = _colorId == 0
        ? (isDark ? AppColors.darkBackground : AppColors.lightBackground)
        : accent.cardColor(isDark);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _flushSave();
        }
      },
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
            onPressed: () async {
              await _flushSave();
              if (context.mounted) {
                // Return payload for backward compatibility with older callers
                Navigator.pop(context, _buildCurrentNoteModel().toMap());
              }
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Save Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: AppRadii.borderFull,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _saveStatus == SaveStatus.saving
                          ? Icons.sync_rounded
                          : Icons.check_circle_rounded,
                      size: 11,
                      color: _saveStatus == SaveStatus.saving
                          ? Colors.orange
                          : AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _saveStatus == SaveStatus.saving ? 'Saving...' : 'Saved',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Color picker button
            IconButton(
              icon: Icon(
                Icons.palette_outlined,
                size: 22,
                color: accent.accentColor,
              ),
              tooltip: 'Note Accent',
              onPressed: _showColorPicker,
            ),
            // Favorite button
            IconButton(
              icon: Icon(
                _favorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: _favorite ? Colors.amber : null,
              ),
              tooltip: 'Favorite',
              onPressed: () {
                setState(() => _favorite = !_favorite);
                _triggerAutoSave();
              },
            ),
            // Pin button
            IconButton(
              icon: Icon(
                _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
                color: _pinned ? AppColors.primary : null,
              ),
              tooltip: 'Pin',
              onPressed: () {
                setState(() => _pinned = !_pinned);
                _triggerAutoSave();
              },
            ),
            // More menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) async {
                switch (val) {
                  case 'folder':
                    _showFolderPicker();
                    break;
                  case 'share':
                    final text =
                        '${_titleController.text}\n\n${_contentController.text}';
                    SharePlus.instance.share(
                      ShareParams(text: text, subject: _titleController.text),
                    );
                    break;
                  case 'delete':
                    final navigator = Navigator.of(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Move to Trash?'),
                        content: const Text(
                          'You can restore this note anytime from Trash.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(c, true),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && mounted) {
                      if (_noteId != null) {
                        await NotesRepository.instance.moveToTrash(_noteId!);
                      }
                      navigator.pop();
                    }
                    break;
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'folder',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_outline_rounded, size: 20),
                      const SizedBox(width: 10),
                      Text('Category: $_category'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20),
                      SizedBox(width: 10),
                      Text('Share Note'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Move to Trash',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Row: folder pill + character/word statistics
                    Row(
                      children: [
                        PressableScale(
                          onTap: _showFolderPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkSurfaceElevated
                                  : AppColors.lightSurfaceElevated,
                              borderRadius: AppRadii.borderSm,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bookmark_rounded,
                                  size: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_contentController.text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length} words • ${DateFormatter.formatSmart(_updatedAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? AppColors.darkTextTertiary
                                : AppColors.lightTextTertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Title TextField
                    TextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        height: 1.25,
                      ),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _contentFocusNode.requestFocus(),
                      decoration: InputDecoration(
                        hintText: 'Note Title',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          color: isDark ? Colors.white30 : Colors.black26,
                        ),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    // Body or Checklist View
                    if (_isChecklist) ...[
                      // Checklist items
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _checklist.length,
                        itemBuilder: (context, index) {
                          final item = _checklist[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: item.isDone,
                                  onChanged: (_) => _toggleChecklistItem(index),
                                  activeColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.text,
                                    onChanged: (val) {
                                      _checklist[index] = item.copyWith(
                                        text: val,
                                      );
                                      _triggerAutoSave();
                                    },
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: isDark
                                          ? AppColors.darkTextPrimary
                                          : AppColors.lightTextPrimary,
                                      decoration: item.isDone
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Task description...',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                  onPressed: () => _removeChecklistItem(index),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Add task item'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                        onPressed: _addChecklistItem,
                      ),
                    ] else ...[
                      // Regular Body TextField
                      TextField(
                        controller: _contentController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        minLines: 14,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.1,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Start writing your thoughts, ideas, or plans...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white30 : Colors.black26,
                            height: 1.6,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Formatting Toolbar
            EditorFormattingToolbar(
              textController: _contentController,
              isChecklistMode: _isChecklist,
              onToggleChecklist: _toggleChecklistMode,
              onUndo: _undo,
              onRedo: _redo,
              canUndo: _undoStack.length > 1,
              canRedo: _redoStack.isNotEmpty,
            ),
          ],
        ),
      ),
    );
  }
}
