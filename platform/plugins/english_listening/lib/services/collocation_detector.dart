import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/subtitle.dart';

class _CollocationEntry {
  final String type;
  final String? meaning;

  const _CollocationEntry({required this.type, this.meaning});
}

class CollocationDetector {
  Map<String, _CollocationEntry> _dictionary = {};
  bool _isLoaded = false;
  final Map<String, List<CollocationToken>> _cache = {};
  static const int _maxCacheSize = 200;

  bool get isLoaded => _isLoaded;

  Future<void> loadDictionary() async {
    String jsonStr;
    try {
      jsonStr = await rootBundle
          .loadString('packages/english_listening/assets/collocations.json');
    } catch (_) {
      jsonStr = await rootBundle.loadString('assets/collocations.json');
    }
    final map = json.decode(jsonStr) as Map<String, dynamic>;

    _dictionary = map.map(
      (key, value) {
        final entry = value as Map<String, dynamic>;
        return MapEntry(
          key.toLowerCase(),
          _CollocationEntry(
            type: entry['type'] as String? ?? 'phrase',
            meaning: entry['meaning'] as String?,
          ),
        );
      },
    );

    _isLoaded = true;
  }

  List<CollocationToken> detect(String text) {
    if (!_isLoaded || text.isEmpty) return [];

    final cached = _cache[text];
    if (cached != null) return cached;

    final tokens = <CollocationToken>[];
    final words = _tokenizeWithPositions(text);
    final matchedIndices = <int>{};

    for (int n = 5; n >= 2; n--) {
      _scanNGrams(text, words, tokens, matchedIndices, n);
    }

    tokens.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[text] = tokens;

    return tokens;
  }

  void _scanNGrams(
    String text,
    List<_WordPosition> words,
    List<CollocationToken> tokens,
    Set<int> matchedIndices,
    int n,
  ) {
    for (int i = 0; i <= words.length - n; i++) {
      if (matchedIndices.contains(i)) continue;

      final phraseWords = words.sublist(i, i + n);
      final phrase = phraseWords.map((w) => w.text).join(' ').toLowerCase();

      final entry = _dictionary[phrase];
      if (entry != null) {
        tokens.add(CollocationToken(
          text: phrase,
          type: entry.type,
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

  List<_WordPosition> _tokenizeWithPositions(String text) {
    final words = <_WordPosition>[];
    final regex = RegExp(r"[a-zA-Z'-]+");
    for (final match in regex.allMatches(text)) {
      words.add(_WordPosition(
        text: match.group(0)!,
        startIndex: match.start,
        endIndex: match.end,
      ));
    }
    return words;
  }
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