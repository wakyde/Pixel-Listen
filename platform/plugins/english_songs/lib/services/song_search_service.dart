import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/search_models.dart';

class SongSearchService {
  static const _backendBase = 'http://localhost:8000/api/songs';
  static const _itunesBase = 'https://itunes.apple.com';
  static const _lyricsOvhBase = 'https://api.lyrics.ovh/v1';

  Future<List<SongSearchResult>> searchSongs(String query) async {
    if (query.trim().isEmpty) return [];

    final results = await _searchViaBackend(query);
    if (results.isNotEmpty) return results;

    return _searchViaItunes(query);
  }

  Future<List<SongSearchResult>> _searchViaBackend(String query) async {
    try {
      final uri = Uri.parse(
        '$_backendBase/search?q=${Uri.encodeComponent(query)}&limit=20',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) return [];

      final songs = <SongSearchResult>[];
      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        songs.add(SongSearchResult(
          trackId: item['track_id'] as String? ?? '',
          title: item['title'] as String? ?? 'Unknown',
          artist: item['artist'] as String? ?? 'Unknown',
          albumName: item['album_name'] as String?,
          artworkUrl: item['artwork_url'] as String?,
          previewUrl: item['preview_url'] as String?,
          audioUrl: item['audio_url'] as String?,
          collectionName: item['album_name'] as String?,
          trackTimeMillis: item['duration'] as int?,
        ));
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  Future<List<SongSearchResult>> _searchViaItunes(String query) async {
    final uri = Uri.parse(
      '$_itunesBase/search?term=${Uri.encodeComponent(query)}&entity=song&limit=20',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) return [];

      final seen = <String>{};
      final songs = <SongSearchResult>[];

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final kind = item['kind'] as String?;
        final wrapper = item['wrapperType'] as String?;

        if (kind != 'song' && wrapper != 'track') continue;

        final result = SongSearchResult.fromJson(item);

        final key = '${result.title}|${result.artist}';
        if (seen.contains(key)) continue;
        seen.add(key);

        songs.add(result);
      }

      return songs;
    } catch (_) {
      return [];
    }
  }

  Future<String?> fetchLyrics(String artist, String title) async {
    final lyrics = await _fetchLyricsViaBackend(artist, title);
    if (lyrics != null) return lyrics;

    return _fetchLyricsViaOvh(artist, title);
  }

  Future<String?> _fetchLyricsViaBackend(String artist, String title) async {
    try {
      final uri = Uri.parse(
        '$_backendBase/lyrics?artist=${Uri.encodeComponent(artist)}&title=${Uri.encodeComponent(title)}',
      );
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['lyrics'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _fetchLyricsViaOvh(String artist, String title) async {
    final uri = Uri.parse(
      '$_lyricsOvhBase/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}',
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['lyrics'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<SongOnlineData?> fetchSongData(SongSearchResult result) async {
    final lyrics = await fetchLyrics(result.artist, result.title);
    if (lyrics == null && result.previewUrl == null && result.audioUrl == null) {
      return null;
    }

    return SongOnlineData(
      info: result,
      lyrics: lyrics,
      lyricsSource: lyrics != null ? 'lyrics.ovh' : null,
    );
  }
}