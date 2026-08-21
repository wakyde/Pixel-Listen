import '../models/song_models.dart';

class LiaisonDetector {
  static const _vowels = 'aeiouAEIOU';
  static const _consonants = 'bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ';

  static List<LiaisonMark> detect(String text) {
    if (text.isEmpty) return [];

    final cjkCount = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').allMatches(text).length;
    if (cjkCount >= text.length * 0.8) return [];

    final marks = <LiaisonMark>[];

    final cleanText = text.replaceAll(RegExp(r"[^\w\s']"), '');
    final words = cleanText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return marks;

    int charOffset = 0;
    final wordPositions = <int>[];

    for (int i = 0; i < words.length; i++) {
      final pos = text.indexOf(words[i], charOffset);
      if (pos >= 0) {
        wordPositions.add(pos);
        charOffset = pos + words[i].length;
      } else {
        wordPositions.add(charOffset);
        charOffset += words[i].length + 1;
      }
    }

    for (int i = 0; i < words.length - 1; i++) {
      final w1 = words[i];
      final w2 = words[i + 1];
      if (w1.isEmpty || w2.isEmpty) continue;

      final lastChar = w1[w1.length - 1];
      final firstChar = w2[0];

      _detectTPJ(w1, w2, i, wordPositions, text, marks);

      _detectDPJ(w1, w2, i, wordPositions, text, marks);

      _detectWeakForm(w1, w2, i, wordPositions, text, marks);

      _detectConsonantVowel(w1, w2, lastChar, firstChar, i, wordPositions, text, marks);

      _detectSameConsonant(w1, w2, lastChar, firstChar, i, wordPositions, text, marks);
    }

    marks.sort((a, b) => a.startChar.compareTo(b.startChar));

    final filtered = <LiaisonMark>[];
    for (final mark in marks) {
      final overlaps = filtered.where((f) =>
          (mark.startChar >= f.startChar && mark.startChar < f.endChar) ||
          (mark.endChar > f.startChar && mark.endChar <= f.endChar));
      if (overlaps.isEmpty) {
        filtered.add(mark);
      }
    }

    return filtered;
  }

  static void _detectTPJ(
    String w1,
    String w2,
    int idx,
    List<int> positions,
    String text,
    List<LiaisonMark> marks,
  ) {
    if (!w1.endsWith('t') && !w1.endsWith('T')) return;
    final w2Lower = w2.toLowerCase();
    if (w2Lower != 'you' && w2Lower != 'your' && w2Lower != 'yours' && w2Lower != 'yourself') {
      return;
    }

    final startPos = positions[idx];
    final endPos = positions[idx + 1] + w2.length;
    if (endPos > text.length) return;

    final phrase = text.substring(startPos, endPos);
    final pronunciation = _makeTPronunciation(w1, w2);

    marks.add(LiaisonMark(
      text: phrase,
      startChar: startPos,
      endChar: endPos,
      type: LiaisonType.tPlusJ,
      pronunciation: pronunciation,
      detectedBy: 'rule',
    ));
  }

  static void _detectDPJ(
    String w1,
    String w2,
    int idx,
    List<int> positions,
    String text,
    List<LiaisonMark> marks,
  ) {
    if (!w1.endsWith('d') && !w1.endsWith('D')) return;
    final w2Lower = w2.toLowerCase();
    if (w2Lower != 'you' && w2Lower != 'your' && w2Lower != 'yours' && w2Lower != 'yourself') {
      return;
    }

    final startPos = positions[idx];
    final endPos = positions[idx + 1] + w2.length;
    if (endPos > text.length) return;

    final phrase = text.substring(startPos, endPos);
    final pronunciation = _makeDPronunciation(w1, w2);

    marks.add(LiaisonMark(
      text: phrase,
      startChar: startPos,
      endChar: endPos,
      type: LiaisonType.dPlusJ,
      pronunciation: pronunciation,
      detectedBy: 'rule',
    ));
  }

  static void _detectWeakForm(
    String w1,
    String w2,
    int idx,
    List<int> positions,
    String text,
    List<LiaisonMark> marks,
  ) {
    final weakForms = {
      'going to': 'gonna',
      'want to': 'wanna',
      'got to': 'gotta',
      'have to': 'hafta',
      'has to': 'hasta',
      'kind of': 'kinda',
      'sort of': 'sorta',
      'lot of': 'lotta',
      'out of': 'outta',
    };

    final w1Lower = w1.toLowerCase();
    final w2Lower = w2.toLowerCase();
    final combo = '$w1Lower $w2Lower';

    if (weakForms.containsKey(combo)) {
      final startPos = positions[idx];
      final endPos = positions[idx + 1] + w2.length;
      if (endPos > text.length) return;

      marks.add(LiaisonMark(
        text: text.substring(startPos, endPos),
        startChar: startPos,
        endChar: endPos,
        type: LiaisonType.weakForm,
        pronunciation: weakForms[combo]!,
        detectedBy: 'rule',
      ));
    }
  }

  static void _detectConsonantVowel(
    String w1,
    String w2,
    String lastChar,
    String firstChar,
    int idx,
    List<int> positions,
    String text,
    List<LiaisonMark> marks,
  ) {
    if (!_consonants.contains(lastChar)) return;
    if (!_vowels.contains(firstChar)) return;

    final startPos = positions[idx];
    final endPos = positions[idx + 1] + w2.length;
    if (endPos > text.length) return;

    final phrase = text.substring(startPos, endPos);
    final pronunciation = '${w1.toLowerCase()}-${w2.toLowerCase()}';

    marks.add(LiaisonMark(
      text: phrase,
      startChar: startPos,
      endChar: endPos,
      type: LiaisonType.consonantVowel,
      pronunciation: pronunciation,
      detectedBy: 'rule',
    ));
  }

  static void _detectSameConsonant(
    String w1,
    String w2,
    String lastChar,
    String firstChar,
    int idx,
    List<int> positions,
    String text,
    List<LiaisonMark> marks,
  ) {
    if (lastChar.toLowerCase() != firstChar.toLowerCase()) return;
    if (!_consonants.contains(lastChar)) return;

    final startPos = positions[idx];
    final endPos = positions[idx + 1] + w2.length;
    if (endPos > text.length) return;

    final phrase = text.substring(startPos, endPos);
    final w1WithoutLast = w1.substring(0, w1.length - 1);
    final pronunciation = '${w1WithoutLast.toLowerCase()}-${w2.toLowerCase()}';

    marks.add(LiaisonMark(
      text: phrase,
      startChar: startPos,
      endChar: endPos,
      type: LiaisonType.sameConsonant,
      pronunciation: pronunciation,
      detectedBy: 'rule',
    ));
  }

  static String _makeTPronunciation(String w1, String w2) {
    final base = w1.substring(0, w1.length - 1);
    final suffix = w2.toLowerCase() == 'you' ? 'chyou' : 'chy${w2.substring(3)}';
    return '${base.toLowerCase()}-$suffix';
  }

  static String _makeDPronunciation(String w1, String w2) {
    final base = w1.substring(0, w1.length - 1);
    final suffix = w2.toLowerCase() == 'you' ? 'jyou' : 'jy${w2.substring(3)}';
    return '${base.toLowerCase()}-$suffix';
  }
}