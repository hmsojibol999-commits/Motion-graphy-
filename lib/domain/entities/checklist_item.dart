class ChecklistItem {
  final String id;
  final String text;
  final bool done;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.done = false,
  });

  ChecklistItem copyWith({String? text, bool? done}) => ChecklistItem(
        id: id,
        text: text ?? this.text,
        done: done ?? this.done,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'text': text, 'done': done};

  factory ChecklistItem.fromJson(Map<String, dynamic> j) => ChecklistItem(
        id: j['id'] as String,
        text: j['text'] as String? ?? '',
        done: j['done'] as bool? ?? false,
      );
}
