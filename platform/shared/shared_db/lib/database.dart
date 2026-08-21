import 'package:drift/drift.dart';

import 'connection_stub.dart'
    if (dart.library.io) 'connection_io.dart'
    if (dart.library.js) 'connection_web.dart';

part 'database.g.dart';

class Users extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get username => text().unique()();
  TextColumn get email => text().unique()();
  TextColumn get passwordHash => text().named('password_hash')();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class Favorites extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text().named('user_id')();
  TextColumn get type => text()();
  TextColumn get contentText => text().named('content_text')();
  TextColumn get context => text().nullable()();
  TextColumn get cefrLevel => text().named('cefr_level').nullable()();
  RealColumn get mediaTime => real().named('media_time').nullable()();
  TextColumn get cueId => text().named('cue_id').nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class Collocations extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text().named('user_id')();
  TextColumn get type => text()();
  TextColumn get collocationText => text().named('collocation_text')();
  TextColumn get meaning => text().nullable()();
  TextColumn get sourceCueId => text().named('source_cue_id').nullable()();
  TextColumn get sourceText => text().named('source_text').nullable()();
  BoolColumn get aiDetected => boolean().named('ai_detected').withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class Flashcards extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text().named('user_id')();
  TextColumn get frontText => text().named('front_text')();
  TextColumn get frontHint => text().named('front_hint').nullable()();
  TextColumn get backAnswer => text().named('back_answer')();
  TextColumn get backMeaning => text().named('back_meaning').nullable()();
  TextColumn get backOriginal => text().named('back_original').nullable()();
  TextColumn get mediaFilePath => text().named('media_file_path').nullable()();
  TextColumn get mediaFileId => text().named('media_file_id').nullable()();
  RealColumn get mediaTime => real().named('media_time').nullable()();
  TextColumn get cueId => text().named('cue_id').nullable()();
  TextColumn get sourceTitle => text().named('source_title').nullable()();
  TextColumn get tags => text().nullable()();
  IntColumn get reviewCount => integer().named('review_count').withDefault(const Constant(0))();
  DateTimeColumn get nextReviewAt => dateTime().named('next_review_at').clientDefault(() => DateTime.now().add(const Duration(days: 1)))();
  RealColumn get easeFactor => real().named('ease_factor').withDefault(const Constant(2.5))();
  RealColumn get interval => real().withDefault(const Constant(0))();
  BoolColumn get aiGenerated => boolean().named('ai_generated').withDefault(const Constant(false))();
  TextColumn get examples => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class FlashcardReviews extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get flashcardId => text().named('flashcard_id')();
  IntColumn get rating => integer()();
  DateTimeColumn get reviewedAt => dateTime().named('reviewed_at').clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncStatus extends Table {
  TextColumn get userId => text().named('user_id')();
  DateTimeColumn get lastSyncedAt => dateTime().named('last_synced_at').nullable()();
  IntColumn get serverGeneration => integer().named('server_generation').withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {userId};
}

class ListeningHistory extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text().named('user_id')();
  TextColumn get mediaPath => text().named('media_path')();
  TextColumn get mediaName => text().named('media_name')();
  TextColumn get subtitlePath => text().named('subtitle_path').nullable()();
  TextColumn get subtitleContent => text().named('subtitle_content').nullable()();
  RealColumn get progress => real().withDefault(const Constant(0))();
  RealColumn get duration => real().nullable()();
  TextColumn get episodeIndex => text().named('episode_index').nullable()();
  TextColumn get episodeTitle => text().named('episode_title').nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().named('last_played_at').clientDefault(() => DateTime.now())();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class AiCache extends Table {
  TextColumn get cacheKey => text().named('cache_key')();
  TextColumn get taskType => text().named('task_type')();
  TextColumn get inputHash => text().named('input_hash')();
  TextColumn get response => text()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get expiresAt => dateTime().named('expires_at')();

  @override
  Set<Column> get primaryKey => {cacheKey};
}

class MediaCategories extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get name => text()();
  TextColumn get iconName => text().named('icon_name')();
  TextColumn get type => text()();
  TextColumn get platform => text().nullable()();
  IntColumn get sortOrder => integer().named('sort_order').withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

class MediaRecords extends Table {
  TextColumn get id => text().clientDefault(() => _uuid())();
  TextColumn get userId => text().named('user_id')();
  TextColumn get categoryId => text().named('category_id')();
  TextColumn get name => text()();
  TextColumn get path => text()();
  TextColumn get subtitlePath => text().named('subtitle_path').nullable()();
  TextColumn get subtitleContent => text().named('subtitle_content').nullable()();
  TextColumn get thumbnailUrl => text().named('thumbnail_url').nullable()();
  RealColumn get duration => real().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(() => DateTime.now())();
  DateTimeColumn get updatedAt => dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {id};
}

String _uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
}

@DriftDatabase(tables: [
  Users,
  Favorites,
  Collocations,
  Flashcards,
  FlashcardReviews,
  SyncStatus,
  ListeningHistory,
  AiCache,
  MediaCategories,
  MediaRecords,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(mediaCategories);
            await m.createTable(mediaRecords);
          }
          if (from < 3) {
            await m.createIndex(Index(
              'idx_favorites_user_id',
              'CREATE INDEX idx_favorites_user_id ON favorites(user_id)',
            ));
            await m.createIndex(Index(
              'idx_flashcards_user_id',
              'CREATE INDEX idx_flashcards_user_id ON flashcards(user_id)',
            ));
            await m.createIndex(Index(
              'idx_flashcards_next_review',
              'CREATE INDEX idx_flashcards_next_review ON flashcards(user_id, next_review_at)',
            ));
            await m.createIndex(Index(
              'idx_fr_flashcard_id',
              'CREATE INDEX idx_fr_flashcard_id ON flashcard_reviews(flashcard_id)',
            ));
            await m.createIndex(Index(
              'idx_lh_user_id',
              'CREATE INDEX idx_lh_user_id ON listening_history(user_id)',
            ));
            await m.createIndex(Index(
              'idx_mr_user_category',
              'CREATE INDEX idx_mr_user_category ON media_records(user_id, category_id)',
            ));
          }
          if (from < 4) {
            await m.addColumn(flashcards, flashcards.examples as GeneratedColumn<Object>);
          }
        },
      );

  static Future<AppDatabase> initialize({DatabaseMode mode = DatabaseMode.shared}) async {
    return AppDatabase(await openConnection());
  }
}

enum DatabaseMode { shared, isolated }