import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/journal_entry.dart';
import 'database.dart';

class NotionConfig {
  final String token;
  final String databaseId;
  final bool autoSync;

  const NotionConfig({
    this.token = '',
    this.databaseId = '',
    this.autoSync = false,
  });
}

class NotionService {
  static const _autoSyncKey = 'notion_auto_sync';
  static const _apiVersion = '2022-06-28';
  static String get _token => dotenv.env['NOTION_TOKEN'] ?? '';
  static String get _databaseId => dotenv.env['NOTION_DATABASE_ID'] ?? '';
  static String get _learningDatabaseId =>
      dotenv.env['LEARNING_NOTES_DATABASE_ID'] ?? '';

  static String _databaseIdFor(JournalEntry entry) =>
      entry.toolId == 'learning' ? _learningDatabaseId : _databaseId;

  static Future<String> _readSetting(String key) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isNotEmpty ? (rows.first['value'] as String? ?? '') : '';
  }

  static Future<void> _writeSetting(String key, String value) async {
    final db = await AppDatabase.instance;
    final existing = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('settings', {'key': key, 'value': value});
    } else {
      await db.update(
        'settings',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  static Future<NotionConfig> loadConfig() async {
    final autoSyncRaw = await _readSetting(_autoSyncKey);
    return NotionConfig(
      token: _token,
      databaseId: _databaseId,
      autoSync: autoSyncRaw.toLowerCase() == 'true',
    );
  }

  static Future<void> saveConfig(NotionConfig config) async {
    await _writeSetting(_autoSyncKey, config.autoSync.toString());
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final config = await loadConfig();
    if (config.token.isEmpty) {
      throw Exception('Notion token is not configured');
    }
    final headers = {
      'Authorization': 'Bearer ${config.token}',
      'Notion-Version': _apiVersion,
      'Content-Type': 'application/json',
    };
    final http.Response response;
    if (method == 'GET') {
      response = await http.get(uri, headers: headers);
    } else {
      response = await http.post(uri, headers: headers, body: jsonEncode(body));
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Notion API error ${response.statusCode}: ${response.body}',
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDatabase(String databaseId) async {
    return _request(
      'GET',
      Uri.parse('https://api.notion.com/v1/databases/$databaseId'),
    );
  }

  static Future<List<Map<String, dynamic>>> queryDatabase(
    String databaseId, {
    Map<String, dynamic>? filter,
    int pageSize = 100,
  }) async {
    final results = <Map<String, dynamic>>[];
    String? nextCursor;
    while (true) {
      final body = <String, dynamic>{'page_size': pageSize};
      if (filter != null) body['filter'] = filter;
      if (nextCursor != null) body['start_cursor'] = nextCursor;
      final data = await _request(
        'POST',
        Uri.parse('https://api.notion.com/v1/databases/$databaseId/query'),
        body: body,
      );
      final list = (data['results'] as List).cast<Map<String, dynamic>>();
      results.addAll(list);
      nextCursor = data['next_cursor'] as String?;
      if (data['has_more'] != true || nextCursor == null) break;
    }
    return results;
  }

  static Future<List<Map<String, dynamic>>> search({
    String query = '',
    int pageSize = 100,
  }) async {
    final results = <Map<String, dynamic>>[];
    String? nextCursor;
    while (true) {
      final body = <String, dynamic>{
        'page_size': pageSize,
        if (query.isNotEmpty) 'query': query,
        'filter': {'value': 'database', 'property': 'object'},
      };
      if (nextCursor != null) body['start_cursor'] = nextCursor;
      final data = await _request(
        'POST',
        Uri.parse('https://api.notion.com/v1/search'),
        body: body,
      );
      final list = (data['results'] as List).cast<Map<String, dynamic>>();
      results.addAll(list);
      nextCursor = data['next_cursor'] as String?;
      if (data['has_more'] != true || nextCursor == null) break;
    }
    return results;
  }

  static Future<void> onEntrySaved(JournalEntry entry) async {
    final config = await loadConfig();
    if (!config.autoSync ||
        config.token.isEmpty ||
        _databaseIdFor(entry).isEmpty) {
      return;
    }
    try {
      await syncEntry(entry);
    } catch (e, stack) {
      log('Notion sync error: $e');
      log('$stack');
    }
  }

  static Future<void> syncEntry(JournalEntry entry) async {
    if (entry.id == null || entry.toolId == 'mood') return;
    final config = await loadConfig();
    final databaseId = _databaseIdFor(entry);
    if (config.token.isEmpty || databaseId.isEmpty) return;
    final pageId = await _createPage(config, databaseId, entry);
    final db = await AppDatabase.instance;
    await db.update(
      'journal_entries',
      {'notion_synced': 1, 'notion_page_id': pageId},
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  static Future<int> syncAll() async {
    final config = await loadConfig();
    if (config.token.isEmpty) return 0;
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'journal_entries',
      where: 'notion_synced = ? AND tool_id != ?',
      whereArgs: [0, 'mood'],
      orderBy: 'created_at ASC',
    );
    final entries = rows.map(JournalEntry.fromMap).toList();
    for (final entry in entries) {
      await syncEntry(entry);
    }
    return entries.length;
  }

  static Future<String> createPage({
    required String databaseId,
    required Map<String, dynamic> properties,
  }) async {
    final data = await _request(
      'POST',
      Uri.parse('https://api.notion.com/v1/pages'),
      body: {
        'parent': {'database_id': databaseId},
        'properties': properties,
      },
    );
    return data['id'] as String;
  }

  static Future<String> _createPage(
    NotionConfig config,
    String databaseId,
    JournalEntry entry,
  ) async {
    final response = await http.post(
      Uri.parse('https://api.notion.com/v1/pages'),
      headers: {
        'Authorization': 'Bearer ${config.token}',
        'Notion-Version': _apiVersion,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'parent': {'database_id': databaseId},
        'properties': entry.toolId == 'learning'
            ? _learningProperties(entry)
            : {
                'Name': {
                  'title': [
                    {
                      'text': {'content': _pageTitle(entry)},
                    },
                  ],
                },
                'Content': {
                  'rich_text': [
                    {
                      'text': {'content': _pageContent(entry)},
                    },
                  ],
                },
              },
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Notion API error ${response.statusCode}: ${response.body}',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['id'] as String;
  }

  static Map<String, dynamic> _learningProperties(JournalEntry entry) {
    final fields = entry.fields;
    final isBook = entry.practiceId == 'book';
    final title = isBook
        ? fields['title']?.toString() ?? ''
        : fields['text']?.toString() ?? '';
    final note = isBook
        ? ''
        : fields['text']?.toString() ?? title;
    final rawTags = fields['tags']?.toString() ?? '';
    final tags = rawTags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (isBook) tags.add('book');
    final author = fields['author']?.toString() ?? '';
    return {
      'Name': {
        'title': [
          {
            'text': {'content': title},
          },
        ],
      },
      'Author': {
        'rich_text': [
          {
            'text': {'content': author},
          },
        ],
      },
      'Note': {
        'rich_text': [
          {
            'text': {'content': note},
          },
        ],
      },
      'Tags': {
        'multi_select': tags.map((t) => {'name': t}).toList(),
      },
    };
  }

  static String _pageTitle(JournalEntry entry) {
    final practiceTitle = _practiceTitle(entry.practiceId);
    final date = _formatDate(entry.createdAt);
    return '$practiceTitle · $date';
  }

  static String _practiceTitle(String practiceId) {
    switch (practiceId) {
      case 'self_trust':
        return 'Self-trust';
      case 'gratitude':
        return 'Gratitude';
      case 'book':
        return 'Book';
      case 'book_quote':
        return 'Quote';
      default:
        return practiceId;
    }
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  static String _pageContent(JournalEntry entry) {
    final buffer = StringBuffer();
    buffer.writeln('Practice: ${_practiceTitle(entry.practiceId)}');
    buffer.writeln('Date: ${_formatDate(entry.createdAt)}');
    buffer.writeln();
    for (final key in entry.fields.keys) {
      buffer.writeln('$key: ${entry.fields[key]}');
    }
    return buffer.toString();
  }
}
