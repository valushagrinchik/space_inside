import 'package:sqflite/sqflite.dart';
import 'database.dart';

class SettingsService {
  static const _visibleToolsKey = 'visible_tools';

  static Future<Set<String>> loadVisibleTools(List<String> allIds) async {
    final db = await AppDatabase.instance;
    final allSet = allIds.toSet();
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [_visibleToolsKey],
    );
    if (rows.isEmpty) {
      await saveVisibleTools(allSet);
      return allSet;
    }

    final value = rows.first['value'] as String;
    var saved = value.split(',').where((s) => s.isNotEmpty).toSet();
    final missing = allSet.difference(saved);
    if (missing.isNotEmpty) {
      saved = saved.union(missing);
      await saveVisibleTools(saved);
    }
    return saved.intersection(allSet);
  }

  static Future<void> saveVisibleTools(Set<String> ids) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'settings',
      {'key': _visibleToolsKey, 'value': ids.join(',')},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
