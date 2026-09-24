import 'dart:convert';

class JournalEntry {
  final int? id;
  final String practiceId;
  final String toolId;
  final DateTime createdAt;
  final Map<String, dynamic> fields;

  const JournalEntry({
    this.id,
    required this.practiceId,
    required this.toolId,
    required this.createdAt,
    required this.fields,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'practice_id': practiceId,
      'tool_id': toolId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'data': jsonEncode(fields),
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as int?,
      practiceId: map['practice_id'] as String,
      toolId: map['tool_id'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      fields: Map<String, dynamic>.from(
        jsonDecode(map['data'] as String) as Map,
      ),
    );
  }
}
