class SongSearchResult {
  final String trackId;
  final String title;
  final String artist;
  final String? albumName;
  final String? artworkUrl;
  final String? previewUrl;
  final String? audioUrl;
  final String? collectionName;
  final int? trackTimeMillis;

  const SongSearchResult({
    required this.trackId,
    required this.title,
    required this.artist,
    this.albumName,
    this.artworkUrl,
    this.previewUrl,
    this.audioUrl,
    this.collectionName,
    this.trackTimeMillis,
  });

  factory SongSearchResult.fromJson(Map<String, dynamic> json) {
    return SongSearchResult(
      trackId: '${json['trackId'] ?? ''}',
      title: json['trackName'] as String? ?? json['collectionName'] as String? ?? 'Unknown',
      artist: json['artistName'] as String? ?? 'Unknown',
      albumName: json['collectionName'] as String?,
      artworkUrl: json['artworkUrl100'] as String?,
      previewUrl: json['previewUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      collectionName: json['collectionName'] as String?,
      trackTimeMillis: json['trackTimeMillis'] as int?,
    );
  }
}

class SongOnlineData {
  final SongSearchResult info;
  final String? lyrics;
  final String? lyricsSource;

  const SongOnlineData({
    required this.info,
    this.lyrics,
    this.lyricsSource,
  });
}