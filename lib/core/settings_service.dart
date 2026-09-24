import 'package:sqflite/sqflite.dart';
import 'database.dart';

class SettingsService {
  static const _visibleToolsKey = 'visible_tools';
  static const _knownToolsKey = 'known_tools';

  static Future<Set<String>> loadVisibleTools(List<String> allIds) async {
    final db = await AppDatabase.instance;
    final allSet = allIds.toSet();
    final visibleRow = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_visibleToolsKey],
    );
    final saved = visibleRow.isEmpty
        ? allSet
        : _parseSet(visibleRow.first['value'] as String);
    final known = await _loadSet(db, _knownToolsKey);
    final newIds = allSet.difference(known);
    final removedIds = known.difference(allSet);
    final visible = saved
        .union(newIds)
        .difference(removedIds)
        .intersection(allSet);
    await _saveSet(db, _visibleToolsKey, visible);
    await _saveSet(db, _knownToolsKey, allSet);
    return visible;
  }

  static Future<void> saveVisibleTools(Set<String> ids) async {
    final db = await AppDatabase.instance;
    await _saveSet(db, _visibleToolsKey, ids);
  }

  static String _visiblePracticesKey(String toolId) =>
      'visible_practices_$toolId';
  static String _knownPracticesKey(String toolId) => 'known_practices_$toolId';

  static Future<Set<String>> loadVisiblePractices(
    String toolId,
    List<String> allIds,
  ) async {
    final db = await AppDatabase.instance;
    final allSet = allIds.toSet();
    final key = _visiblePracticesKey(toolId);
    final visibleRow = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    final saved = visibleRow.isEmpty
        ? allSet
        : _parseSet(visibleRow.first['value'] as String);
    final known = await _loadSet(db, _knownPracticesKey(toolId));
    final newIds = allSet.difference(known);
    final removedIds = known.difference(allSet);
    final visible = saved
        .union(newIds)
        .difference(removedIds)
        .intersection(allSet);
    await _saveSet(db, key, visible);
    await _saveSet(db, _knownPracticesKey(toolId), allSet);
    return visible;
  }

  static Future<void> saveVisiblePractices(
    String toolId,
    Set<String> ids,
  ) async {
    final db = await AppDatabase.instance;
    await _saveSet(db, _visiblePracticesKey(toolId), ids);
  }

  static Future<Set<String>> _loadSet(Database db, String key) async {
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return {};
    return _parseSet(rows.first['value'] as String);
  }

  static Set<String> _parseSet(String value) {
    return value.split(',').where((s) => s.isNotEmpty).toSet();
  }

  static Future<void> _saveSet(Database db, String key, Set<String> ids) async {
    await db.insert('settings', {
      'key': key,
      'value': ids.join(','),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
