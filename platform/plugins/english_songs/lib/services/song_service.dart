import '../database/db_adapter.dart';
import '../database/songs_database.dart';
import '../models/song_models.dart';
import 'scoring_service.dart';

class SongService {
  Future<DbAdapter> get _db => SongsDatabase.database;

  Future<SongData> createSong({
    required String userId,
    required String title,
    String? artist,
    required String format,
    required bool hasTimestamps,
    String? audioFilePath,
    required List<SongLyricLine> lines,
  }) async {
    final db = await _db;
    final songId = SongsDatabase.uuid();
    final now = DateTime.now().toIso8601String();

    await db.insert('songs', {
      'id': songId,
      'user_id': userId,
      'title': title,
      'artist': artist,
      'format': format,
      'has_timestamps': hasTimestamps ? 1 : 0,
      'audio_file_path': audioFilePath,
      'created_at': now,
      'updated_at': now,
    });

    for (final line in lines) {
      final lineId = SongsDatabase.uuid();
      await db.insert('song_lines', {
        'id': lineId,
        'song_id': songId,
        'line_index': line.lineIndex,
        'start_time': line.startTime,
        'end_time': line.endTime,
        'text': line.text,
        'text_zh': line.textZh,
        'created_at': now,
      });

      if (line.liaisonMarks != null) {
        for (final mark in line.liaisonMarks!) {
          await db.insert('liaison_marks', {
            'id': SongsDatabase.uuid(),
            'line_id': lineId,
            'song_id': songId,
            'start_char': mark.startChar,
            'end_char': mark.endChar,
            'text': mark.text,
            'pronunciation': mark.pronunciation,
            'type': mark.type.name,
            'detected_by': mark.detectedBy,
            'created_at': now,
          });
        }
      }
    }

    return SongData(
      id: songId,
      userId: userId,
      title: title,
      artist: artist,
      format: format,
      hasTimestamps: hasTimestamps,
      audioFilePath: audioFilePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<List<SongData>> getUserSongs(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'songs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => SongData(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String?,
      format: r['format'] as String,
      hasTimestamps: (r['has_timestamps'] as int) == 1,
      audioFilePath: r['audio_file_path'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
    )).toList();
  }

  Future<SongData?> getSong(String id) async {
    final db = await _db;
    final rows = await db.query('songs', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;

    final r = rows.first;
    return SongData(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      title: r['title'] as String,
      artist: r['artist'] as String?,
      format: r['format'] as String,
      hasTimestamps: (r['has_timestamps'] as int) == 1,
      audioFilePath: r['audio_file_path'] as String?,
      createdAt: DateTime.parse(r['created_at'] as String),
      updatedAt: DateTime.parse(r['updated_at'] as String),
    );
  }

  Future<List<SongLyricLine>> getSongLines(String songId) async {
    final db = await _db;
    final rows = await db.query(
      'song_lines',
      where: 'song_id = ?',
      whereArgs: [songId],
      orderBy: 'line_index ASC',
    );

    final lines = <SongLyricLine>[];
    for (final row in rows) {
      final lineId = row['id'] as String;
      final marks = await _getLiaisonMarks(lineId);
      lines.add(SongLyricLine(
        id: lineId,
        songId: row['song_id'] as String,
        lineIndex: row['line_index'] as int,
        startTime: row['start_time'] as double?,
        endTime: row['end_time'] as double?,
        text: row['text'] as String,
        textZh: row['text_zh'] as String?,
        liaisonMarks: marks.isNotEmpty ? marks : null,
        createdAt: DateTime.parse(row['created_at'] as String),
      ));
    }

    return lines;
  }

  Future<List<LiaisonMark>> _getLiaisonMarks(String lineId) async {
    final db = await _db;
    final rows = await db.query(
      'liaison_marks',
      where: 'line_id = ?',
      whereArgs: [lineId],
      orderBy: 'start_char ASC',
    );

    return rows.map((r) => LiaisonMark(
      text: r['text'] as String,
      startChar: r['start_char'] as int,
      endChar: r['end_char'] as int,
      type: LiaisonType.values.firstWhere(
        (t) => t.name == r['type'],
        orElse: () => LiaisonType.other,
      ),
      pronunciation: r['pronunciation'] as String,
      detectedBy: r['detected_by'] as String,
    )).toList();
  }

  Future<void> deleteSong(String id) async {
    final db = await _db;
    await db.delete('songs', where: 'id = ?', whereArgs: [id]);
  }

  Future<SongRecordingData> saveRecording({
    required String userId,
    required String songId,
    required String lineId,
    String? recordingPath,
    String? recognizedText,
    SongScoreResult? score,
  }) async {
    final db = await _db;
    final recordingId = SongsDatabase.uuid();
    final now = DateTime.now().toIso8601String();

    await db.insert('song_recordings', {
      'id': recordingId,
      'user_id': userId,
      'song_id': songId,
      'line_id': lineId,
      'recording_path': recordingPath,
      'recognized_text': recognizedText,
      'created_at': now,
    });

    if (score != null) {
      await db.insert('song_scores', {
        'id': SongsDatabase.uuid(),
        'recording_id': recordingId,
        'total_score': score.totalScore,
        'pronunciation_score': score.pronunciationScore,
        'rhythm_score': score.rhythmScore,
        'liaison_score': score.liaisonScore,
        'created_at': now,
      });
    }

    return SongRecordingData(
      id: recordingId,
      userId: userId,
      songId: songId,
      lineId: lineId,
      recordingPath: recordingPath,
      recognizedText: recognizedText,
      score: score,
      createdAt: DateTime.now(),
    );
  }

  Future<List<SongRecordingData>> getRecordingsForLine(String lineId) async {
    final db = await _db;
    final rows = await db.query(
      'song_recordings',
      where: 'line_id = ?',
      whereArgs: [lineId],
      orderBy: 'created_at DESC',
    );

    final recordings = <SongRecordingData>[];
    for (final row in rows) {
      final score = await _getScoreForRecording(row['id'] as String);
      recordings.add(SongRecordingData(
        id: row['id'] as String,
        userId: row['user_id'] as String,
        songId: row['song_id'] as String,
        lineId: row['line_id'] as String,
        recordingPath: row['recording_path'] as String?,
        recognizedText: row['recognized_text'] as String?,
        score: score,
        createdAt: DateTime.parse(row['created_at'] as String),
      ));
    }

    return recordings;
  }

  Future<SongScoreResult?> _getScoreForRecording(String recordingId) async {
    final db = await _db;
    final rows = await db.query(
      'song_scores',
      where: 'recording_id = ?',
      whereArgs: [recordingId],
    );

    if (rows.isEmpty) return null;
    final r = rows.first;
    return SongScoreResult(
      totalScore: r['total_score'] as int,
      pronunciationScore: r['pronunciation_score'] as int,
      rhythmScore: r['rhythm_score'] as int,
      liaisonScore: r['liaison_score'] as int?,
    );
  }

  Future<List<SongRecordingData>> getBestRecordings(String songId) async {
    final db = await _db;
    final lines = await db.query(
      'song_lines',
      where: 'song_id = ?',
      whereArgs: [songId],
    );

    final best = <SongRecordingData>[];
    for (final line in lines) {
      final recordings = await getRecordingsForLine(line['id'] as String);
      if (recordings.isNotEmpty) {
        recordings.sort((a, b) {
          final sa = a.score?.totalScore ?? 0;
          final sb = b.score?.totalScore ?? 0;
          return sb.compareTo(sa);
        });
        best.add(recordings.first);
      }
    }

    return best;
  }

  Future<void> addFavorite({
    required String userId,
    String? songId,
    String? lineId,
    required String text,
    required String pronunciation,
    required String type,
    int? startChar,
    int? endChar,
  }) async {
    final db = await _db;

    final existing = await db.query(
      'song_favorites',
      where: 'user_id = ? AND text = ? AND pronunciation = ?',
      whereArgs: [userId, text, pronunciation],
    );

    if (existing.isNotEmpty) return;

    await db.insert('song_favorites', {
      'id': SongsDatabase.uuid(),
      'user_id': userId,
      'song_id': songId,
      'line_id': lineId,
      'text': text,
      'pronunciation': pronunciation,
      'type': type,
      'start_char': startChar,
      'end_char': endChar,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(String id) async {
    final db = await _db;
    await db.delete('song_favorites', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<SongFavoriteData>> getUserFavorites(String userId) async {
    final db = await _db;
    final rows = await db.query(
      'song_favorites',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return rows.map((r) => SongFavoriteData(
      id: r['id'] as String,
      userId: r['user_id'] as String,
      songId: r['song_id'] as String?,
      lineId: r['line_id'] as String?,
      text: r['text'] as String,
      pronunciation: r['pronunciation'] as String,
      type: r['type'] as String,
      startChar: r['start_char'] as int?,
      endChar: r['end_char'] as int?,
      createdAt: DateTime.parse(r['created_at'] as String),
    )).toList();
  }

  Future<bool> isFavorite({
    required String userId,
    required String text,
    required String pronunciation,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'song_favorites',
      where: 'user_id = ? AND text = ? AND pronunciation = ?',
      whereArgs: [userId, text, pronunciation],
    );
    return rows.isNotEmpty;
  }

  Future<int> getSongCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM songs WHERE user_id = ?',
      [userId],
    );
    return result.first['cnt'] as int;
  }

  Future<int> getRecordingCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM song_recordings WHERE user_id = ?',
      [userId],
    );
    return result.first['cnt'] as int;
  }
}

class SongData {
  final String id;
  final String userId;
  final String title;
  final String? artist;
  final String format;
  final bool hasTimestamps;
  final String? audioFilePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SongData({
    required this.id,
    required this.userId,
    required this.title,
    this.artist,
    required this.format,
    required this.hasTimestamps,
    this.audioFilePath,
    required this.createdAt,
    required this.updatedAt,
  });
}

class SongRecordingData {
  final String id;
  final String userId;
  final String songId;
  final String lineId;
  final String? recordingPath;
  final String? recognizedText;
  final SongScoreResult? score;
  final DateTime createdAt;

  const SongRecordingData({
    required this.id,
    required this.userId,
    required this.songId,
    required this.lineId,
    this.recordingPath,
    this.recognizedText,
    this.score,
    required this.createdAt,
  });
}

class SongFavoriteData {
  final String id;
  final String userId;
  final String? songId;
  final String? lineId;
  final String text;
  final String pronunciation;
  final String type;
  final int? startChar;
  final int? endChar;
  final DateTime createdAt;

  const SongFavoriteData({
    required this.id,
    required this.userId,
    this.songId,
    this.lineId,
    required this.text,
    required this.pronunciation,
    required this.type,
    this.startChar,
    this.endChar,
    required this.createdAt,
  });
}