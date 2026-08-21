import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/models/subtitle.dart';
import 'package:english_listening/services/memorization_scorer.dart';

void main() {
  late MemorizationScorer scorer;

  setUp(() {
    scorer = MemorizationScorer();
  });

  group('calculateScore', () {
    test('simple line scores low', () {
      final cue = SubtitleCue(
        id: '1',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'Hello.',
      );
      final score = scorer.calculateScore(cue);
      expect(score, lessThan(5.0));
    });

    test('complex line with CEFR tokens scores higher', () {
      final cue = SubtitleCue(
        id: '2',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'Nevertheless, I would argue that the fundamental issue remains unresolved.',
        cefrTokens: [
          const CefrToken(
            word: 'Nevertheless',
            level: 'B2',
            startIndex: 0,
            endIndex: 12,
          ),
          const CefrToken(
            word: 'fundamental',
            level: 'B2',
            startIndex: 38,
            endIndex: 49,
          ),
          const CefrToken(
            word: 'unresolved',
            level: 'C1',
            startIndex: 56,
            endIndex: 66,
          ),
        ],
      );
      final score = scorer.calculateScore(cue);
      expect(score, greaterThan(5.0));
    });

    test('line with collocations scores higher', () {
      final cue = SubtitleCue(
        id: '3',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'I ran into my old friend at the grocery store.',
        collocationTokens: [
          const CollocationToken(
            text: 'ran into',
            meaning: '偶遇',
            type: 'phrasalVerb',
            startIndex: 2,
            endIndex: 10,
          ),
        ],
      );
      final score = scorer.calculateScore(cue);
      expect(score, greaterThan(5.0));
    });

    test('trivial line scores very low', () {
      final cue = SubtitleCue(
        id: '4',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'OK.',
      );
      final score = scorer.calculateScore(cue);
      expect(score, lessThan(4.0));
    });

    test('score is always within 1-10 range', () {
      final testCases = [
        'What?',
        'Yeah, sure.',
        'I think we should consider the potential consequences of this decision.',
        'The unprecedented growth of artificial intelligence has fundamentally reshaped our understanding of cognitive processes.',
        'Hmm.',
      ];

      for (final text in testCases) {
        final cue = SubtitleCue(
          id: 't',
          start: Duration.zero,
          end: const Duration(seconds: 1),
          text: text,
        );
        final score = scorer.calculateScore(cue);
        expect(score, greaterThanOrEqualTo(1.0));
        expect(score, lessThanOrEqualTo(10.0));
      }
    });
  });

  group('evaluateAll', () {
    test('returns MemorizationMeta for all cues', () {
      final cues = [
        SubtitleCue(
          id: '1',
          start: const Duration(seconds: 0),
          end: const Duration(seconds: 1),
          text: 'Hello there.',
        ),
        SubtitleCue(
          id: '2',
          start: const Duration(seconds: 1),
          end: const Duration(seconds: 2),
          text: 'How are you doing?',
        ),
      ];

      final results = scorer.evaluateAll(cues);
      expect(results.length, equals(2));
      expect(results[0].score, isNotNull);
      expect(results[0].isAiEnhanced, isFalse);
      expect(results[1].isAiEnhanced, isFalse);
    });

    test('returns empty list for empty cues', () {
      final results = scorer.evaluateAll([]);
      expect(results, isEmpty);
    });
  });

  group('extractHighlights', () {
    test('extracts words with CEFR tokens', () {
      final cue = SubtitleCue(
        id: '1',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'The fundamental issue remains.',
        cefrTokens: [
          const CefrToken(
            word: 'fundamental',
            level: 'B2',
            meaning: '基本的',
            startIndex: 4,
            endIndex: 15,
          ),
        ],
      );
      final highlights = scorer.extractHighlights(cue);
      expect(highlights, contains('fundamental'));
    });

    test('extracts collocation phrases', () {
      final cue = SubtitleCue(
        id: '1',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'I ran into my friend.',
        collocationTokens: [
          const CollocationToken(
            text: 'ran into',
            meaning: '偶遇',
            type: 'phrasalVerb',
            startIndex: 2,
            endIndex: 10,
          ),
        ],
      );
      final highlights = scorer.extractHighlights(cue);
      expect(highlights, contains('ran into'));
    });

    test('detects phrasal verbs from text', () {
      final cue = SubtitleCue(
        id: '1',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'Can you figure out what went wrong?',
      );
      final highlights = scorer.extractHighlights(cue);
      expect(highlights, contains('figure out'));
    });

    test('phrasal verb boosts score', () {
      final cueWithoutPhrasal = SubtitleCue(
        id: '1',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'I need to understand the problem.',
      );
      final cueWithPhrasal = SubtitleCue(
        id: '2',
        start: Duration.zero,
        end: const Duration(seconds: 1),
        text: 'I need to figure out the problem.',
      );
      final scoreWithout = scorer.calculateScore(cueWithoutPhrasal);
      final scoreWith = scorer.calculateScore(cueWithPhrasal);
      expect(scoreWith, greaterThan(scoreWithout));
    });
  });

  group('large dataset', () {
    test('scores all 700 cues without error', () {
      final cues = List.generate(700, (i) => SubtitleCue(
        id: '$i',
        start: Duration(seconds: i),
        end: Duration(seconds: i + 1),
        text: 'This is sentence number $i with some random words here.',
      ));
      final results = scorer.evaluateAll(cues);
      expect(results.length, equals(700));
      for (final result in results) {
        expect(result.score, greaterThanOrEqualTo(1.0));
        expect(result.score, lessThanOrEqualTo(10.0));
      }
    });
  });
}