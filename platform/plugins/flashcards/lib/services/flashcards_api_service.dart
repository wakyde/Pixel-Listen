import 'package:shared_auth/shared_auth.dart';

class FlashcardsApiService {
  FlashcardsApiService();

  Future<List<Map<String, dynamic>>> fetchFlashcards({
    String? sortBy,
    String? tags,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (tags != null) queryParams['tags'] = tags;

      final response = await AuthService.dio.get(
        '/api/flashcards',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchDueCards() async {
    try {
      final response = await AuthService.dio.get('/api/flashcards/due');
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, int>?> fetchCounts() async {
    try {
      final response = await AuthService.dio.get('/api/flashcards/counts');
      final data = response.data as Map<String, dynamic>;
      return {
        'due_count': data['due_count'] as int,
        'total_count': data['total_count'] as int,
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createCard({
    required String frontText,
    required String backAnswer,
    String? frontHint,
    String? backMeaning,
    String? backOriginal,
    String? mediaFilePath,
    String? mediaFileId,
    double? mediaTime,
    String? cueId,
    String? sourceTitle,
    String? tags,
    bool aiGenerated = false,
  }) async {
    try {
      final response = await AuthService.dio.post('/api/flashcards', data: {
        'front_text': frontText,
        'back_answer': backAnswer,
        'front_hint': frontHint,
        'back_meaning': backMeaning,
        'back_original': backOriginal,
        'media_file_path': mediaFilePath,
        'media_file_id': mediaFileId,
        'media_time': mediaTime,
        'cue_id': cueId,
        'source_title': sourceTitle,
        'tags': tags,
        'ai_generated': aiGenerated,
      });
      return response.data as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> recordReview({
    required String cardId,
    required int rating,
  }) async {
    try {
      await AuthService.dio.post('/api/flashcards/$cardId/review', data: {
        'rating': rating,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCard(String cardId) async {
    try {
      await AuthService.dio.delete('/api/flashcards/$cardId');
      return true;
    } catch (_) {
      return false;
    }
  }
}