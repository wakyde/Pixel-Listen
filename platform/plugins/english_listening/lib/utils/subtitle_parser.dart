import '../models/subtitle.dart';

class SubtitleParser {
  static List<SubtitleCue> parse(String content) {
    final trimmed = content.trim();
    if (trimmed.contains('-->')) {
      return _parseSrt(trimmed);
    } else if (trimmed.startsWith('WEBVTT')) {
      return _parseVtt(trimmed);
    }
    return [];
  }

  static List<SubtitleCue> _parseSrt(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      final timeMatch = _timePattern.firstMatch(lines[1]);
      if (timeMatch == null) continue;

      final start = _parseTimestamp(timeMatch.group(1)!);
      final end = _parseTimestamp(timeMatch.group(2)!);
      final text = lines.skip(2).join('\n').trim();

      if (text.isEmpty) continue;

      cues.add(SubtitleCue(
        id: cues.length.toString(),
        start: start,
        end: end,
        text: text,
      ));
    }

    return cues;
  }

  static List<SubtitleCue> _parseVtt(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');
    int i = 0;

    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    for (; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.contains('-->')) {
        final timeMatch = _timePattern.firstMatch(line);
        if (timeMatch == null) continue;

        final start = _parseTimestamp(timeMatch.group(1)!);
        final end = _parseTimestamp(timeMatch.group(2)!);

        final textLines = <String>[];
        i++;
        while (i < lines.length && lines[i].trim().isNotEmpty) {
          textLines.add(lines[i].trim());
          i++;
        }

        final text = textLines.join('\n').trim();
        if (text.isEmpty) continue;

        cues.add(SubtitleCue(
          id: cues.length.toString(),
          start: start,
          end: end,
          text: text,
        ));
      }
    }

    return cues;
  }

  static final _timePattern = RegExp(
    r'(\d{2}:\d{2}:\d{2}[,\.]\d{3})\s*-->\s*(\d{2}:\d{2}:\d{2}[,\.]\d{3})',
  );

  static Duration _parseTimestamp(String timestamp) {
    final cleaned = timestamp.replaceAll(',', '.');
    final parts = cleaned.split(':');
    final seconds = parts[2].split('.');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
      seconds: int.parse(seconds[0]),
      milliseconds: int.parse(seconds[1]),
    );
  }
}