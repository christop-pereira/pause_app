import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  late Database db;

  Future<void> init() async {
    final path = join(await getDatabasesPath(), 'pause_v3.db');

    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE user(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            audioPath TEXT,
            photoPath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE triggers(
            id TEXT PRIMARY KEY,
            type TEXT,
            label TEXT,
            days TEXT,
            time TEXT,
            lat REAL,
            lng REAL,
            locationName TEXT,
            radius REAL DEFAULT 150,
            active INTEGER DEFAULT 1
          )
        ''');

        await db.execute('''
          CREATE TABLE events(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            triggerId TEXT,
            date TEXT,
            success INTEGER,
            reason TEXT
          )
        ''');
      },
    );
  }

  // ── User ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUser() async {
    final rows = await db.query('user', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveUser(String name, String? audioPath, {String? photoPath}) async {
    final existing = await getUser();
    if (existing == null) {
      await db.insert('user', {'name': name, 'audioPath': audioPath, 'photoPath': photoPath});
    } else {
      final data = {'name': name, 'audioPath': audioPath};
      if (photoPath != null) data['photoPath'] = photoPath;
      await db.update('user', data);
    }
  }

  Future<void> updateUserPhoto(String? photoPath) async {
    await db.update('user', {'photoPath': photoPath});
  }

  // ── Triggers ──────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTriggers() async {
    return await db.query('triggers', orderBy: 'rowid DESC');
  }

  Future<void> insertTrigger(Map<String, dynamic> data) async {
    await db.insert('triggers', data);
  }

  Future<void> updateTrigger(Map<String, dynamic> data) async {
    await db.update('triggers', data, where: 'id = ?', whereArgs: [data['id']]);
  }

  Future<void> updateTriggerActive(String id, int active) async {
    await db.update('triggers', {'active': active}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteTrigger(String id) async {
    await db.delete('triggers', where: 'id = ?', whereArgs: [id]);
  }

  // ── Events ────────────────────────────────────────────
  Future<void> insertEvent(Map<String, dynamic> data) async {
    await db.insert('events', data);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    return await db.query('events', orderBy: 'date DESC');
  }

  Future<List<Map<String, dynamic>>> getEventsLast7Days() async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return await db.query(
      'events',
      where: "date >= ?",
      whereArgs: [since.toIso8601String().substring(0, 10)],
      orderBy: 'date ASC',
    );
  }
}
