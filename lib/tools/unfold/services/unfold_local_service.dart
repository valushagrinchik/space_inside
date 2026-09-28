import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database.dart';
import '../models/unfold_models.dart';

class UnfoldLocalService {
  static const _cacheKey = 'unfold_data';

  static Future<List<UnfoldPeriod>?> load() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'unfold_cache',
      where: 'key = ?',
      whereArgs: [_cacheKey],
    );
    if (rows.isEmpty) return null;
    final data = rows.first['data'] as String;
    final list = jsonDecode(data) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map(UnfoldPeriod.fromJson)
        .toList();
  }

  static Future<DateTime?> lastSyncedAt() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'unfold_cache',
      columns: ['synced_at'],
      where: 'key = ?',
      whereArgs: [_cacheKey],
    );
    if (rows.isEmpty) return null;
    final ms = rows.first['synced_at'] as int?;
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> save(List<UnfoldPeriod> periods) async {
    final db = await AppDatabase.instance;
    final data = jsonEncode(periods.map((p) => p.toJson()).toList());
    await db.insert('unfold_cache', {
      'key': _cacheKey,
      'data': data,
      'synced_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> clear() async {
    final db = await AppDatabase.instance;
    await db.delete('unfold_cache', where: 'key = ?', whereArgs: [_cacheKey]);
  }
}
