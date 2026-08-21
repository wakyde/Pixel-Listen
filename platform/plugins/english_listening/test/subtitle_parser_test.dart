import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/services/subtitle_parser.dart';

void main() {
  group('SubtitleParser', () {
    group('parseSrt', () {
      test('parses standard SRT format', () {
        const srtContent = '''
1
00:00:01,000 --> 00:00:03,000
Hello world

2
00:00:04,000 --> 00:00:06,500
This is a test
''';

        final cues = SubtitleParser.parseSrt(srtContent);

        expect(cues.length, 2);
        expect(cues[0].id, 'cue_0');
        expect(cues[0].start, const Duration(seconds: 1));
        expect(cues[0].end, const Duration(seconds: 3));
        expect(cues[0].text, 'Hello world');
        expect(cues[1].start, const Duration(seconds: 4));
        expect(cues[1].end, const Duration(seconds: 6, milliseconds: 500));
        expect(cues[1].text, 'This is a test');
      });

      test('parses multi-line subtitle text', () {
        const srtContent = '''
1
00:00:01,000 --> 00:00:03,000
First line
Second line
''';

        final cues = SubtitleParser.parseSrt(srtContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'First line Second line');
      });

      test('strips HTML tags from text', () {
        const srtContent = '''
1
00:00:01,000 --> 00:00:03,000
<b>Bold text</b> and <i>italic</i>
''';

        final cues = SubtitleParser.parseSrt(srtContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'Bold text and italic');
      });

      test('skips malformed time entries', () {
        const srtContent = '''
1
bad time --> 00:00:03,000
Should be skipped

2
00:00:04,000 --> 00:00:06,000
Valid entry
''';

        final cues = SubtitleParser.parseSrt(srtContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'Valid entry');
      });

      test('returns empty list for empty content', () {
        final cues = SubtitleParser.parseSrt('');
        expect(cues, isEmpty);
      });

      test('converts HTML entities', () {
        const srtContent = '''
1
00:00:01,000 --> 00:00:03,000
Hello &amp; goodbye &lt;3 &gt;0 &quot;test&quot;
''';

        final cues = SubtitleParser.parseSrt(srtContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'Hello & goodbye <3 >0 "test"');
      });
    });

    group('parseVtt', () {
      test('parses standard VTT format', () {
        const vttContent = '''
WEBVTT

1
00:00:01.000 --> 00:00:03.000
Hello world

2
00:00:04.000 --> 00:00:06.500
This is a test
''';

        final cues = SubtitleParser.parseVtt(vttContent);

        expect(cues.length, 2);
        expect(cues[0].id, 'cue_0');
        expect(cues[0].start, const Duration(seconds: 1));
        expect(cues[0].end, const Duration(seconds: 3));
        expect(cues[0].text, 'Hello world');
        expect(cues[1].text, 'This is a test');
      });

      test('skips WEBVTT header and metadata', () {
        const vttContent = '''
WEBVTT
Kind: captions
Language: en

1
00:00:01.000 --> 00:00:03.000
Test
''';

        final cues = SubtitleParser.parseVtt(vttContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'Test');
      });

      test('strips VTT cue settings', () {
        const vttContent = '''
WEBVTT

1
00:00:01.000 --> 00:00:03.000 position:50% align:middle
Test
''';

        final cues = SubtitleParser.parseVtt(vttContent);

        expect(cues.length, 1);
        expect(cues[0].text, 'Test');
      });

      test('returns empty list for content without cues', () {
        const vttContent = '''
WEBVTT
Kind: captions
''';

        final cues = SubtitleParser.parseVtt(vttContent);
        expect(cues, isEmpty);
      });
    });

    group('parseFromContent', () {
      test('routes to SRT parser for .srt', () {
        const content = '''
1
00:00:01,000 --> 00:00:03,000
Hello
''';
        final cues = SubtitleParser.parseFromContent(content, '.srt');
        expect(cues.length, 1);
        expect(cues[0].text, 'Hello');
      });

      test('routes to VTT parser for .vtt', () {
        const content = '''
WEBVTT

1
00:00:01.000 --> 00:00:03.000
Hello
''';
        final cues = SubtitleParser.parseFromContent(content, '.vtt');
        expect(cues.length, 1);
        expect(cues[0].text, 'Hello');
      });

      test('defaults to SRT for unknown extension', () {
        const content = '''
1
00:00:01,000 --> 00:00:03,000
Hello
''';
        final cues = SubtitleParser.parseFromContent(content, '.unknown');
        expect(cues.length, 1);
        expect(cues[0].text, 'Hello');
      });
    });

    group('ASS bilingual parsing', () {
      test('splits bilingual ASS into English and native', () {
        const content = '''
[Script Info]
Title: Test

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,20,&H00C8C8BF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,3,2,30,30,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:00.67,0:00:03.14,Default,,0000,0000,0000,,{\\fnArial\\fs20}你好世界{\\r}\\N{\\fnArial\\fs14}Hello World{\\r}
Dialogue: 0,0:00:04.00,0:00:06.00,Default,,0000,0000,0000,,{\\fnArial\\fs20}这是测试{\\r}\\N{\\fnArial\\fs14}This is a test{\\r}
''';

        final cues = SubtitleParser.parseAss(content);
        expect(cues.length, 2);
        expect(cues[0].text, 'Hello World');
        expect(cues[0].nativeTranslation, '你好世界');
        expect(cues[1].text, 'This is a test');
        expect(cues[1].nativeTranslation, '这是测试');
      });

      test('handles ASS with only English (no bilingual)', () {
        const content = '''
[Script Info]
Title: Test

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,Arial,20,&H00C8C8BF,&H00FFFFFF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,3,2,30,30,30,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 0,0:00:01.00,0:00:03.00,Default,,0000,0000,0000,,Hello World
''';

        final cues = SubtitleParser.parseAss(content);
        expect(cues.length, 1);
        expect(cues[0].text, 'Hello World');
        expect(cues[0].nativeTranslation, isNull);
      });
    });
  });
}