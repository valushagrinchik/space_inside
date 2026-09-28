import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/notion_service.dart';
import '../models/unfold_models.dart';

class _RelationInfo {
  final String name;
  final String linkedDatabaseId;

  const _RelationInfo(this.name, this.linkedDatabaseId);
}

String _normalizeId(String id) => id.replaceAll('-', '');

class UnfoldService {
  static final String _periodsDatabaseId =
      dotenv.env['UNFOLD_PERIODS_DATABASE_ID'] ?? '';

  static Future<List<UnfoldPeriod>> loadPeriods() async {
    final relation = await _findReflectionRelation();

    final periodsPages = await NotionService.queryDatabase(_periodsDatabaseId);
    final periodNamesById = <String, String>{};
    for (final page in periodsPages) {
      final properties = page['properties'] as Map<String, dynamic>;
      periodNamesById[page['id'] as String] = _titleText(properties);
    }

    final reflectionPages = await NotionService.queryDatabase(
      relation.linkedDatabaseId,
    );

    final entriesByPeriod = <String, List<UnfoldEntry>>{};
    for (final page in reflectionPages) {
      final periodIds = _relationIds(
        page['properties'] as Map<String, dynamic>,
        relation.name,
      );
      final entry = _parseEntry(
        page,
        periodName: periodIds.isEmpty ? null : periodNamesById[periodIds.first],
      );
      for (final periodId in periodIds) {
        entriesByPeriod.putIfAbsent(periodId, () => []).add(entry);
      }
    }

    return periodsPages
        .map(
          (page) =>
              _parsePeriod(page, entriesByPeriod[page['id'] as String] ?? []),
        )
        .toList();
  }

  static UnfoldPeriod _parsePeriod(
    Map<String, dynamic> page,
    List<UnfoldEntry> entries,
  ) {
    final properties = page['properties'] as Map<String, dynamic>;
    return UnfoldPeriod(
      id: page['id'] as String,
      name: _titleText(properties),
      date: _dateValue(properties),
      context: _selectName(properties),
      themes: _multiSelectNames(properties),
      entries: entries,
    );
  }

  static UnfoldEntry _parseEntry(
    Map<String, dynamic> page, {
    String? periodName,
  }) {
    final properties = page['properties'] as Map<String, dynamic>;
    return UnfoldEntry(
      id: page['id'] as String,
      name: _titleText(properties),
      content: _richText(properties),
      fields: _fieldsFromProperties(properties),
      periodName: periodName,
    );
  }

  static _RelationInfo? _findRelationProperty(
    Map<String, dynamic> schema, {
    String? targetDatabaseId,
  }) {
    final properties = schema['properties'] as Map<String, dynamic>? ?? {};
    for (final entry in properties.entries) {
      final prop = entry.value;
      if (prop['type'] == 'relation') {
        final relDbId =
            (prop['relation'] as Map<String, dynamic>)['database_id']
                as String?;
        if (targetDatabaseId == null ||
            _normalizeId(relDbId ?? '') == _normalizeId(targetDatabaseId)) {
          return _RelationInfo(entry.key, relDbId ?? '');
        }
      }
    }
    return null;
  }

  static Future<_RelationInfo> _findReflectionRelation() async {
    final periodsSchema = await NotionService.getDatabase(_periodsDatabaseId);
    final outgoing = _findRelationProperty(periodsSchema);
    if (outgoing != null && outgoing.linkedDatabaseId.isNotEmpty) {
      log(
        'Unfold: using relation from Periods to ${outgoing.linkedDatabaseId}',
      );
      return _RelationInfo(outgoing.name, outgoing.linkedDatabaseId);
    }

    final searchResults = await NotionService.search();
    log('Unfold: search found ${searchResults.length} databases');
    for (final db in searchResults) {
      final id = db['id'] as String;
      if (_normalizeId(id) == _normalizeId(_periodsDatabaseId)) continue;
      final schema = await NotionService.getDatabase(id);
      final incoming = _findRelationProperty(
        schema,
        targetDatabaseId: _periodsDatabaseId,
      );
      if (incoming != null) {
        log(
          'Unfold: found Reflection database $id with relation ${incoming.name}',
        );
        return _RelationInfo(incoming.name, id);
      }
    }
    throw Exception('Could not find a Reflection database linked to Periods');
  }

  static List<String> _relationIds(
    Map<String, dynamic> properties,
    String relationName,
  ) {
    final relation = properties[relationName]?['relation'] as List? ?? [];
    return relation
        .cast<Map<String, dynamic>>()
        .map((r) => r['id'] as String)
        .toList();
  }

