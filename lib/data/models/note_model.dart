import 'checklist_item.dart';
import 'note_color.dart';

/// Comprehensive domain model for a note, supporting title/body,
/// tags, checklists, favorites, pinning, trash, and color accents.
class NoteModel {
  final int id;
  final String title;
  final String content;
  final String category;
  final List<String> tags;
  final bool pinned;
  final bool favorite;
  final bool archived;
  final bool isTrash;
  final int colorId;
  final bool isChecklist;
  final List<ChecklistItem> checklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'Normal',
    this.tags = const [],
    this.pinned = false,
    this.favorite = false,
    this.archived = false,
    this.isTrash = false,
    this.colorId = 0,
    this.isChecklist = false,
    this.checklist = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  NoteAccent get accent => NoteAccent.fromId(colorId);

  /// Display title with fallback if empty
  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (content.trim().isNotEmpty) {
      final firstLine = content.trim().split('\n').first.trim();
      if (firstLine.length > 50) {
        return '${firstLine.substring(0, 47)}...';
      }
      return firstLine;
    }
    return 'Untitled Note';
  }

  /// Display preview snippet
  String get previewSnippet {
    if (isChecklist) {
      if (checklist.isEmpty) return 'No tasks';
      final completed = checklist.where((item) => item.isDone).length;
      final previewItems = checklist
          .take(2)
          .map((item) => (item.isDone ? '✓ ' : '○ ') + item.text)
          .join(' • ');
      return '$completed/${checklist.length} completed • $previewItems';
    }

    if (content.trim().isNotEmpty) {
      // Strip markdown tags so note cards display clean, natural text excerpts
      final clean = content
          .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
          .replaceAll(RegExp(r'^>\s*', multiLine: true), '')
          .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m.group(1) ?? '')
          .replaceAllMapped(RegExp(r'\*([^*]+)\*'), (m) => m.group(1) ?? '')
          .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m.group(1) ?? '')
          .trim();
      return clean.isNotEmpty ? clean : content.trim();
    }
    return 'No additional text';
  }

  /// Word and character count statistics
  int get wordCount {
    final text = '$title $content';
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }

  int get characterCount => ('$title $content').length;

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? pinned,
    bool? favorite,
    bool? archived,
    bool? isTrash,
    int? colorId,
    bool? isChecklist,
    List<ChecklistItem>? checklist,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      pinned: pinned ?? this.pinned,
      favorite: favorite ?? this.favorite,
      archived: archived ?? this.archived,
      isTrash: isTrash ?? this.isTrash,
      colorId: colorId ?? this.colorId,
      isChecklist: isChecklist ?? this.isChecklist,
      checklist: checklist ?? this.checklist,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    // Preserve legacy 'text' key for backward compatibility
    final legacyText = title.isNotEmpty
        ? (content.isNotEmpty ? '$title\n$content' : title)
        : content;

    return {
      'id': id,
      'title': title,
      'content': content,
      'text': legacyText, // Legacy key
      'category': category,
      'tags': tags,
      'pinned': pinned,
      'favorite': favorite,
      'archived': archived,
      'isTrash': isTrash,
      'colorId': colorId,
      'isChecklist': isChecklist,
      'checklist': checklist.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    // Graceful backward compatibility with old 'text' field
    String title = (map['title'] ?? '').toString();
    String content = (map['content'] ?? '').toString();

    if (title.isEmpty && content.isEmpty && map.containsKey('text')) {
      final rawText = (map['text'] ?? '').toString();
      final lines = rawText.split('\n');
      if (lines.length > 1) {
        title = lines.first.trim();
        content = lines.sublist(1).join('\n').trim();
      } else {
        title = rawText.trim();
        content = '';
      }
    }

    final now = DateTime.now();
    DateTime createdAt = now;
    if (map['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(map['createdAt'].toString());
      } catch (_) {}
    }

    DateTime updatedAt = createdAt;
    if (map['updatedAt'] != null) {
      try {
        updatedAt = DateTime.parse(map['updatedAt'].toString());
      } catch (_) {}
    }

    final rawTags = map['tags'];
    List<String> tags = [];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString()).toList();
    }

    final rawChecklist = map['checklist'];
    List<ChecklistItem> checklist = [];
    if (rawChecklist is List) {
      checklist = rawChecklist
          .whereType<Map>()
          .map((e) => ChecklistItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    return NoteModel(
      id: (map['id'] is int)
          ? map['id'] as int
          : int.tryParse(map['id'].toString()) ?? 0,
      title: title,
      content: content,
      category: (map['category'] ?? 'Normal').toString(),
      tags: tags,
      pinned: map['pinned'] == true,
      favorite: map['favorite'] == true,
      archived: map['archived'] == true,
      isTrash: map['isTrash'] == true,
      colorId: (map['colorId'] is int) ? map['colorId'] as int : 0,
      isChecklist: map['isChecklist'] == true,
      checklist: checklist,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
