import '../models/song_models.dart';

class SongScoringService {
  SongScoringService._();

  static SongScoreResult calculateScore({
    required String originalText,
    required String recordedText,
    required List<LiaisonMark>? liaisonMarks,
  }) {
    final pronunciationScore = _calcPronunciationScore(originalText, recordedText);
    final rhythmScore = _calcRhythmScore(originalText, recordedText);

    final hasLiaisons = liaisonMarks != null && liaisonMarks.isNotEmpty;
    int? liaisonScore;
    if (hasLiaisons) {
      liaisonScore = _calcLiaisonScore(originalText, recordedText, liaisonMarks);
    }

    final totalScore = hasLiaisons
        ? (pronunciationScore * 0.4 + rhythmScore * 0.3 + liaisonScore! * 0.3).round()
        : (pronunciationScore * 0.55 + rhythmScore * 0.45).round();

    return SongScoreResult(
      totalScore: totalScore.clamp(0, 100),
      pronunciationScore: pronunciationScore.clamp(0, 100),
      rhythmScore: rhythmScore.clamp(0, 100),
      liaisonScore: liaisonScore?.clamp(0, 100),
    );
  }

  static int _calcPronunciationScore(String original, String recorded) {
    final normOriginal = _normalize(original);
    final normRecorded = _normalize(recorded);

    if (normOriginal.isEmpty && normRecorded.isEmpty) return 100;
    if (normOriginal.isEmpty || normRecorded.isEmpty) return 0;

    final originalWords = normOriginal.split(' ');
    final recordedWords = normRecorded.split(' ');

    int matchedWords = 0;
    for (final word in originalWords) {
      if (word.isEmpty) continue;
      if (recordedWords.contains(word)) {
        matchedWords++;
      } else {
        for (final rw in recordedWords) {
          if (_levenshteinDistance(word, rw) <= 2) {
            matchedWords++;
            break;
          }
        }
      }
    }

    final wordScore = originalWords.isEmpty
        ? 0.0
        : (matchedWords / originalWords.length * 100);

    final charMatches = _charMatchCount(normOriginal, normRecorded);
    final maxLen = normOriginal.length > normRecorded.length
        ? normOriginal.length
        : normRecorded.length;
    final charScore = maxLen == 0 ? 100.0 : (charMatches / maxLen * 100);

    return ((wordScore * 0.6 + charScore * 0.4)).round();
  }

  static int _calcRhythmScore(String original, String recorded) {
    final normOriginal = _normalize(original);
    final normRecorded = _normalize(recorded);

    final originalWords = normOriginal.split(' ').where((w) => w.isNotEmpty).toList();
    final recordedWords = normRecorded.split(' ').where((w) => w.isNotEmpty).toList();

    if (originalWords.isEmpty) return 100;

    final wordCountDiff = (originalWords.length - recordedWords.length).abs();
    final wordCountScore = wordCountDiff == 0
        ? 100.0
        : (1.0 - wordCountDiff / originalWords.length) * 100;

    return wordCountScore.clamp(0, 100).round();
  }

  static int _calcLiaisonScore(
    String original,
    String recorded,
    List<LiaisonMark> liaisons,
  ) {
    if (liaisons.isEmpty) return 100;

    final normRecorded = _normalize(recorded);
    int matchedLiaisons = 0;

    for (final liaison in liaisons) {
      final liaisonWords = _normalize(liaison.text).split(' ');
      var allFound = true;
      for (final word in liaisonWords) {
        if (word.isNotEmpty && !normRecorded.contains(word)) {
          allFound = false;
          break;
        }
      }
      if (allFound) matchedLiaisons++;
    }

    return (matchedLiaisons / liaisons.length * 100).round();
  }

  static String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _charMatchCount(String a, String b) {
    int matches = 0;
    final maxLen = a.length > b.length ? a.length : b.length;
    for (int i = 0; i < maxLen; i++) {
      if (i < a.length && i < b.length && a[i] == b[i]) {
        matches++;
      }
    }
    return matches;
  }

  static int _levenshteinDistance(String a, String b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((x, y) => x < y ? x : y);
      }
    }

    return matrix[a.length][b.length];
  }
}

class SongScoreResult {
  final int totalScore;
  final int pronunciationScore;
  final int rhythmScore;
  final int? liaisonScore;

  const SongScoreResult({
    required this.totalScore,
    required this.pronunciationScore,
    required this.rhythmScore,
    this.liaisonScore,
  });
}