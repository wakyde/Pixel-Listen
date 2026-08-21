import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';

class ListeningHistoryEntry {
  final String id;
  final String mediaPath;
  final String mediaName;
  final String? subtitlePath;
  final String? subtitleContent;
  final double progress;
  final double? duration;
  final String? episodeIndex;
  final String? episodeTitle;
  final DateTime lastPlayedAt;

  const ListeningHistoryEntry({
    required this.id,
    required this.mediaPath,
    required this.mediaName,
    this.subtitlePath,
    this.subtitleContent,
    required this.progress,
    this.duration,
    this.episodeIndex,
    this.episodeTitle,
    required this.lastPlayedAt,
  });
}

class ListeningHistoryNotifier extends StateNotifier<List<ListeningHistoryEntry>> {
  final AppDatabase _db;

  ListeningHistoryNotifier(this._db) : super([]) {
    Future.microtask(() => _loadFromDb());
  }

  String get _userId => AuthService.currentUser?.id ?? 'mock-user-001';

  Future<void> _loadFromDb() async {
    try {
      final query = _db.select(_db.listeningHistory)
        ..where((f) => f.userId.equals(_userId))
        ..orderBy([(f) => OrderingTerm.desc(f.lastPlayedAt)]);
      final rows = await query.get();
      state = rows.map((r) => ListeningHistoryEntry(
        id: r.id,
        mediaPath: r.mediaPath,
        mediaName: r.mediaName,
        subtitlePath: r.subtitlePath,
        subtitleContent: r.subtitleContent,
        progress: r.progress,
        duration: r.duration,
        episodeIndex: r.episodeIndex,
        episodeTitle: r.episodeTitle,
        lastPlayedAt: r.lastPlayedAt,
      )).toList();
    } catch (e, st) {
      debugPrint('[ListeningHistory] _loadFromDb failed: $e\n$st');
      state = [];
    }
  }

  Future<void> recordPlayback({
    required String mediaPath,
    required String mediaName,
    String? subtitlePath,
    String? subtitleContent,
    double progress = 0,
    double? duration,
    String? episodeIndex,
    String? episodeTitle,
  }) async {
    final now = DateTime.now();

    final isBlobUrl = mediaPath.startsWith('blob:');

    final existingQuery = _db.select(_db.listeningHistory)
      ..where((f) => f.userId.equals(_userId) & (isBlobUrl
          ? f.mediaName.equals(mediaName)
          : f.mediaPath.equals(mediaPath)));
    final existing = await existingQuery.getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.listeningHistory)
            ..where((f) => f.id.equals(existing.id)))
          .write(ListeningHistoryCompanion(
        mediaPath: Value(mediaPath),
        subtitlePath: Value(subtitlePath),
        subtitleContent: Value(subtitleContent),
        progress: Value(progress),
        duration: Value(duration),
        episodeIndex: Value(episodeIndex),
        episodeTitle: Value(episodeTitle),
        lastPlayedAt: Value(now),
      ));
    } else {
      await _db.into(_db.listeningHistory).insert(
        ListeningHistoryCompanion.insert(
          userId: _userId,
          mediaPath: mediaPath,
          mediaName: mediaName,
          subtitlePath: Value(subtitlePath),
          subtitleContent: Value(subtitleContent),
          progress: Value(progress),
          duration: Value(duration),
          episodeIndex: Value(episodeIndex),
          episodeTitle: Value(episodeTitle),
          lastPlayedAt: Value(now),
          createdAt: Value(now),
        ),
      );
    }

    await _loadFromDb();
  }

  Future<void> updateProgress({
    required String mediaPath,
    required double progress,
  }) async {
    final existingQuery = _db.select(_db.listeningHistory)
      ..where((f) => f.userId.equals(_userId) & f.mediaPath.equals(mediaPath));
    final existing = await existingQuery.getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.listeningHistory)
            ..where((f) => f.id.equals(existing.id)))
          .write(ListeningHistoryCompanion(
        progress: Value(progress),
        lastPlayedAt: Value(DateTime.now()),
      ));
    }
  }

  Future<void> removeEntry(String id) async {
    await (_db.delete(_db.listeningHistory)
          ..where((f) => f.id.equals(id)))
        .go();
    await _loadFromDb();
  }

  Future<void> clearHistory() async {
    await (_db.delete(_db.listeningHistory)
          ..where((f) => f.userId.equals(_userId)))
        .go();
    await _loadFromDb();
  }

  ListeningHistoryEntry? getEntryByMediaPath(String mediaPath) {
    try {
      return state.firstWhere((e) => e.mediaPath == mediaPath);
    } catch (e, st) {
      debugPrint('[ListeningHistory] getEntryByMediaPath failed: $e\n$st');
      return null;
    }
  }

  List<ListeningHistoryEntry> entriesByMediaName(String mediaName) {
    final lowerName = mediaName.toLowerCase();
    return state.where((e) => e.mediaName.toLowerCase().contains(lowerName)).toList();
  }
}

final listeningHistoryProvider =
    StateNotifierProvider<ListeningHistoryNotifier, List<ListeningHistoryEntry>>(
  (ref) {
    final db = getAppDatabase();
    return ListeningHistoryNotifier(db);
  },
);