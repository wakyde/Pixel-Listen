import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/screens/import_utils.dart';
import 'package:english_listening/models/subtitle.dart';

void main() {
  group('categoryIcon', () {
    test('returns correct icon for folder', () {
      expect(categoryIcon('folder'), isNotNull);
    });

    test('returns correct icon for smart_display', () {
      expect(categoryIcon('smart_display'), isNotNull);
    });

    test('returns default icon for unknown name', () {
      expect(categoryIcon('unknown'), isNotNull);
    });
  });

  group('formatDurationSeconds', () {
    test('formats zero seconds', () {
      expect(formatDurationSeconds(0), '00:00');
    });

    test('formats single digit seconds', () {
      expect(formatDurationSeconds(5), '00:05');
    });

    test('formats minutes and seconds', () {
      expect(formatDurationSeconds(65), '01:05');
    });

    test('formats two digit minutes', () {
      expect(formatDurationSeconds(600), '10:00');
    });
  });

  group('formatRelativeTime', () {
    test('returns 刚刚 for recent time', () {
      final now = DateTime.now();
      expect(formatRelativeTime(now), '刚刚');
    });

    test('returns minutes ago', () {
      final fiveMinAgo = DateTime.now().subtract(const Duration(minutes: 5));
      expect(formatRelativeTime(fiveMinAgo), '5分钟前');
    });

    test('returns hours ago', () {
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      expect(formatRelativeTime(twoHoursAgo), '2小时前');
    });

    test('returns days ago', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      expect(formatRelativeTime(threeDaysAgo), '3天前');
    });

    test('returns date for older entries', () {
      final tenDaysAgo = DateTime.now().subtract(const Duration(days: 10));
      final result = formatRelativeTime(tenDaysAgo);
      expect(result, contains('/'));
    });
  });

  group('formatDuration', () {
    test('formats zero duration', () {
      expect(formatDuration(Duration.zero), '00:00');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(const Duration(minutes: 2, seconds: 30)), '02:30');
    });

    test('formats hours', () {
      expect(
        formatDuration(const Duration(hours: 1, minutes: 5, seconds: 30)),
        '01:05:30',
      );
    });
  });

  group('cjkRatio', () {
    test('returns 0 for empty string', () {
      expect(cjkRatio(''), 0);
    });

    test('returns 0 for pure English text', () {
      expect(cjkRatio('Hello World'), 0);
    });

    test('returns 1 for pure Chinese text', () {
      expect(cjkRatio('你好世界'), 1.0);
    });

    test('returns ratio for mixed text', () {
      final ratio = cjkRatio('你好 World');
      expect(ratio, greaterThan(0));
      expect(ratio, lessThan(1));
    });
  });

  group('mergeBilingualCues', () {
    test('returns empty list for empty input', () {
      expect(mergeBilingualCues([]), isEmpty);
    });

    test('returns single group unchanged', () {
      final cues = [
        SubtitleCue(
          id: '1',
          start: Duration.zero,
          end: const Duration(seconds: 1),
          text: 'Hello',
        ),
      ];
      expect(mergeBilingualCues([cues]), cues);
    });

    test('merges English and Chinese cues', () {
      final enCues = [
        SubtitleCue(
          id: 'en1',
          start: Duration.zero,
          end: const Duration(seconds: 1),
          text: 'Hello',
        ),
      ];
      final zhCues = [
        SubtitleCue(
          id: 'zh1',
          start: Duration.zero,
          end: const Duration(seconds: 1),
          text: '你好',
        ),
      ];
      final merged = mergeBilingualCues([enCues, zhCues]);
      expect(merged.length, 1);
      expect(merged[0].text, 'Hello');
      expect(merged[0].nativeTranslation, '你好');
    });
  });

  group('encodeCuesToAss', () {
    test('returns valid ASS format', () {
      final cues = [
        SubtitleCue(
          id: '1',
          start: Duration.zero,
          end: const Duration(seconds: 2),
          text: 'Hello World',
          nativeTranslation: '你好世界',
        ),
      ];
      final ass = encodeCuesToAss(cues);
      expect(ass, contains('[Script Info]'));
      expect(ass, contains('[V4+ Styles]'));
      expect(ass, contains('[Events]'));
      expect(ass, contains('Hello World'));
      expect(ass, contains('你好世界'));
    });

    test('handles cues without native translation', () {
      final cues = [
        SubtitleCue(
          id: '1',
          start: Duration.zero,
          end: const Duration(seconds: 2),
          text: 'Hello',
        ),
      ];
      final ass = encodeCuesToAss(cues);
      expect(ass, contains('Hello'));
      expect(ass, isNot(contains('\\N')));
    });
  });

  group('formatAssTime', () {
    test('formats zero duration', () {
      expect(formatAssTime(Duration.zero), '0:00:00.00');
    });

    test('formats with milliseconds', () {
      expect(
        formatAssTime(const Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 670)),
        '1:23:45.67',
      );
    });
  });
}