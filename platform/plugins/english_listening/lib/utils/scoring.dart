class ScoringUtils {
  ScoringUtils._();

  static String normalizeForCompare(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9 ']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double calcAccuracy(String expected, String typed) {
    final normalizedExpected = normalizeForCompare(expected);
    final normalizedTyped = normalizeForCompare(typed);

    if (normalizedExpected.isEmpty && normalizedTyped.isEmpty) {
      return 100.0;
    }
    if (normalizedExpected.isEmpty || normalizedTyped.isEmpty) {
      return 0.0;
    }

    final maxLen = normalizedExpected.length > normalizedTyped.length
        ? normalizedExpected.length
        : normalizedTyped.length;

    int matches = 0;
    for (int i = 0; i < maxLen; i++) {
      final expectedChar =
          i < normalizedExpected.length ? normalizedExpected[i] : null;
      final typedChar =
          i < normalizedTyped.length ? normalizedTyped[i] : null;
      if (expectedChar == typedChar) {
        matches++;
      }
    }

    return (matches / maxLen * 100).roundToDouble();
  }

  static List<CharDiff> buildCharDiff(String expected, String typed) {
    final normalizedExpected = normalizeForCompare(expected);
    final normalizedTyped = normalizeForCompare(typed);
    final diffs = <CharDiff>[];

    final maxLen = normalizedExpected.length > normalizedTyped.length
        ? normalizedExpected.length
        : normalizedTyped.length;

    for (int i = 0; i < maxLen; i++) {
      final expectedChar =
          i < normalizedExpected.length ? normalizedExpected[i] : null;
      final typedChar =
          i < normalizedTyped.length ? normalizedTyped[i] : null;

      if (expectedChar == null) {
        diffs.add(CharDiff(
          char: typedChar!,
          status: CharDiffStatus.extra,
        ));
      } else if (typedChar == null) {
        diffs.add(CharDiff(
          char: expectedChar,
          status: CharDiffStatus.missing,
        ));
      } else if (expectedChar == typedChar) {
        diffs.add(CharDiff(
          char: expectedChar,
          status: CharDiffStatus.correct,
        ));
      } else {
        diffs.add(CharDiff(
          char: expectedChar,
          typedChar: typedChar,
          status: CharDiffStatus.incorrect,
        ));
      }
    }

    return diffs;
  }
}

enum CharDiffStatus { correct, incorrect, missing, extra }

class CharDiff {
  final String char;
  final String? typedChar;
  final CharDiffStatus status;

  const CharDiff({
    required this.char,
    this.typedChar,
    required this.status,
  });
}