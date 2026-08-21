import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_db/shared_db.dart';

import '../constants.dart';

class MediaCategory {
  final String id;
  final String name;
  final String iconName;
  final String type;
  final String? platform;
  final int sortOrder;

  const MediaCategory({
    required this.id,
    required this.name,
    required this.iconName,
    required this.type,
    this.platform,
    required this.sortOrder,
  });
}

final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final mediaCategoryProvider = FutureProvider<List<MediaCategory>>((ref) async {
  final db = getAppDatabase();
  await _seedDefaultCategories(db);
  final rows = await (db.select(db.mediaCategories)
        ..orderBy([(f) => OrderingTerm.asc(f.sortOrder)]))
      .get();
  return rows.map((r) => MediaCategory(
        id: r.id,
        name: r.name,
        iconName: r.iconName,
        type: r.type,
        platform: r.platform,
        sortOrder: r.sortOrder,
      )).toList();
});

class MediaCategoryNotifier extends StateNotifier<AsyncValue<void>> {
  final AppDatabase _db;

  MediaCategoryNotifier(this._db) : super(const AsyncValue.data(null));

  Future<void> addCategory({
    required String name,
    required String type,
    String? platform,
    required String iconName,
    required int sortOrder,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _db.into(_db.mediaCategories).insert(
        MediaCategoriesCompanion.insert(
          name: name,
          iconName: iconName,
          type: type,
          platform: Value(platform),
          sortOrder: Value(sortOrder),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    state = const AsyncValue.loading();
    try {
      await (_db.delete(_db.mediaCategories)
            ..where((f) => f.id.equals(categoryId)))
          .go();
      await (_db.delete(_db.mediaRecords)
            ..where((f) => f.categoryId.equals(categoryId)))
          .go();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final mediaCategoryNotifierProvider =
    StateNotifierProvider<MediaCategoryNotifier, AsyncValue<void>>((ref) {
  final db = getAppDatabase();
  return MediaCategoryNotifier(db);
});

Future<void> _seedDefaultCategories(AppDatabase db) async {
  final existing = await db.select(db.mediaCategories).get();
  if (existing.isNotEmpty) return;

  final defaults = [
    ('本地视频', IconName.folder, CategoryType.local, null, 0),
    ('YouTube', IconName.smartDisplay, CategoryType.online, PlatformName.youtube, 1),
    ('Bilibili', IconName.tv, CategoryType.online, PlatformName.bilibili, 2),
    ('抖音', IconName.musicNote, CategoryType.online, PlatformName.douyin, 3),
    ('其他在线', IconName.language, CategoryType.online, PlatformName.other, 4),
  ];

  for (var i = 0; i < defaults.length; i++) {
    final (name, icon, type, platform, order) = defaults[i];
    await db.into(db.mediaCategories).insert(
      MediaCategoriesCompanion.insert(
        name: name,
        iconName: icon,
        type: type,
        platform: Value(platform),
        sortOrder: Value(order),
      ),
    );
  }
}