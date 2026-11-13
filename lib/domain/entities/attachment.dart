class Attachment {
  final String path;
  final String name;
  /// 'image' or 'audio'
  final String kind;

  const Attachment({
    required this.path,
    required this.name,
    required this.kind,
  });

  Map<String, dynamic> toJson() =>
      {'path': path, 'name': name, 'kind': kind};

  factory Attachment.fromJson(Map<String, dynamic> j) => Attachment(
        path: j['path'] as String,
        name: j['name'] as String? ?? '',
        kind: j['kind'] as String? ?? 'image',
      );
}
