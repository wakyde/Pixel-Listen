import 'package:flutter_test/flutter_test.dart';

import 'package:english_songs/english_songs.dart';

void main() {
  group('SongLearningPlugin', () {
    test('plugin id should be unique', () {
      final plugin = SongLearningPlugin();
      expect(plugin.id, 'english_songs');
    });

    test('route path should start with /', () {
      final plugin = SongLearningPlugin();
      expect(plugin.routePath.startsWith('/'), isTrue);
    });

    test('plugin name should not be empty', () {
      final plugin = SongLearningPlugin();
      expect(plugin.name.isNotEmpty, isTrue);
    });
  });

  group('LiaisonDetector', () {
    test('detects consonant-vowel liaison', () {
      final marks = LiaisonDetector.detect('look at my sister');
      final cv = marks.where((m) => m.type == LiaisonType.consonantVowel);
      expect(cv.isNotEmpty, isTrue);
    });

    test('detects t+j liaison', () {
      final marks = LiaisonDetector.detect('I will meet you there');
      final tj = marks.where((m) => m.type == LiaisonType.tPlusJ);
      expect(tj.isNotEmpty, isTrue);
      expect(tj.first.pronunciation.contains('chyou'), isTrue);
    });

    test('detects d+j liaison', () {
      final marks = LiaisonDetector.detect('did you see that');
      final dj = marks.where((m) => m.type == LiaisonType.dPlusJ);
      expect(dj.isNotEmpty, isTrue);
    });

    test('detects weak form', () {
      final marks = LiaisonDetector.detect('I am going to leave');
      final wf = marks.where((m) => m.type == LiaisonType.weakForm);
      expect(wf.isNotEmpty, isTrue);
      expect(wf.first.pronunciation, 'gonna');
    });

    test('detects same consonant merging', () {
      final marks = LiaisonDetector.detect('good day to you');
      final sc = marks.where((m) => m.type == LiaisonType.sameConsonant);
      expect(sc.isNotEmpty, isTrue);
    });

    test('skips Chinese text', () {
      final marks = LiaisonDetector.detect('你好世界今天天气真好');
      expect(marks.isEmpty, isTrue);
    });
  });

  group('LyricsParser', () {
    test('parses LRC format', () {
      final content = '''
[00:17.00]Yesterday, all my troubles seemed so far away
[00:23.00]Now it looks as though they're here to stay
[00:28.00]Oh, I believe in yesterday
''';
      final result = LyricsParser.parse(content, 'test.lrc');
      expect(result.format, 'lrc');
      expect(result.hasTimestamps, isTrue);
      expect(result.lines.length, 3);
      expect(result.lines[0].startTime, closeTo(17.0, 0.01));
      expect(result.lines[0].endTime, closeTo(23.0, 0.01));
    });

    test('parses LRC with metadata', () {
      final content = '''
[ti:My Song]
[ar:Test Artist]
[00:05.00]First line
[00:10.00]Second line
''';
      final result = LyricsParser.parse(content, 'test.lrc');
      expect(result.songTitle, 'My Song');
      expect(result.artist, 'Test Artist');
    });

    test('parses SRT format', () {
      final content = '''
1
00:00:01,000 --> 00:00:04,000
Hello world

2
00:00:05,000 --> 00:00:08,000
This is a test
''';
      final result = LyricsParser.parse(content, 'test.srt');
      expect(result.format, 'srt');
      expect(result.hasTimestamps, isTrue);
      expect(result.lines.length, 2);
    });

    test('parses TXT format without timestamps', () {
      final content = 'Hello world\nThis is a test\nAnother line';
      final result = LyricsParser.parse(content, 'test.txt');
      expect(result.format, 'txt');
      expect(result.hasTimestamps, isFalse);
      expect(result.lines.length, 3);
      expect(result.lines[0].startTime, isNull);
    });

    test('auto-detects LRC content in .txt file (NetEase fallback)', () {
      final content = '''
[00:02.83]I found a love for me
[00:07.97]Darling just dive right in and follow my lead
[00:17.84]Well I found a girl beautiful and sweet
''';
      final result = LyricsParser.parse(content, 'song.txt');
      expect(result.format, 'lrc');
      expect(result.hasTimestamps, isTrue);
      expect(result.lines.length, 3);
      expect(result.lines[0].startTime, closeTo(2.83, 0.01));
    });
  });

  group('SongScoringService', () {
    test('perfect match gives high score', () {
      final result = SongScoringService.calculateScore(
        originalText: 'Hello world',
        recordedText: 'Hello world',
        liaisonMarks: null,
      );
      expect(result.totalScore, greaterThanOrEqualTo(70));
    });

    test('no match gives low score', () {
      final result = SongScoringService.calculateScore(
        originalText: 'Hello world',
        recordedText: 'xyz abc',
        liaisonMarks: null,
      );
      expect(result.totalScore, lessThan(50));
    });

    test('with liaison marks calculates liaison score', () {
      final result = SongScoringService.calculateScore(
        originalText: 'look at me',
        recordedText: 'look at me',
        liaisonMarks: [
          LiaisonMark(
            text: 'look at',
            startChar: 0,
            endChar: 7,
            type: LiaisonType.consonantVowel,
            pronunciation: 'loo-kat',
            detectedBy: 'rule',
          ),
        ],
      );
      expect(result.liaisonScore, isNotNull);
    });
  });
}