  static String _titleText(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop['type'] == 'title') {
        final list = (prop['title'] as List).cast<Map<String, dynamic>>();
        return list.map((t) => t['plain_text'] as String? ?? '').join();
      }
    }
    return 'Untitled';
  }

  static DateTime? _dateValue(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop['type'] == 'date') {
        final start = prop['date']?['start'] as String?;
        if (start == null) continue;
        return DateTime.tryParse(start);
      }
    }
    return null;
  }

  static String? _selectName(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop['type'] == 'select') {
        return prop['select']?['name'] as String?;
      }
    }
    return null;
  }

  static List<String> _multiSelectNames(Map<String, dynamic> properties) {
    for (final prop in properties.values) {
      if (prop['type'] == 'multi_select') {
        final options = (prop['multi_select'] as List)
            .cast<Map<String, dynamic>>();
        return options.map((o) => o['name'] as String).toList();
      }
    }
    return [];
  }

  static String _richText(Map<String, dynamic> properties) {
    final buffer = StringBuffer();
    for (final prop in properties.values) {
      if (prop['type'] == 'rich_text') {
        final list = (prop['rich_text'] as List).cast<Map<String, dynamic>>();
        buffer.write(list.map((t) => t['plain_text'] as String? ?? '').join());
      }
    }
    return buffer.toString().trim();
  }

  static List<UnfoldSpan> _richTextSpans(dynamic prop) {
    final list = (prop['rich_text'] as List).cast<Map<String, dynamic>>();
    final spans = <UnfoldSpan>[];
    for (final item in list) {
      final text = item['plain_text'] as String? ?? '';
      if (text.isEmpty) continue;
      final annotations = item['annotations'] as Map<String, dynamic>? ?? {};
      spans.add(
        UnfoldSpan(
          text: text,
          bold: annotations['bold'] == true,
          italic: annotations['italic'] == true,
          underline: annotations['underline'] == true,
          strikethrough: annotations['strikethrough'] == true,
          code: annotations['code'] == true,
        ),
      );
    }
    return spans;
  }

  static List<UnfoldField> _fieldsFromProperties(
    Map<String, dynamic> properties,
  ) {
    const order = ['feelings', 'analysis', 'my questions', 'questions to me'];
    final fields = <UnfoldField>[];
    for (final entry in properties.entries) {
      final prop = entry.value;
      final type = prop['type'] as String?;
      if (type == 'title' || type == 'relation') continue;
      final value = _propertyValue(prop);
      var spans = const <UnfoldSpan>[];
      if (type == 'rich_text') {
        spans = _richTextSpans(prop);
      }
      if (value != null && value.isNotEmpty) {
        fields.add(UnfoldField(label: entry.key, value: value, spans: spans));
      }
    }
    fields.sort((a, b) {
      final aIndex = order.indexOf(a.label.toLowerCase());
      final bIndex = order.indexOf(b.label.toLowerCase());
      return (aIndex == -1 ? 1000 : aIndex).compareTo(
        bIndex == -1 ? 1000 : bIndex,
      );
    });
    return fields;
  }

  static String? _propertyValue(dynamic prop) {
    final type = prop['type'] as String?;
    switch (type) {
      case 'rich_text':
        final list = (prop['rich_text'] as List).cast<Map<String, dynamic>>();
        return list.map((t) => t['plain_text'] as String? ?? '').join().trim();
      case 'select':
        return prop['select']?['name'] as String?;
      case 'multi_select':
        final options = (prop['multi_select'] as List)
            .cast<Map<String, dynamic>>();
        return options.map((o) => o['name'] as String).join(', ');
      case 'status':
        return prop['status']?['name'] as String?;
      case 'date':
        final start = prop['date']?['start'] as String?;
        if (start == null) return null;
        final end = prop['date']?['end'] as String?;
        return end == null ? start : '$start — $end';
      case 'number':
        return prop['number']?.toString();
      case 'checkbox':
        return prop['checkbox'] == true ? 'Yes' : 'No';
      case 'url':
      case 'email':
      case 'phone_number':
        return prop[type] as String?;
      case 'relation':
        final relations = (prop['relation'] as List)
            .cast<Map<String, dynamic>>();
        return relations.isEmpty ? null : '${relations.length} linked';
      case 'people':
        final people = (prop['people'] as List).cast<Map<String, dynamic>>();
        return people.map((p) => (p['name'] as String?) ?? '').join(', ');
      case 'files':
        final files = (prop['files'] as List).cast<Map<String, dynamic>>();
        return files
            .map((f) {
              final url =
                  f['file']?['url'] as String? ??
                  f['external']?['url'] as String?;
              return url ?? f['name'] as String? ?? '';
            })
            .join(', ');
      case 'formula':
        return prop['formula']?['string']?.toString() ??
            prop['formula']?['number']?.toString() ??
            prop['formula']?['boolean']?.toString() ??
            prop['formula']?['date']?['start']?.toString();
      case 'created_by':
      case 'last_edited_by':
        final user = prop[type] as Map<String, dynamic>?;
        return user?['name'] as String?;
      default:
        return prop[type]?.toString();
    }
  }
}
