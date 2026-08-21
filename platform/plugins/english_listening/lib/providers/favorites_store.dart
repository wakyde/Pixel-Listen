import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';

import '../services/favorites_api_service.dart';

enum FavoriteType { word, phrase, sentence }

class FavoriteEntry {
  final String id;
  final FavoriteType type;
  final String text;
  final String? context;
  final String? cefrLevel;
  final double? mediaTime;
  final String? cueId;
  final DateTime createdAt;

  const FavoriteEntry({
    required this.id,
    required this.type,
    required this.text,
    this.context,
    this.cefrLevel,
    this.mediaTime,
    this.cueId,
    required this.createdAt,
  });
}

class FavoritesStoreNotifier extends StateNotifier<List<FavoriteEntry>> {
  final AppDatabase _db;
  final FavoritesApiService _api;
  bool _isSyncing = false;

  FavoritesStoreNotifier(this._db, this._api) : super([]) {
    Future.microtask(() => _init());
  }

  String get _userId => AuthService.currentUser?.id ?? 'mock-user-001';

  Future<void> _init() async {
    await _loadFromDb();
    await syncFromServer();
  }

  Future<void> _loadFromDb() async {
    try {
      final rows = await _db.managers.favorites
          .filter((f) => f.userId.equals(_userId))
          .get();
      state = rows.map((f) => FavoriteEntry(
        id: f.id,
        type: _parseType(f.type),
        text: f.contentText,
        context: f.context,
        cefrLevel: f.cefrLevel,
        mediaTime: f.mediaTime,
        cueId: f.cueId,
        createdAt: f.createdAt,
      )).toList();
    } catch (e, st) {
      debugPrint('[FavoritesStore] _loadFromDb failed: $e\n$st');
      state = [];
    }
  }

  Future<void> syncFromServer() async {
    if (_isSyncing) return;
    if (!AuthService.isLoggedIn) return;
    _isSyncing = true;

    try {
      final serverFavorites = await _api.fetchFavorites();
      for (final serverFav in serverFavorites) {
        final exists = await _db.managers.favorites
            .filter((f) => f.id.equals(serverFav['id'] as String))
            .getSingleOrNull();

        if (exists == null) {
          await _db.managers.favorites.create((f) => f(
            id: Value(serverFav['id'] as String),
            userId: _userId,
            type: serverFav['type'] as String,
            contentText: serverFav['text'] as String,
            context: Value(serverFav['context'] as String?),
            cefrLevel: Value(serverFav['cefr_level'] as String?),
            mediaTime: Value((serverFav['media_time'] as num?)?.toDouble()),
            cueId: Value(serverFav['cue_id'] as String?),
            createdAt: Value(DateTime.parse(serverFav['created_at'] as String)),
            updatedAt: Value(DateTime.parse(serverFav['updated_at'] as String)),
          ));
        }
      }
      await _loadFromDb();
    } catch (e, st) {
      debugPrint('[FavoritesStore] syncFromServer failed: $e\n$st');
    } finally {
      _isSyncing = false;
    }
  }

  FavoriteType _parseType(String type) {
    switch (type) {
      case 'word':
        return FavoriteType.word;
      case 'phrase':
        return FavoriteType.phrase;
      case 'sentence':
        return FavoriteType.sentence;
      default:
        return FavoriteType.word;
    }
  }

  String _typeToString(FavoriteType type) {
    switch (type) {
      case FavoriteType.word:
        return 'word';
      case FavoriteType.phrase:
        return 'phrase';
      case FavoriteType.sentence:
        return 'sentence';
    }
  }

  Future<bool> toggleFavorite({
    required String text,
    FavoriteType type = FavoriteType.word,
    String? context,
    String? cefrLevel,
    double? mediaTime,
    String? cueId,
  }) async {
    final lowerText = text.toLowerCase();
    final existingIndex = state.indexWhere((f) => f.text.toLowerCase() == lowerText);

    if (existingIndex >= 0) {
      final entry = state[existingIndex];
      await _db.managers.favorites.filter((f) => f.id.equals(entry.id)).delete();
      if (AuthService.isLoggedIn) {
        await _api.deleteFavorite(entry.id);
      }
      await _loadFromDb();
      return false;
    }

    if (AuthService.isLoggedIn) {
      final created = await _api.createFavorite(
        type: _typeToString(type),
        text: text,
        context: context,
        cefrLevel: cefrLevel,
        mediaTime: mediaTime,
        cueId: cueId,
      );

      final now = DateTime.now();
      await _db.managers.favorites.create((f) => f(
        id: created != null ? Value(created['id'] as String) : const Value.absent(),
        userId: _userId,
        type: _typeToString(type),
        contentText: text,
        context: Value(context),
        cefrLevel: Value(cefrLevel),
        mediaTime: Value(mediaTime),
        cueId: Value(cueId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    } else {
      final now = DateTime.now();
      await _db.managers.favorites.create((f) => f(
        id: Value('local_${DateTime.now().millisecondsSinceEpoch}'),
        userId: _userId,
        type: _typeToString(type),
        contentText: text,
        context: Value(context),
        cefrLevel: Value(cefrLevel),
        mediaTime: Value(mediaTime),
        cueId: Value(cueId),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
    }
    await _loadFromDb();
    return true;
  }

  bool isFavorited(String text) {
    final lowerText = text.toLowerCase();
    return state.any((f) => f.text.toLowerCase() == lowerText);
  }

  Future<void> removeFavorite(String id) async {
    await _db.managers.favorites.filter((f) => f.id.equals(id)).delete();
    if (AuthService.isLoggedIn) {
      await _api.deleteFavorite(id);
    }
    await _loadFromDb();
  }

  Future<void> removeFavorites(List<String> ids) async {
    for (final id in ids) {
      await _db.managers.favorites.filter((f) => f.id.equals(id)).delete();
      if (AuthService.isLoggedIn) {
        await _api.deleteFavorite(id);
      }
    }
    await _loadFromDb();
  }

  List<FavoriteEntry> filterByType(FavoriteType? type) {
    if (type == null) return state;
    return state.where((f) => f.type == type).toList();
  }

  List<FavoriteEntry> filterByLevel(String? level) {
    if (level == null) return state;
    return state.where((f) => f.cefrLevel == level).toList();
  }
}

final favoritesStoreProvider =
    StateNotifierProvider<FavoritesStoreNotifier, List<FavoriteEntry>>(
  (ref) {
    final db = getAppDatabase();
    final api = FavoritesApiService();
    return FavoritesStoreNotifier(db, api);
  },
);