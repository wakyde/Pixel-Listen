import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/utils/scoring.dart';

void main() {
  group('normalizeForCompare', () {
    test('converts to lowercase', () {
      expect(ScoringUtils.normalizeForCompare('Hello World'), 'hello world');
    });

    test('removes punctuation except apostrophe', () {
      expect(
        ScoringUtils.normalizeForCompare('Hello, world! How\'s it going?'),
        'hello world how\'s it going',
      );
    });

    test('collapses multiple spaces', () {
      expect(
        ScoringUtils.normalizeForCompare('Hello   world'),
        'hello world',
      );
    });

    test('trims leading and trailing spaces', () {
      expect(
        ScoringUtils.normalizeForCompare('  hello world  '),
        'hello world',
      );
    });

    test('returns empty string for pure punctuation', () {
      expect(ScoringUtils.normalizeForCompare('...,!!!'), '');
    });
  });

  group('calcAccuracy', () {
    test('perfect match returns 100%', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, world!', 'Hello, world!');
      expect(accuracy, 100.0);
    });

    test('partial match scores correctly', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, world!', 'Hello word');
      expect(accuracy, closeTo(81.8, 0.5));
    });

    test('case insensitive', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, World!', 'hello, world!');
      expect(accuracy, 100.0);
    });

    test('punctuation ignored', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, world!', 'hello world');
      expect(accuracy, 100.0);
    });

    test('empty input returns 0%', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, world!', '');
      expect(accuracy, 0.0);
    });

    test('both empty returns 100%', () {
      final accuracy = ScoringUtils.calcAccuracy('', '');
      expect(accuracy, 100.0);
    });

    test('pure punctuation input returns 0%', () {
      final accuracy = ScoringUtils.calcAccuracy('Hello, world!', '...,!!!');
      expect(accuracy, 0.0);
    });
  });

  group('buildCharDiff', () {
    test('correct characters marked correctly', () {
      final diffs = ScoringUtils.buildCharDiff('hello', 'hello');
      expect(diffs.length, 5);
      for (final diff in diffs) {
        expect(diff.status, CharDiffStatus.correct);
      }
    });

    test('incorrect characters marked incorrectly', () {
      final diffs = ScoringUtils.buildCharDiff('hello', 'hallo');
      expect(diffs[1].status, CharDiffStatus.incorrect);
      expect(diffs[1].char, 'e');
      expect(diffs[1].typedChar, 'a');
    });

    test('missing characters marked missing', () {
      final diffs = ScoringUtils.buildCharDiff('hello', 'hel');
      expect(diffs[3].status, CharDiffStatus.missing);
      expect(diffs[4].status, CharDiffStatus.missing);
    });

    test('extra characters marked extra', () {
      final diffs = ScoringUtils.buildCharDiff('hel', 'hello');
      final extraDiffs = diffs.where((d) => d.status == CharDiffStatus.extra);
      expect(extraDiffs.length, 2);
    });
  });
}