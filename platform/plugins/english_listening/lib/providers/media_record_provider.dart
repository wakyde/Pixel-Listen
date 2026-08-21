import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';

class MediaRecord {
  final String id;
  final String categoryId;
  final String name;
  final String path;
  final String? subtitlePath;
  final String? subtitleContent;
  final String? thumbnailUrl;
  final double? duration;
  final DateTime createdAt;

  const MediaRecord({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.path,
    this.subtitlePath,
    this.subtitleContent,
    this.thumbnailUrl,
    this.duration,
    required this.createdAt,
  });
}

final mediaRecordsProvider =
    FutureProvider.family<List<MediaRecord>, String>((ref, categoryId) async {
  final db = getAppDatabase();
  final userId = AuthService.currentUser?.id ?? 'mock-user-001';
  final rows = await (db.select(db.mediaRecords)
        ..where((f) => f.userId.equals(userId) & f.categoryId.equals(categoryId))
        ..orderBy([(f) => OrderingTerm.desc(f.createdAt)]))
      .get();
  return rows.map((r) => MediaRecord(
        id: r.id,
        categoryId: r.categoryId,
        name: r.name,
        path: r.path,
        subtitlePath: r.subtitlePath,
        subtitleContent: r.subtitleContent,
        thumbnailUrl: r.thumbnailUrl,
        duration: r.duration,
        createdAt: r.createdAt,
      )).toList();
});

class MediaRecordNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  MediaRecordNotifier(this._db) : super(const AsyncValue.data(null));

  String get _userId => AuthService.currentUser?.id ?? 'mock-user-001';

  Future<void> saveRecord({
    required String categoryId,
    required String name,
    required String path,
    String? subtitlePath,
    String? subtitleContent,
    String? thumbnailUrl,
    double? duration,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isBlobUrl = path.startsWith('blob:');

      final existingQuery = _db.select(_db.mediaRecords)
        ..where((f) =>
            f.userId.equals(_userId) &
            f.categoryId.equals(categoryId) &
            (isBlobUrl ? f.name.equals(name) : f.path.equals(path)));
      final existing = await existingQuery.getSingleOrNull();

      if (existing != null) {
        await (_db.update(_db.mediaRecords)
              ..where((f) => f.id.equals(existing.id)))
            .write(MediaRecordsCompanion(
          path: Value(path),
          subtitlePath: Value(subtitlePath),
          subtitleContent: Value(subtitleContent),
          thumbnailUrl: Value(thumbnailUrl),
          duration: Value(duration),
          updatedAt: Value(DateTime.now()),
        ));
      } else {
        await _db.into(_db.mediaRecords).insert(
          MediaRecordsCompanion.insert(
            userId: _userId,
            categoryId: categoryId,
            name: name,
            path: path,
            subtitlePath: Value(subtitlePath),
            subtitleContent: Value(subtitleContent),
            thumbnailUrl: Value(thumbnailUrl),
            duration: Value(duration),
          ),
        );
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteRecord(String recordId) async {
    state = const AsyncValue.loading();
    try {
      await (_db.delete(_db.mediaRecords)
            ..where((f) => f.id.equals(recordId)))
          .go();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mediaRecordNotifierProvider =
    StateNotifierProvider<MediaRecordNotifier, AsyncValue<void>>((ref) {
  final db = getAppDatabase();
  return MediaRecordNotifier(db);
});