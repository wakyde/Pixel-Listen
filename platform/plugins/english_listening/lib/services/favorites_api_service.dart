import 'package:flutter/foundation.dart';
import 'package:shared_auth/shared_auth.dart';

class FavoritesApiService {
  FavoritesApiService();

  Future<List<Map<String, dynamic>>> fetchFavorites({
    String? typeFilter,
    String? levelFilter,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (typeFilter != null) queryParams['type'] = typeFilter;
      if (levelFilter != null) queryParams['level'] = levelFilter;

      final response = await AuthService.dio.get(
        '/api/favorites',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      final data = response.data;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e, st) {
      debugPrint('[FavoritesApi] fetchFavorites failed: $e\n$st');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createFavorite({
    required String type,
    required String text,
    String? context,
    String? cefrLevel,
    double? mediaTime,
    String? cueId,
  }) async {
    try {
      final response = await AuthService.dio.post('/api/favorites', data: {
        'type': type,
        'text': text,
        'context': context,
        'cefr_level': cefrLevel,
        'media_time': mediaTime,
        'cue_id': cueId,
      });
      return response.data as Map<String, dynamic>;
    } catch (e, st) {
      debugPrint('[FavoritesApi] createFavorite failed: $e\n$st');
      return null;
    }
  }

  Future<bool> deleteFavorite(String favoriteId) async {
    try {
      await AuthService.dio.delete('/api/favorites/$favoriteId');
      return true;
    } catch (e, st) {
      debugPrint('[FavoritesApi] deleteFavorite failed: $e\n$st');
      return false;
    }
  }
}