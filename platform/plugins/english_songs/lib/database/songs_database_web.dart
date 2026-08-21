import 'db_adapter.dart';

class _DbAdapterWeb implements DbAdapter {
  final Map<String, List<Map<String, dynamic>>> _store;

  _DbAdapterWeb(this._store);

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    var results = List<Map<String, dynamic>>.from(_store[table] ?? []);

    if (where != null && whereArgs != null) {
      final conditions = _parseWhere(where, whereArgs);
      results = results.where((row) {
        for (final cond in conditions) {
          if (row[cond.key] != cond.value) return false;
        }
        return true;
      }).toList();
    }

    if (orderBy != null) {
      final desc = orderBy.endsWith(' DESC');
      final col = desc ? orderBy.substring(0, orderBy.length - 5).trim() : orderBy.trim();
      results.sort((a, b) {
        final av = a[col];
        final bv = b[col];
        if (av == null) return desc ? 1 : -1;
        if (bv == null) return desc ? -1 : 1;
        final cmp = (av as Comparable).compareTo(bv);
        return desc ? -cmp : cmp;
      });
    }

    if (offset != null) {
      results = results.skip(offset).toList();
    }

    if (limit != null) {
      results = results.take(limit).toList();
    }

    if (columns != null && columns.isNotEmpty) {
      results = results.map((row) {
        final filtered = <String, dynamic>{};
        for (final col in columns) {
          if (row.containsKey(col)) {
            filtered[col] = row[col];
          }
        }
        return filtered;
      }).toList();
    }

    return results;
  }

  List<_WhereCond> _parseWhere(String where, List<dynamic> whereArgs) {
    final conditions = <_WhereCond>[];
    int argIdx = 0;

    final parts = where.split(' AND ');
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.contains(' = ?')) {
        final col = part.replaceAll(' = ?', '').trim();
        if (argIdx < whereArgs.length) {
          conditions.add(_WhereCond(col, whereArgs[argIdx]));
          argIdx++;
        }
      }
    }

    return conditions;
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> values) async {
    _store.putIfAbsent(table, () => []);
    _store[table]!.add(Map<String, dynamic>.from(values));
    return 1;
  }

  @override
  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    int count = 0;
    final rows = _store[table];
    if (rows == null) return 0;

    if (where != null && whereArgs != null) {
      final conditions = _parseWhere(where, whereArgs);
      for (final row in rows) {
        bool match = true;
        for (final cond in conditions) {
          if (row[cond.key] != cond.value) {
            match = false;
            break;
          }
        }
        if (match) {
          row.addAll(values);
          count++;
        }
      }
    }

    return count;
  }

  @override
  Future<int> delete(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    if (where == null || whereArgs == null) {
      final count = _store[table]?.length ?? 0;
      _store[table] = [];
      return count;
    }

    final rows = _store[table];
    if (rows == null) return 0;

    final conditions = _parseWhere(where, whereArgs);
    final before = rows.length;
    rows.removeWhere((row) {
      for (final cond in conditions) {
        if (row[cond.key] != cond.value) return false;
      }
      return true;
    });

    return before - rows.length;
  }

  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? args]) async {
    // Handle COUNT(*) queries
    if (sql.toUpperCase().contains('COUNT(*)')) {
      final tableMatch = RegExp(r'FROM\s+(\w+)', caseSensitive: false).firstMatch(sql);
      if (tableMatch != null) {
        final table = tableMatch.group(1)!;
        var rows = _store[table] ?? [];

        // Handle WHERE clause
        if (args != null && args.isNotEmpty) {
          final whereMatch = RegExp(r'WHERE\s+(.+?)(?:\s+GROUP|\s+ORDER|\s*$)', caseSensitive: false).firstMatch(sql);
          if (whereMatch != null) {
            final whereClause = whereMatch.group(1)!;
            final conditions = _parseWhere(whereClause, args);
            rows = rows.where((row) {
              for (final cond in conditions) {
                if (row[cond.key] != cond.value) return false;
              }
              return true;
            }).toList();
          }
        }

        return [{'cnt': rows.length}];
      }
    }

    return [];
  }
}

class _WhereCond {
  final String key;
  final dynamic value;
  _WhereCond(this.key, this.value);
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

    final store = <String, List<Map<String, dynamic>>>{
      'songs': [],
      'song_lines': [],
      'liaison_marks': [],
      'song_recordings': [],
      'song_scores': [],
      'song_favorites': [],
    };

    _db = _DbAdapterWeb(store);
    return _db!;
  }

  static Future<void> initialize() async {
    await database;
  }

  static String uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
  }
}