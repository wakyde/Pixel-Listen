class SongLyrics {
  final String id;
  final String songTitle;
  final String? artist;
  final String filePath;
  final String lyricsFormat;
  final String? audioFilePath;
  final int lineCount;
  final bool hasTimestamps;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> parseErrors;

  const SongLyrics({
    required this.id,
    required this.songTitle,
    this.artist,
    required this.filePath,
    required this.lyricsFormat,
    this.audioFilePath,
    required this.lineCount,
    required this.hasTimestamps,
    required this.createdAt,
    required this.updatedAt,
    this.parseErrors = const [],
  });
}

class SongLyricLine {
  final String id;
  final String songId;
  final int lineIndex;
  final double? startTime;
  final double? endTime;
  final String text;
  final String? textZh;
  final List<WordTiming>? wordTimings;
  final List<LiaisonMark>? liaisonMarks;
  final DateTime createdAt;

  const SongLyricLine({
    required this.id,
    required this.songId,
    required this.lineIndex,
    this.startTime,
    this.endTime,
    required this.text,
    this.textZh,
    this.wordTimings,
    this.liaisonMarks,
    required this.createdAt,
  });

  SongLyricLine copyWith({
    List<LiaisonMark>? liaisonMarks,
  }) {
    return SongLyricLine(
      id: id,
      songId: songId,
      lineIndex: lineIndex,
      startTime: startTime,
      endTime: endTime,
      text: text,
      textZh: textZh,
      wordTimings: wordTimings,
      liaisonMarks: liaisonMarks ?? this.liaisonMarks,
      createdAt: createdAt,
    );
  }
}

class WordTiming {
  final String word;
  final double time;

  const WordTiming({
    required this.word,
    required this.time,
  });

  factory WordTiming.fromJson(Map<String, dynamic> json) {
    return WordTiming(
      word: json['word'] as String,
      time: (json['time'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'word': word,
        'time': time,
      };
}

class LiaisonMark {
  final String text;
  final int startChar;
  final int endChar;
  final LiaisonType type;
  final String pronunciation;
  final String detectedBy;

  const LiaisonMark({
    required this.text,
    required this.startChar,
    required this.endChar,
    required this.type,
    required this.pronunciation,
    required this.detectedBy,
  });

  factory LiaisonMark.fromJson(Map<String, dynamic> json) {
    return LiaisonMark(
      text: json['text'] as String,
      startChar: json['startChar'] as int,
      endChar: json['endChar'] as int,
      type: LiaisonType.fromString(json['type'] as String),
      pronunciation: json['pronunciation'] as String,
      detectedBy: json['detectedBy'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'startChar': startChar,
        'endChar': endChar,
        'type': type.name,
        'pronunciation': pronunciation,
        'detectedBy': detectedBy,
      };
}

enum LiaisonType {
  consonantVowel,
  sameConsonant,
  tPlusJ,
  dPlusJ,
  weakForm,
  linkingR,
  intrusiveR,
  elision,
  other;

  String get name {
    switch (this) {
      case LiaisonType.consonantVowel:
        return 'consonantVowel';
      case LiaisonType.sameConsonant:
        return 'sameConsonant';
      case LiaisonType.tPlusJ:
        return 'tPlusJ';
      case LiaisonType.dPlusJ:
        return 'dPlusJ';
      case LiaisonType.weakForm:
        return 'weakForm';
      case LiaisonType.linkingR:
        return 'linkingR';
      case LiaisonType.intrusiveR:
        return 'intrusiveR';
      case LiaisonType.elision:
        return 'elision';
      case LiaisonType.other:
        return 'other';
    }
  }

  String get displayName {
    switch (this) {
      case LiaisonType.consonantVowel:
        return 'consonantVowel';
      case LiaisonType.sameConsonant:
        return 'sameConsonant';
      case LiaisonType.tPlusJ:
        return '/t/+/j/\u2192/t\u0283/';
      case LiaisonType.dPlusJ:
        return '/d/+/j/\u2192/d\u0292/';
      case LiaisonType.weakForm:
        return 'weakForm';
      case LiaisonType.linkingR:
        return 'linkingR';
      case LiaisonType.intrusiveR:
        return 'intrusiveR';
      case LiaisonType.elision:
        return 'elision';
      case LiaisonType.other:
        return 'other';
    }
  }

  static LiaisonType fromString(String s) {
    switch (s) {
      case 'consonantVowel':
        return LiaisonType.consonantVowel;
      case 'sameConsonant':
        return LiaisonType.sameConsonant;
      case 'tPlusJ':
        return LiaisonType.tPlusJ;
      case 'dPlusJ':
        return LiaisonType.dPlusJ;
      case 'weakForm':
        return LiaisonType.weakForm;
      case 'linkingR':
        return LiaisonType.linkingR;
      case 'intrusiveR':
        return LiaisonType.intrusiveR;
      case 'elision':
        return LiaisonType.elision;
      default:
        return LiaisonType.other;
    }
  }
}

class SongRecording {
  final String id;
  final String lyricLineId;
  final String filePath;
  final double duration;
  final int sampleRate;
  final DateTime createdAt;

  const SongRecording({
    required this.id,
    required this.lyricLineId,
    required this.filePath,
    required this.duration,
    required this.sampleRate,
    required this.createdAt,
  });
}

class SongScore {
  final String id;
  final String recordingId;
  final String lyricLineId;
  final int totalScore;
  final int? pronunciationScore;
  final int? rhythmScore;
  final int? liaisonScore;
  final DateTime createdAt;

  const SongScore({
    required this.id,
    required this.recordingId,
    required this.lyricLineId,
    required this.totalScore,
    this.pronunciationScore,
    this.rhythmScore,
    this.liaisonScore,
    required this.createdAt,
  });
}