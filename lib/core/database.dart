import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static Database? _db;

  static Future<Database> get instance async {
    _db ??= await _init();
    return _db!;
  }

  static Future<Database> _init() async {
    final dir = await getDatabasesPath();
    final dbPath = join(dir, 'space_inside.db');
    return openDatabase(
      dbPath,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE journal_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            practice_id TEXT NOT NULL,
            tool_id TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            data TEXT NOT NULL,
            notion_synced INTEGER NOT NULL DEFAULT 0,
            notion_page_id TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS journal_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              practice_id TEXT NOT NULL,
              tool_id TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              data TEXT NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE journal_entries ADD COLUMN notion_synced INTEGER NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE journal_entries ADD COLUMN notion_page_id TEXT
          ''');
        }
      },
    );
  }
}
