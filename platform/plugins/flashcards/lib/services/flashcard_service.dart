import 'package:drift/drift.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';

import '../utils/sm2.dart';
import 'flashcards_api_service.dart';

class FlashcardService {
  final AppDatabase _db;
  final FlashcardsApiService _api;
  bool _isSyncing = false;

  FlashcardService(this._db, this._api);

  Future<void> syncFromServer() async {
    if (_isSyncing) return;
    if (!AuthService.isLoggedIn) return;
    _isSyncing = true;

    try {
      final serverCards = await _api.fetchFlashcards();
      for (final serverCard in serverCards) {
        final exists = await (_db.select(_db.flashcards)
              ..where((f) => f.id.equals(serverCard['id'] as String)))
            .getSingleOrNull();

        if (exists == null) {
          await _db.into(_db.flashcards).insert(FlashcardsCompanion(
            id: Value(serverCard['id'] as String),
            userId: const Value('mock-user-001'),
            frontText: Value(serverCard['front_text'] as String),
            frontHint: Value(serverCard['front_hint'] as String?),
            backAnswer: Value(serverCard['back_answer'] as String),
            backMeaning: Value(serverCard['back_meaning'] as String?),
            backOriginal: Value(serverCard['back_original'] as String?),
            mediaFilePath: Value(serverCard['media_file_path'] as String?),
            mediaTime: Value((serverCard['media_time'] as num?)?.toDouble()),
            cueId: Value(serverCard['cue_id'] as String?),
            sourceTitle: Value(serverCard['source_title'] as String?),
            tags: Value(serverCard['tags'] as String?),
            reviewCount: Value(serverCard['review_count'] as int? ?? 0),
            nextReviewAt: Value(DateTime.parse(serverCard['next_review_at'] as String)),
            easeFactor: Value((serverCard['ease_factor'] as num?)?.toDouble() ?? 2.5),
            interval: Value((serverCard['interval'] as num?)?.toDouble() ?? 0),
            aiGenerated: Value(serverCard['ai_generated'] as bool? ?? false),
            createdAt: Value(DateTime.parse(serverCard['created_at'] as String)),
            updatedAt: Value(DateTime.parse(serverCard['updated_at'] as String)),
          ));
        }
      }
    } catch (_) {
    } finally {
      _isSyncing = false;
    }
  }

  Future<List<FlashcardData>> getDueCards() async {
    final now = DateTime.now();
    final query = _db.select(_db.flashcards)
      ..where((f) => f.nextReviewAt.isSmallerOrEqualValue(now))
      ..orderBy([(f) => OrderingTerm.asc(f.nextReviewAt)]);

    final rows = await query.get();
    return rows.map((r) => FlashcardData.fromRow(r)).toList();
  }

  Future<List<FlashcardData>> getAllCards() async {
    final rows = await _db.select(_db.flashcards).get();
    return rows.map((r) => FlashcardData.fromRow(r)).toList();
  }

  Future<int> getDueCount() async {
    final now = DateTime.now();
    final query = _db.select(_db.flashcards)
      ..where((f) => f.nextReviewAt.isSmallerOrEqualValue(now));

    final rows = await query.get();
    return rows.length;
  }

  Future<int> getTotalCount() async {
    final rows = await _db.select(_db.flashcards).get();
    return rows.length;
  }

