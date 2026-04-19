class Note {
  const Note({
    required this.id,
    required this.title,
    this.document = '[{"insert":"\\n"}]',
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;

  /// JSON-encoded Quill Delta.
  final String document;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Plain-text preview (first 120 chars of document content).
  String get preview {
    try {
      final text = document
          .replaceAll(RegExp(r'\{"insert"\s*:\s*"'), '')
          .replaceAll(RegExp(r'"\}'), '')
          .replaceAll(r'\n', ' ')
          .replaceAll(RegExp(r'[\[\],{}]'), '')
          .trim();
      return text.length > 120 ? '${text.substring(0, 120)}…' : text;
    } catch (_) {
      return '';
    }
  }

  String get timestampLabel {
    final now = DateTime.now();
    final diff = now.difference(updatedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${updatedAt.month}/${updatedAt.day}';
  }

  Note copyWith({
    String? id,
    String? title,
    String? document,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      document: document ?? this.document,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'document': document,
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      document: json['document'] as String? ?? '[{"insert":"\\n"}]',
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
