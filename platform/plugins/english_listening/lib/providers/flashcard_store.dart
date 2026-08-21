import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_db/shared_db.dart';

import '../services/ai_service.dart';

final flashcardStoreProvider =
    FutureProvider.family<bool, String>((ref, word) async {
  final db = getAppDatabase();
  final lower = word.toLowerCase();
  final rows = await (db.select(db.flashcards)
        ..where((f) => f.backAnswer.lower().equals(lower)))
      .get();
  return rows.isNotEmpty;
});

final flashcardWordSetProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final db = getAppDatabase();
  final rows = await db.select(db.flashcards).get();
  return rows.map((r) => r.backAnswer.toLowerCase()).toSet();
});

final flashcardCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final db = getAppDatabase();
  final rows = await db.select(db.flashcards).get();
  return rows.length;
});

Future<bool> addFlashcard({
  required String word,
  String? meaning,
  String? level,
  String? originalSentence,
  String? sourceTitle,
  AIService? aiService,
}) async {
  try {
    final db = getAppDatabase();
    final lowerWord = word.toLowerCase();

    final existing = await (db.select(db.flashcards)
          ..where((f) => f.backAnswer.lower().equals(lowerWord)))
        .get();
    if (existing.isNotEmpty) return false;

    String frontText;
    String? frontHint;
    String? examplesJson;

    if (aiService != null && originalSentence != null && originalSentence.isNotEmpty) {
      final aiResult = await aiService.generateCloze(
        collocation: word,
        originalSentence: originalSentence,
      );
      if (aiResult != null && aiResult['clozeSentence']!.isNotEmpty) {
        frontText = aiResult['clozeSentence']!;
        frontHint = aiResult['hint']?.isNotEmpty == true
            ? aiResult['hint']
            : meaning;
      } else {
        frontText = _buildClozeFront(originalSentence, word);
        frontHint = meaning;
      }

      final examples = await aiService.generateExamples(
        word: word,
        meaning: meaning,
        count: 3,
      );
      if (examples.isNotEmpty) {
        examplesJson = jsonEncode(
          examples.map((e) => {'sentence_en': e.sentenceEn, 'sentence_zh': e.sentenceZh}).toList(),
        );
      }
    } else {
      frontText = _buildClozeFront(originalSentence ?? '', word);
      frontHint = meaning;
    }

    final now = DateTime.now();
    final id = _uuid();

    await db.into(db.flashcards).insert(FlashcardsCompanion(
      id: Value(id),
      userId: const Value('mock-user-001'),
      frontText: Value(frontText),
      frontHint: Value.absentIfNull(frontHint),
      backAnswer: Value(word),
      backMeaning: Value.absentIfNull(meaning),
      backOriginal: Value.absentIfNull(originalSentence),
      sourceTitle: Value.absentIfNull(sourceTitle),
      tags: Value.absentIfNull(level),
      examples: Value.absentIfNull(examplesJson),
      nextReviewAt: Value(now.add(const Duration(days: 1))),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return true;
  } catch (e, st) {
    debugPrint('[FlashcardStore] add failed: $e\n$st');
    return false;
  }
}

Future<void> removeFlashcard(String id) async {
  try {
    final db = getAppDatabase();
    await (db.delete(db.flashcards)..where((f) => f.id.equals(id))).go();
    await (db.delete(db.flashcardReviews)
          ..where((r) => r.flashcardId.equals(id)))
        .go();
  } catch (e, st) {
    debugPrint('[FlashcardStore] remove failed: $e\n$st');
  }
}

String _buildClozeFront(String sentence, String word) {
  if (sentence.isEmpty) return '______';
  final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
  if (pattern.hasMatch(sentence)) {
    return sentence.replaceAll(pattern, '______');
  }
  return '______ $word';
}

String _uuid() {
  final now = DateTime.now().microsecondsSinceEpoch;
  return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
}