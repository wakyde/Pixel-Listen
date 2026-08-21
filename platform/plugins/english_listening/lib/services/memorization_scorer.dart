import '../models/subtitle.dart';

class MemorizationScorer {
  static const double minScore = 1.0;
  static const double maxScore = 10.0;
  static const int idealWordCountMin = 6;
  static const int idealWordCountMax = 20;
  static const int tooShortWordCount = 3;
  static const int tooLongWordCount = 30;
  static const double highValueUniqueRatio = 0.7;
  static const Set<String> highValueLevels = {'B1', 'B2', 'C1'};

  double calculateScore(SubtitleCue cue) {
    double score = 5.0;

    score += _wordCountScore(cue.text);
    score += _cefrScore(cue.cefrTokens);
    score += _collocationScore(cue.collocationTokens);
    score += _uniqueWordRatioScore(cue.text);
    score += _phrasalVerbScore(cue.text);

    return score.clamp(minScore, maxScore);
  }

  double _wordCountScore(String text) {
    final wordCount = _countWords(text);
    if (wordCount >= idealWordCountMin && wordCount <= idealWordCountMax) {
      return 1.5;
    }
    if (wordCount < tooShortWordCount) {
      return -2.0;
    }
    if (wordCount > tooLongWordCount) {
      return -1.0;
    }
    return 0.0;
  }

  double _cefrScore(List<CefrToken>? tokens) {
    if (tokens == null || tokens.isEmpty) return 0.0;
    final highValueCount =
        tokens.where((t) => highValueLevels.contains(t.level)).length;
    return (highValueCount * 0.5).clamp(0.0, 2.0);
  }

  double _collocationScore(List<CollocationToken>? tokens) {
    if (tokens == null || tokens.isEmpty) return 0.0;
    return (tokens.length * 1.0).clamp(0.0, 3.0);
  }

  double _uniqueWordRatioScore(String text) {
    final words = _extractWords(text);
    if (words.isEmpty) return 0.0;
    final uniqueWords = words.toSet();
    final ratio = uniqueWords.length / words.length;
    if (ratio > highValueUniqueRatio) {
      return 0.5;
    }
    return 0.0;
  }

  double _phrasalVerbScore(String text) {
    final matches = _extractPhrasalPatterns(text);
    if (matches.isEmpty) return 0.0;
    return (matches.length * 1.5).clamp(0.0, 3.0);
  }

  List<String> _extractWords(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[^a-zA-Z]+'))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  int _countWords(String text) {
    return _extractWords(text).length;
  }

  List<String> extractHighlights(SubtitleCue cue) {
    final highlights = <String>[];

    if (cue.collocationTokens != null) {
      for (final ct in cue.collocationTokens!) {
        highlights.add(ct.text);
      }
    }

    if (cue.cefrTokens != null) {
      for (final cefr in cue.cefrTokens!) {
        if (highValueLevels.contains(cefr.level) && cefr.meaning != null) {
          final alreadyCovered = highlights.any((h) => h.contains(cefr.word));
          if (!alreadyCovered) {
            highlights.add(cefr.word);
          }
        }
      }
    }

    final phrasePatterns = _extractPhrasalPatterns(cue.text);
    for (final phrase in phrasePatterns) {
      final alreadyCovered =
          highlights.any((h) => h.toLowerCase() == phrase.toLowerCase());
      if (!alreadyCovered) {
        highlights.add(phrase);
      }
    }

    return highlights.take(5).toList();
  }

  static final RegExp _phrasalVerbPattern = RegExp(
    r'\b(come|go|get|put|take|turn|bring|give|make|set|run|look|find|work|'
    r'pick|break|carry|hold|call|cut|pull|drop|fall|hang|keep|let|pass|'
    r'show|stand|think|throw|walk|back|check|clean|count|cross|die|do|'
    r'draw|drive|eat|face|fight|fill|figure|grow|hand|head|hear|help|hit|join|'
    r'kick|knock|lay|leave|live|lock|mark|move|name|open|pay|play|point|'
    r'pull|push|reach|roll|rule|save|send|settle|shake|shoot|shut|sign|'
    r'sit|sleep|sort|speak|start|stay|stop|tear|tell|tie|try|use|wait|'
    r'wake|wash|watch|wear|win|worry|write)\s+'
    r'(up|down|in|out|on|off|over|away|back|through|around|about|'
    r'forward|together|apart|aside|along|ahead|into|after|for|with)\b',
    caseSensitive: false,
  );

  List<String> _extractPhrasalPatterns(String text) {
    final matches = _phrasalVerbPattern.allMatches(text);
    return matches.map((m) => m.group(0)!).toSet().toList();
  }

  List<MemorizationMeta> evaluateAll(List<SubtitleCue> cues) {
    return cues.map((cue) {
      final score = calculateScore(cue);
      final highlights = extractHighlights(cue);
      final reason = _buildReason(cue, score);
      return MemorizationMeta(
        score: score,
        reason: reason,
        highlights: highlights,
        isAiEnhanced: false,
      );
    }).toList();
  }

  String? _buildReason(SubtitleCue cue, double score) {
    if (score < 3.0) return null;
    final parts = <String>[];
    final wordCount = _countWords(cue.text);
    if (wordCount >= idealWordCountMin && wordCount <= idealWordCountMax) {
      parts.add('长度适中');
    }
    if (cue.collocationTokens != null && cue.collocationTokens!.isNotEmpty) {
      final names = cue.collocationTokens!.map((t) => t.text).take(2).join('、');
      parts.add('含搭配「$names」');
    }
    final phrasalVerbs = _extractPhrasalPatterns(cue.text);
    if (phrasalVerbs.isNotEmpty) {
      final verb = phrasalVerbs.first;
      parts.add('含短语动词「$verb」');
    }
    if (cue.cefrTokens != null && cue.cefrTokens!.isNotEmpty) {
      final highValue = cue.cefrTokens!
          .where((t) => highValueLevels.contains(t.level))
          .length;
      if (highValue > 0) {
        parts.add('含 B1+ 词汇');
      }
    }
    if (parts.isEmpty) return null;
    return parts.join('，');
  }
}