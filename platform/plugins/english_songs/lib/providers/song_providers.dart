import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';

import '../models/song_models.dart';
import '../services/song_service.dart';

final songServiceProvider = Provider<SongService>((ref) {
  return SongService();
});

final userSongsProvider = FutureProvider.autoDispose<List<SongData>>((ref) {
  final service = ref.watch(songServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'anonymous';
  return service.getUserSongs(userId);
});

final songLinesProvider = FutureProvider.autoDispose.family<List<SongLyricLine>, String>((ref, songId) {
  final service = ref.watch(songServiceProvider);
  return service.getSongLines(songId);
});

final userFavoritesProvider = FutureProvider.autoDispose<List<SongFavoriteData>>((ref) {
  final service = ref.watch(songServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'anonymous';
  return service.getUserFavorites(userId);
});

final songCountProvider = FutureProvider.autoDispose<int>((ref) {
  final service = ref.watch(songServiceProvider);
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'anonymous';
  return service.getSongCount(userId);
});