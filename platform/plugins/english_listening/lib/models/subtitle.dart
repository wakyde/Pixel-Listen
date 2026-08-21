class MemorizationMeta {
  final int? index;
  final double score;
  final String? reason;
  final List<String> highlights;
  final String? scenario;
  final bool isAiEnhanced;

  const MemorizationMeta({
    this.index,
    required this.score,
    this.reason,
    this.highlights = const [],
    this.scenario,
    this.isAiEnhanced = false,
  });

  factory MemorizationMeta.fromJson(Map<String, dynamic> json) {
    return MemorizationMeta(
      index: (json['index'] as num?)?.toInt(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      reason: json['reason'] as String?,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      scenario: json['scenario'] as String?,
      isAiEnhanced: json['is_ai_enhanced'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'index': index,
        'score': score,
        'reason': reason,
        'highlights': highlights,
        'scenario': scenario,
        'is_ai_enhanced': isAiEnhanced,
      };
}

class KeyPhrase {
  final String phrase;
  final String meaning;

  const KeyPhrase({required this.phrase, required this.meaning});

  factory KeyPhrase.fromJson(Map<String, dynamic> json) {
    return KeyPhrase(
      phrase: json['phrase'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }
}

class MemoCardTemplate {
  final String clozeText;
  final String hint;
  final List<KeyPhrase> keyPhrases;
  final String usageNote;

  const MemoCardTemplate({
    required this.clozeText,
    required this.hint,
    this.keyPhrases = const [],
    this.usageNote = '',
  });

  factory MemoCardTemplate.fromJson(Map<String, dynamic> json) {
    return MemoCardTemplate(
      clozeText: json['cloze_text'] as String? ?? '',
      hint: json['hint'] as String? ?? '',
      keyPhrases: (json['key_phrases'] as List<dynamic>?)
              ?.map((e) => KeyPhrase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      usageNote: json['usage_note'] as String? ?? '',
    );
  }
}

class SubtitleCue {
  final String id;
  final Duration start;
  final Duration end;
  final String text;
  final String? nativeTranslation;
  final List<CefrToken>? cefrTokens;
  final List<CollocationToken>? collocationTokens;
  final MemorizationMeta? memorizationMeta;

  const SubtitleCue({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
    this.nativeTranslation,
    this.cefrTokens,
    this.collocationTokens,
    this.memorizationMeta,
  });
}

class GrammarPoint {
  final String name;
  final String explanation;
  final String example;
  final String relatedText;

  const GrammarPoint({
    required this.name,
    required this.explanation,
    required this.example,
    required this.relatedText,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      name: json['name'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      example: json['example'] as String? ?? '',
      relatedText: json['related_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'explanation': explanation,
        'example': example,
        'related_text': relatedText,
      };
}

class GrammarAnalysis {
  final List<GrammarPoint> grammarPoints;
  final String sentenceStructure;
  final String sentenceType;
  final String tense;
  final String difficulty;
  final String notes;

  const GrammarAnalysis({
    this.grammarPoints = const [],
    this.sentenceStructure = '',
    this.sentenceType = '',
    this.tense = '',
    this.difficulty = '',
    this.notes = '',
  });

  factory GrammarAnalysis.fromJson(Map<String, dynamic> json) {
    return GrammarAnalysis(
      grammarPoints: (json['grammar_points'] as List<dynamic>?)
              ?.map((e) => GrammarPoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sentenceStructure: json['sentence_structure'] as String? ?? '',
      sentenceType: json['sentence_type'] as String? ?? '',
      tense: json['tense'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'grammar_points': grammarPoints.map((g) => g.toJson()).toList(),
        'sentence_structure': sentenceStructure,
        'sentence_type': sentenceType,
        'tense': tense,
        'difficulty': difficulty,
        'notes': notes,
      };
}

class CefrToken {
  final String word;
  final String level;
  final String? meaning;
  final int startIndex;
  final int endIndex;

  const CefrToken({
    required this.word,
    required this.level,
    this.meaning,
    required this.startIndex,
    required this.endIndex,
  });
}

class CollocationToken {
  final String text;
  final String type;
  final String? meaning;
  final int startIndex;
  final int endIndex;
  final bool aiDetected;

  const CollocationToken({
    required this.text,
    required this.type,
    this.meaning,
    required this.startIndex,
    required this.endIndex,
    this.aiDetected = false,
  });
}

class WordSense {
  final String definitionEn;
  final String definitionZh;

  const WordSense({
    required this.definitionEn,
    required this.definitionZh,
  });

  factory WordSense.fromJson(Map<String, dynamic> json) {
    return WordSense(
      definitionEn: json['definition_en'] as String? ?? '',
      definitionZh: json['definition_zh'] as String? ?? '',
    );
  }
}

class WordExample {
  final String sentenceEn;
  final String sentenceZh;

  const WordExample({
    required this.sentenceEn,
    required this.sentenceZh,
  });

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      sentenceEn: json['sentence_en'] as String? ?? '',
      sentenceZh: json['sentence_zh'] as String? ?? '',
    );
  }
}

class ExampleSentence {
  final String sentenceEn;
  final String sentenceZh;

  const ExampleSentence({
    required this.sentenceEn,
    required this.sentenceZh,
  });

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    return ExampleSentence(
      sentenceEn: json['sentence_en'] as String? ?? '',
      sentenceZh: json['sentence_zh'] as String? ?? '',
    );
  }
}

class WordCollocation {
  final String phrase;
  final String meaning;

  const WordCollocation({
    required this.phrase,
    required this.meaning,
  });

  factory WordCollocation.fromJson(Map<String, dynamic> json) {
    return WordCollocation(
      phrase: json['phrase'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
    );
  }
}

class ConfusableWord {
  final String word;
  final String meaning;
  final String difference;

  const ConfusableWord({
    required this.word,
    required this.meaning,
    required this.difference,
  });

  factory ConfusableWord.fromJson(Map<String, dynamic> json) {
    return ConfusableWord(
      word: json['word'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      difference: json['difference'] as String? ?? '',
    );
  }
}

class WordLookupResult {
  final String word;
  final String phoneticUs;
  final List<WordSense> senses;
  final List<WordExample> examples;
  final List<WordCollocation> collocations;
  final List<ConfusableWord> confusableWords;

  const WordLookupResult({
    required this.word,
    required this.phoneticUs,
    required this.senses,
    required this.examples,
    required this.collocations,
    required this.confusableWords,
  });

  factory WordLookupResult.fromJson(Map<String, dynamic> json) {
    return WordLookupResult(
      word: json['word'] as String? ?? '',
      phoneticUs: json['phonetic_us'] as String? ?? '',
      senses: (json['senses'] as List<dynamic>?)
              ?.map((e) => WordSense.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => WordExample.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      collocations: (json['collocations'] as List<dynamic>?)
              ?.map((e) => WordCollocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      confusableWords: (json['confusable_words'] as List<dynamic>?)
              ?.map((e) => ConfusableWord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TutorChatMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  const TutorChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  bool get isUser => role == 'user';
}

class MistakeRecord {
  final String expected;
  final String typed;
  final double accuracy;

  const MistakeRecord({
    required this.expected,
    required this.typed,
    required this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'expected': expected,
        'typed': typed,
        'accuracy': accuracy,
      };
}

class MistakePattern {
  final String type;
  final String description;
  final List<String> examples;

  const MistakePattern({
    required this.type,
    required this.description,
    required this.examples,
  });

  factory MistakePattern.fromJson(Map<String, dynamic> json) {
    return MistakePattern(
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      examples: (json['examples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class MistakeAnalysis {
  final List<MistakePattern> patterns;
  final List<String> suggestions;

  const MistakeAnalysis({
    required this.patterns,
    required this.suggestions,
  });

  factory MistakeAnalysis.fromJson(Map<String, dynamic> json) {
    return MistakeAnalysis(
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => MistakePattern.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }
}

class DictationSentence {
  final String text;
  final String focusPattern;

  const DictationSentence({
    required this.text,
    required this.focusPattern,
  });

  factory DictationSentence.fromJson(Map<String, dynamic> json) {
    return DictationSentence(
      text: json['text'] as String? ?? '',
      focusPattern: json['focus_pattern'] as String? ?? '',
    );
  }
}

enum PlayerState { idle, loading, playing, paused, error }

enum SubtitleDisplayMode { english, native, bilingual, hidden }

class PlayerStatus {
  final PlayerState state;
  final Duration position;
  final Duration duration;
  final bool isLooping;
  final Duration? loopStart;
  final Duration? loopEnd;
  final Duration leadTime;
  final int? activeCueIndex;
  final bool skipSilent;

  const PlayerStatus({
    this.state = PlayerState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLooping = false,
    this.loopStart,
    this.loopEnd,
    this.leadTime = Duration.zero,
    this.activeCueIndex,
    this.skipSilent = false,
  });

  PlayerStatus copyWith({
    PlayerState? state,
    Duration? position,
    Duration? duration,
    bool? isLooping,
    Duration? loopStart,
    Duration? loopEnd,
    Duration? leadTime,
    int? activeCueIndex,
    bool clearLoopStart = false,
    bool clearLoopEnd = false,
    bool? skipSilent,
  }) {
    return PlayerStatus(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLooping: isLooping ?? this.isLooping,
      loopStart: clearLoopStart ? null : (loopStart ?? this.loopStart),
      loopEnd: clearLoopEnd ? null : (loopEnd ?? this.loopEnd),
      leadTime: leadTime ?? this.leadTime,
      activeCueIndex: activeCueIndex ?? this.activeCueIndex,
      skipSilent: skipSilent ?? this.skipSilent,
    );
  }
}