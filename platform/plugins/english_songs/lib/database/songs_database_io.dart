import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'db_adapter.dart';

class _DbAdapterIO implements DbAdapter {
  final Database _db;

  _DbAdapterIO(this._db);

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) {
    return _db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) {
    return _db.insert(table, values);
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) {
    return _db.update(table, values, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) {
    return _db.delete(table, where: where, whereArgs: whereArgs);
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) {
    return _db.rawQuery(sql, args);
  }
}

class SongsDatabase {
  static DbAdapter? _db;
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<DbAdapter> get database async {
    await ensureInitialized();
    if (_db != null) return _db!;

    final dbFolder = await getApplicationDocumentsDirectory();
    final path = p.join(dbFolder.path, 'english_songs.db');

    final sqfliteDb = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    _db = _DbAdapterIO(sqfliteDb);
    return _db!;
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE songs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        artist TEXT,
        format TEXT NOT NULL,
        has_timestamps INTEGER NOT NULL DEFAULT 1,
        audio_file_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE song_lines (
        id TEXT PRIMARY KEY,
        song_id TEXT NOT NULL,
        line_index INTEGER NOT NULL,
        start_time REAL,
        end_time REAL,
        text TEXT NOT NULL,
        text_zh TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE liaison_marks (
        id TEXT PRIMARY KEY,
        line_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        start_char INTEGER NOT NULL,
        end_char INTEGER NOT NULL,
        text TEXT NOT NULL,
        pronunciation TEXT NOT NULL,
        type TEXT NOT NULL,
        detected_by TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (line_id) REFERENCES song_lines(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE song_recordings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        song_id TEXT NOT NULL,
        line_id TEXT NOT NULL,
        recording_path TEXT,
        recognized_text TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE song_scores (
        id TEXT PRIMARY KEY,
        recording_id TEXT NOT NULL,
        total_score INTEGER NOT NULL,
        pronunciation_score INTEGER NOT NULL,
        rhythm_score INTEGER NOT NULL,
        liaison_score INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (recording_id) REFERENCES song_recordings(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE song_favorites (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        song_id TEXT,
        line_id TEXT,
        text TEXT NOT NULL,
        pronunciation TEXT NOT NULL,
        type TEXT NOT NULL,
        start_char INTEGER,
        end_char INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_songs_user ON songs(user_id)');
    await db.execute('CREATE INDEX idx_song_lines_song ON song_lines(song_id)');
    await db.execute('CREATE INDEX idx_liaison_marks_line ON liaison_marks(line_id)');
    await db.execute('CREATE INDEX idx_recordings_user ON song_recordings(user_id)');
    await db.execute('CREATE INDEX idx_favorites_user ON song_favorites(user_id)');
  }

  static Future<void> initialize() async {
    await database;
  }

  static String uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
  }
}