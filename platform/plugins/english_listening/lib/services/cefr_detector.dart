import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subtitle.dart';

class CefrDetector {
  Map<String, _VocabEntry> _dictionary = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadDictionary() async {
    String jsonStr;
    try {
      jsonStr = await rootBundle.loadString('packages/english_listening/assets/cefr_vocabulary.json');
    } catch (_) {
      jsonStr = await rootBundle.loadString('assets/cefr_vocabulary.json');
    }
    final map = json.decode(jsonStr) as Map<String, dynamic>;

    _dictionary = map.map(
      (key, value) {
        final entry = value as Map<String, dynamic>;
        return MapEntry(
          key.toLowerCase(),
          _VocabEntry(
            level: entry['level'] as String,
            meaning: entry['meaning'] as String?,
          ),
        );
      },
    );

    _isLoaded = true;
  }

  List<CefrToken> detect(String text) {
    if (!_isLoaded || text.isEmpty) return [];

    final tokens = <CefrToken>[];

    final words = _tokenize(text);
    final matchedIndices = <int>{};

    _detectPhrases(text, words, tokens, matchedIndices, 3);
    _detectPhrases(text, words, tokens, matchedIndices, 2);

    for (int i = 0; i < words.length; i++) {
      if (matchedIndices.contains(i)) continue;
      _detectWord(words[i], tokens, matchedIndices, i);
    }

    tokens.sort((a, b) => a.startIndex.compareTo(b.startIndex));
    return tokens;
  }

  void _detectPhrases(
    String text,
    List<_WordPosition> words,
    List<CefrToken> tokens,
    Set<int> matchedIndices,
    int n,
  ) {
    for (int i = 0; i <= words.length - n; i++) {
      if (matchedIndices.contains(i)) continue;

      final phraseWords = words.sublist(i, i + n);
      final phrase = phraseWords.map((w) => w.text).join(' ').toLowerCase();

      final entry = _dictionary[phrase];
      if (entry != null) {
        tokens.add(CefrToken(
          word: phrase,
          level: entry.level,
          meaning: entry.meaning,
          startIndex: phraseWords.first.startIndex,
          endIndex: phraseWords.last.endIndex,
        ));
        for (int j = i; j < i + n; j++) {
          matchedIndices.add(j);
        }
      }
    }
  }

  void _detectWord(
    _WordPosition word,
    List<CefrToken> tokens,
    Set<int> matchedIndices,
    int index,
  ) {
    final lower = word.text.toLowerCase();
    final entry = _dictionary[lower];
    if (entry != null) {
      tokens.add(CefrToken(
        word: word.text,
        level: entry.level,
        meaning: entry.meaning,
        startIndex: word.startIndex,
        endIndex: word.endIndex,
      ));
      matchedIndices.add(index);
      return;
    }

    final lemma = _lemmatize(word.text);
    if (lemma != word.text.toLowerCase()) {
      final lemmaEntry = _dictionary[lemma];
      if (lemmaEntry != null) {
        tokens.add(CefrToken(
          word: word.text,
          level: lemmaEntry.level,
          meaning: lemmaEntry.meaning,
          startIndex: word.startIndex,
          endIndex: word.endIndex,
        ));
        matchedIndices.add(index);
      }
    }
  }

  List<_WordPosition> _tokenize(String text) {
    final words = <_WordPosition>[];
    final pattern = RegExp(r"[a-zA-Z'-]+");

    for (final match in pattern.allMatches(text)) {
      words.add(_WordPosition(
        text: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }

    return words;
  }

  String _lemmatize(String word) {
    final lower = word.toLowerCase();

    if (lower.length <= 3) return lower;

    if (lower.endsWith('running') && lower.length > 7) {
      return lower.replaceRange(lower.length - 7, lower.length, '');
    }

    if (lower.endsWith('ing') && lower.length > 4) {
      final base = lower.substring(0, lower.length - 3);
      if (base.endsWith(base[base.length - 1])) {
        return base.substring(0, base.length - 1);
      }
      return base;
    }

    if (lower.endsWith('ed') && lower.length > 4) {
      final base = lower.substring(0, lower.length - 2);
      if (base.endsWith(base[base.length - 1])) {
        return base.substring(0, base.length - 1);
      }
      return base;
    }

    if (lower.endsWith('es') && lower.length > 4) {
      return lower.substring(0, lower.length - 2);
    }

    if (lower.endsWith('s') && !lower.endsWith('ss') && lower.length > 3) {
      return lower.substring(0, lower.length - 1);
    }

    if (lower.endsWith('er') && lower.length > 4) {
      return lower.substring(0, lower.length - 2);
    }

    if (lower.endsWith('est') && lower.length > 5) {
      return lower.substring(0, lower.length - 3);
    }

    if (lower.endsWith('ly') && lower.length > 4) {
      return lower.substring(0, lower.length - 2);
    }

    if (lower.endsWith("'s") && lower.length > 3) {
      return lower.substring(0, lower.length - 2);
    }

    if (lower.endsWith('ies') && lower.length > 4) {
      return '${lower.substring(0, lower.length - 3)}y';
    }

    if (lower.endsWith('ier') && lower.length > 4) {
      return '${lower.substring(0, lower.length - 3)}y';
    }

    if (lower.endsWith('iest') && lower.length > 5) {
      return '${lower.substring(0, lower.length - 4)}y';
    }

    return lower;
  }
}

class _VocabEntry {
  final String level;
  final String? meaning;

  const _VocabEntry({required this.level, this.meaning});
}

class _WordPosition {
  final String text;
  final int startIndex;
  final int endIndex;

  const _WordPosition({
    required this.text,
    required this.startIndex,
    required this.endIndex,
  });
}