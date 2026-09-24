import 'dart:convert';
import 'dart:developer';
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
  static const _tokenKey = 'notion_token';
  static const _databaseIdKey = 'notion_database_id';
  static const _autoSyncKey = 'notion_auto_sync';
  static const _apiVersion = '2022-06-28';

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
    final token = await _readSetting(_tokenKey);
    final databaseId = await _readSetting(_databaseIdKey);
    final autoSyncRaw = await _readSetting(_autoSyncKey);
    return NotionConfig(
      token: token,
      databaseId: databaseId,
      autoSync: autoSyncRaw.toLowerCase() == 'true',
    );
  }

  static Future<void> saveConfig(NotionConfig config) async {
    await _writeSetting(_tokenKey, config.token);
    await _writeSetting(_databaseIdKey, config.databaseId);
    await _writeSetting(_autoSyncKey, config.autoSync.toString());
  }

  static Future<void> onEntrySaved(JournalEntry entry) async {
    final config = await loadConfig();
    if (!config.autoSync || config.token.isEmpty || config.databaseId.isEmpty) {
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
    if (entry.id == null) return;
    final config = await loadConfig();
    if (config.token.isEmpty || config.databaseId.isEmpty) return;
    final pageId = await _createPage(config, entry);
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
    if (config.token.isEmpty || config.databaseId.isEmpty) return 0;
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'journal_entries',
      where: 'notion_synced = ?',
      whereArgs: [0],
      orderBy: 'created_at ASC',
    );
    final entries = rows.map(JournalEntry.fromMap).toList();
    for (final entry in entries) {
      await syncEntry(entry);
    }
    return entries.length;
  }

  static Future<String> _createPage(
    NotionConfig config,
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
        'parent': {'database_id': config.databaseId},
        'properties': {
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
