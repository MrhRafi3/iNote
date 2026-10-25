/// Represents a single item in a checklist note.
class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? id, String? text, bool? isDone}) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'isDone': isDone};
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: (map['id'] ?? DateTime.now().microsecondsSinceEpoch.toString())
          .toString(),
      text: (map['text'] ?? '').toString(),
      isDone: map['isDone'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          text == other.text &&
          isDone == other.isDone;

  @override
  int get hashCode => id.hashCode ^ text.hashCode ^ isDone.hashCode;
}