  Future<FlashcardData> createCard({
    required String frontText,
    required String backAnswer,
    String? frontHint,
    String? backMeaning,
    String? backOriginal,
    String? mediaFilePath,
    double? mediaTime,
    String? cueId,
    String? sourceTitle,
    String? tags,
    bool aiGenerated = false,
  }) async {
    final id = _uuid();
    final now = DateTime.now();

    await _db.into(_db.flashcards).insert(FlashcardsCompanion(
      id: Value(id),
      userId: const Value('mock-user-001'),
      frontText: Value(frontText),
      frontHint: Value.absentIfNull(frontHint),
      backAnswer: Value(backAnswer),
      backMeaning: Value.absentIfNull(backMeaning),
      backOriginal: Value.absentIfNull(backOriginal),
      mediaFilePath: Value.absentIfNull(mediaFilePath),
      mediaTime: Value.absentIfNull(mediaTime),
      cueId: Value.absentIfNull(cueId),
      sourceTitle: Value.absentIfNull(sourceTitle),
      tags: Value.absentIfNull(tags),
      aiGenerated: Value(aiGenerated),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    if (AuthService.isLoggedIn) {
      _api.createCard(
        frontText: frontText,
        backAnswer: backAnswer,
        frontHint: frontHint,
        backMeaning: backMeaning,
        backOriginal: backOriginal,
        mediaFilePath: mediaFilePath,
        mediaTime: mediaTime,
        cueId: cueId,
        sourceTitle: sourceTitle,
        tags: tags,
        aiGenerated: aiGenerated,
      );
    }

    return FlashcardData(
      id: id,
      frontText: frontText,
      backAnswer: backAnswer,
      frontHint: frontHint,
      backMeaning: backMeaning,
      backOriginal: backOriginal,
      mediaFilePath: mediaFilePath,
      mediaTime: mediaTime,
      cueId: cueId,
      sourceTitle: sourceTitle,
      tags: tags,
      reviewCount: 0,
      nextReviewAt: now.add(const Duration(days: 1)),
      easeFactor: 2.5,
      interval: 0,
      aiGenerated: aiGenerated,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> recordReview({
    required String flashcardId,
    required int rating,
    required Sm2Result sm2Result,
  }) async {
    final now = DateTime.now();

    await _db.into(_db.flashcardReviews).insert(FlashcardReviewsCompanion(
      id: Value(_uuid()),
      flashcardId: Value(flashcardId),
      rating: Value(rating),
      reviewedAt: Value(now),
    ));

    await (_db.update(_db.flashcards)
          ..where((f) => f.id.equals(flashcardId)))
        .write(FlashcardsCompanion(
      interval: Value(sm2Result.interval),
      easeFactor: Value(sm2Result.easeFactor),
      nextReviewAt: Value(sm2Result.nextReviewAt),
      reviewCount: Value(sm2Result.reviewCount),
      updatedAt: Value(now),
    ));

    if (AuthService.isLoggedIn) {
      _api.recordReview(cardId: flashcardId, rating: rating);
    }
  }

  Future<void> deleteCard(String id) async {
    await (_db.delete(_db.flashcards)..where((f) => f.id.equals(id))).go();
    await (_db.delete(_db.flashcardReviews)
          ..where((r) => r.flashcardId.equals(id)))
        .go();

    if (AuthService.isLoggedIn) {
      _api.deleteCard(id);
    }
  }

  String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
  }
}

class FlashcardData {
  final String id;
  final String frontText;
  final String backAnswer;
  final String? frontHint;
  final String? backMeaning;
  final String? backOriginal;
  final String? mediaFilePath;
  final double? mediaTime;
  final String? cueId;
  final String? sourceTitle;
  final String? tags;
  final int reviewCount;
  final DateTime nextReviewAt;
  final double easeFactor;
  final double interval;
  final bool aiGenerated;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FlashcardData({
    required this.id,
    required this.frontText,
    required this.backAnswer,
    this.frontHint,
    this.backMeaning,
    this.backOriginal,
    this.mediaFilePath,
    this.mediaTime,
    this.cueId,
    this.sourceTitle,
    this.tags,
    required this.reviewCount,
    required this.nextReviewAt,
    required this.easeFactor,
    required this.interval,
    required this.aiGenerated,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FlashcardData.fromRow(Flashcard row) {
    return FlashcardData(
      id: row.id,
      frontText: row.frontText,
      backAnswer: row.backAnswer,
      frontHint: row.frontHint,
      backMeaning: row.backMeaning,
      backOriginal: row.backOriginal,
      mediaFilePath: row.mediaFilePath,
      mediaTime: row.mediaTime,
      cueId: row.cueId,
      sourceTitle: row.sourceTitle,
      tags: row.tags,
      reviewCount: row.reviewCount,
      nextReviewAt: row.nextReviewAt,
      easeFactor: row.easeFactor,
      interval: row.interval,
      aiGenerated: row.aiGenerated,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}