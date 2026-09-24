import '../models/journal_entry.dart';
import 'database.dart';

class JournalService {
  static Future<List<JournalEntry>> loadEntries(String practiceId) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      'journal_entries',
      where: 'practice_id = ?',
      whereArgs: [practiceId],
      orderBy: 'created_at DESC',
    );
    return rows.map(JournalEntry.fromMap).toList();
  }

  static Future<int> saveEntry(JournalEntry entry) async {
    final db = await AppDatabase.instance;
    return db.insert('journal_entries', entry.toMap()..remove('id'));
  }

  static Future<void> deleteEntry(int id) async {
    final db = await AppDatabase.instance;
    await db.delete('journal_entries', where: 'id = ?', whereArgs: [id]);
  }
}
