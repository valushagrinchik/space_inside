import 'package:flutter/material.dart';

class UnfoldSpan {
  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool code;

  const UnfoldSpan({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.code = false,
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'bold': bold,
    'italic': italic,
    'underline': underline,
    'strikethrough': strikethrough,
    'code': code,
  };

  factory UnfoldSpan.fromJson(Map<String, dynamic> json) {
    return UnfoldSpan(
      text: json['text'] as String,
      bold: (json['bold'] as bool?) ?? false,
      italic: (json['italic'] as bool?) ?? false,
      underline: (json['underline'] as bool?) ?? false,
      strikethrough: (json['strikethrough'] as bool?) ?? false,
      code: (json['code'] as bool?) ?? false,
    );
  }

  TextDecoration? get _decoration {
    if (underline && strikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (underline) return TextDecoration.underline;
    if (strikethrough) return TextDecoration.lineThrough;
    return null;
  }

  InlineSpan toInlineSpan({TextStyle? base}) {
    final style = (base ?? const TextStyle()).copyWith(
      fontWeight: bold ? FontWeight.bold : null,
      fontStyle: italic ? FontStyle.italic : null,
      decoration: _decoration,
      backgroundColor: code ? const Color(0xFFE0E0E0) : null,
    );
    return TextSpan(text: text, style: style);
  }
}

class UnfoldField {
  final String label;
  final String value;
  final List<UnfoldSpan> spans;

  const UnfoldField({
    required this.label,
    required this.value,
    this.spans = const [],
  });

  InlineSpan get formatted =>
      TextSpan(children: spans.map((s) => s.toInlineSpan()).toList());

  Map<String, dynamic> toJson() => {
    'label': label,
    'value': value,
    'spans': spans.map((s) => s.toJson()).toList(),
  };

  factory UnfoldField.fromJson(Map<String, dynamic> json) {
    final spansJson = (json['spans'] as List?)?.cast<Map<String, dynamic>>();
    return UnfoldField(
      label: json['label'] as String,
      value: json['value'] as String,
      spans: spansJson?.map(UnfoldSpan.fromJson).toList() ?? [],
    );
  }
}

class UnfoldEntry {
  final String id;
  final String name;
  final String content;
  final List<UnfoldField> fields;
  final String? periodName;

  const UnfoldEntry({
    required this.id,
    required this.name,
    this.content = '',
    this.fields = const [],
    this.periodName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'content': content,
    'fields': fields.map((f) => f.toJson()).toList(),
    'periodName': periodName,
  };

  factory UnfoldEntry.fromJson(Map<String, dynamic> json) {
    final fieldsJson = (json['fields'] as List?)?.cast<Map<String, dynamic>>();
    return UnfoldEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      content: (json['content'] as String?) ?? '',
      fields: fieldsJson?.map(UnfoldField.fromJson).toList() ?? [],
      periodName: json['periodName'] as String?,
    );
  }
}

class UnfoldPeriod {
  final String id;
  final String name;
  final DateTime? date;
  final String? context;
  final List<String> themes;
  final List<UnfoldEntry> entries;

  const UnfoldPeriod({
    required this.id,
    required this.name,
    this.date,
    this.context,
    this.themes = const [],
    this.entries = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'date': date?.toIso8601String(),
    'context': context,
    'themes': themes,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory UnfoldPeriod.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    final themesJson = (json['themes'] as List?)?.cast<String>();
    final entriesJson = (json['entries'] as List?)
        ?.cast<Map<String, dynamic>>();
    return UnfoldPeriod(
      id: json['id'] as String,
      name: json['name'] as String,
      date: dateStr == null ? null : DateTime.tryParse(dateStr),
      context: json['context'] as String?,
      themes: themesJson?.toList() ?? [],
      entries: entriesJson?.map(UnfoldEntry.fromJson).toList() ?? [],
    );
  }
}
