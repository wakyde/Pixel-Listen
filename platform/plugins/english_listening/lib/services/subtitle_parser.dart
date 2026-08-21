import '../models/subtitle.dart';

class SubtitleParser {
  SubtitleParser._();

  static List<SubtitleCue> parseSrt(String content) {
    final cues = <SubtitleCue>[];
    final blocks = content.trim().split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      final timeLine = lines.firstWhere(
        (l) => l.contains('-->'),
        orElse: () => '',
      );
      if (timeLine.isEmpty) continue;

      final timeMatch = RegExp(
        r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})',
      ).firstMatch(timeLine);
      if (timeMatch == null) continue;

      final start = Duration(
        hours: int.parse(timeMatch.group(1)!),
        minutes: int.parse(timeMatch.group(2)!),
        seconds: int.parse(timeMatch.group(3)!),
        milliseconds: int.parse(timeMatch.group(4)!),
      );
      final end = Duration(
        hours: int.parse(timeMatch.group(5)!),
        minutes: int.parse(timeMatch.group(6)!),
        seconds: int.parse(timeMatch.group(7)!),
        milliseconds: int.parse(timeMatch.group(8)!),
      );

      final textLines = lines
          .where((l) => l != timeLine && !RegExp(r'^\d+$').hasMatch(l.trim()))
          .toList();

      if (textLines.isNotEmpty) {
        final (english, native) = _splitBilingualLines(textLines);
        cues.add(SubtitleCue(
          id: 'cue_${cues.length}',
          start: start,
          end: end,
          text: _cleanText(english),
          nativeTranslation: native != null ? _cleanText(native) : null,
        ));
      }
    }

    return _postProcess(cues);
  }

  static List<SubtitleCue> parseVtt(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');

    final blocks = <String>[];
    final currentBlock = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        if (currentBlock.isNotEmpty) {
          blocks.add(currentBlock.join('\n'));
          currentBlock.clear();
        }
      } else {
        currentBlock.add(line);
      }
    }
    if (currentBlock.isNotEmpty) {
      blocks.add(currentBlock.join('\n'));
    }

    for (final block in blocks) {
      if (block.startsWith('WEBVTT') || block.startsWith('Kind:') ||
          block.startsWith('Language:')) {
        continue;
      }

      final blockLines = block.split('\n');
      final timeLine = blockLines.firstWhere(
        (l) => l.contains('-->'),
        orElse: () => '',
      );
      if (timeLine.isEmpty) continue;

      String cleanTimeLine = timeLine.trim();
      if (cleanTimeLine.contains('position:') ||
          cleanTimeLine.contains('align:') ||
          cleanTimeLine.contains('line:')) {
        cleanTimeLine = cleanTimeLine.split(RegExp(r'\s+(?=[a-z]+:)')).first;
      }

      final timeMatch = RegExp(
        r'(\d{2}):(\d{2}):(\d{2})[.,](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[.,](\d{3})',
      ).firstMatch(cleanTimeLine);

      if (timeMatch == null) continue;

      final start = Duration(
        hours: int.parse(timeMatch.group(1)!),
        minutes: int.parse(timeMatch.group(2)!),
        seconds: int.parse(timeMatch.group(3)!),
        milliseconds: int.parse(timeMatch.group(4)!),
      );
      final end = Duration(
        hours: int.parse(timeMatch.group(5)!),
        minutes: int.parse(timeMatch.group(6)!),
        seconds: int.parse(timeMatch.group(7)!),
        milliseconds: int.parse(timeMatch.group(8)!),
      );

      final textLines = blockLines
          .where((l) =>
              l != timeLine &&
              !l.trim().startsWith('WEBVTT') &&
              !l.trim().startsWith('NOTE') &&
              !l.trim().startsWith('Kind:') &&
              !l.trim().startsWith('Language:') &&
              !RegExp(r'^\d+$').hasMatch(l.trim()))
          .toList();

      if (textLines.isNotEmpty) {
        final (english, native) = _splitBilingualLines(textLines);
        cues.add(SubtitleCue(
          id: 'cue_${cues.length}',
          start: start,
          end: end,
          text: _cleanText(english),
          nativeTranslation: native != null ? _cleanText(native) : null,
        ));
      }
    }

    return _postProcess(cues);
  }

  static List<SubtitleCue> parseAss(String content) {
    final cues = <SubtitleCue>[];
    final lines = content.split('\n');

    bool inEvents = false;
    int startIndex = -1;
    int endIndex = -1;
    int textIndex = -1;
    List<String> formatFields = [];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('[Events]')) {
        inEvents = true;
        continue;
      }

      if (!inEvents) continue;

      if (trimmed.toLowerCase().startsWith('format:')) {
        formatFields = trimmed
            .substring(7)
            .split(',')
            .map((f) => f.trim().toLowerCase())
            .toList();
        startIndex = formatFields.indexOf('start');
        endIndex = formatFields.indexOf('end');
        textIndex = formatFields.indexOf('text');
        continue;
      }

      if (!trimmed.toLowerCase().startsWith('dialogue:')) continue;

      if (startIndex < 0 || endIndex < 0 || textIndex < 0) continue;

      final parts = _splitAssDialogue(trimmed);
      if (parts.length <= textIndex) continue;

      final start = _parseAssTime(parts[startIndex]);
      final end = _parseAssTime(parts[endIndex]);
      final rawText = parts.sublist(textIndex).join(',').trim();

      if (start == null || end == null || rawText.isEmpty) continue;
      if (end <= start) continue;

      final noTags = _stripAssTags(rawText);
      final (english, native) = _splitBilingual(noTags);
      final cleanEnglish = _cleanText(english);
      final cleanNative = native != null ? _cleanText(native) : null;

      cues.add(SubtitleCue(
        id: 'cue_${cues.length}',
        start: start,
        end: end,
        text: cleanEnglish,
        nativeTranslation: cleanNative,
      ));
    }

    return _postProcess(cues);
  }

  static String _stripAssTags(String text) {
    return text
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .replaceAll('\r', '')
        .trim();
  }

  static (String, String?) _splitBilingualLines(List<String> lines) {
    final enLines = <String>[];
    final nativeLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cjkRatio = _cjkCharRatio(trimmed);
      if (cjkRatio >= 0.3) {
        nativeLines.add(trimmed);
      } else {
        enLines.add(trimmed);
      }
    }

    final english = enLines.isNotEmpty ? enLines.join(' ') : lines.join(' ').trim();
    final native = nativeLines.isNotEmpty ? nativeLines.join(' ') : null;
    return (english, native);
  }

  static (String, String?) _splitBilingual(String text) {
    final lines = text.split('\\N');
    if (lines.length == 1) return (text.trim(), null);

    final enLines = <String>[];
    String? nativeLine;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cjkRatio = _cjkCharRatio(trimmed);
      if (cjkRatio >= 0.3) {
        nativeLine = trimmed;
      } else {
        enLines.add(trimmed);
      }
    }

    final english = enLines.isNotEmpty ? enLines.join(' ') : text.trim();
    return (english, nativeLine);
  }

  static double _cjkCharRatio(String text) {
    if (text.isEmpty) return 0;
    int cjk = 0;
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if ((code >= 0x4E00 && code <= 0x9FFF) ||
          (code >= 0x3400 && code <= 0x4DBF) ||
          (code >= 0x3000 && code <= 0x303F) ||
          (code >= 0xFF00 && code <= 0xFFEF) ||
          (code >= 0x3040 && code <= 0x309F) ||
          (code >= 0x30A0 && code <= 0x30FF) ||
          (code >= 0xAC00 && code <= 0xD7AF)) {
        cjk++;
      }
    }
    return cjk / text.length;
  }

  static List<String> _splitAssDialogue(String line) {
    final prefixEnd = line.indexOf(':');
    if (prefixEnd < 0) return [];

    final content = line.substring(prefixEnd + 1).trim();
    final parts = <String>[];
    final buffer = StringBuffer();
    bool inBrace = false;

    for (int i = 0; i < content.length; i++) {
      final char = content[i];
      if (char == '{') {
        inBrace = true;
        buffer.write(char);
      } else if (char == '}') {
        inBrace = false;
        buffer.write(char);
      } else if (char == ',' && !inBrace) {
        parts.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    parts.add(buffer.toString().trim());
    return parts;
  }

  static Duration? _parseAssTime(String time) {
    final match = RegExp(
      r'(\d+):(\d{2}):(\d{2})[.,](\d{2})',
    ).firstMatch(time.trim());
    if (match == null) return null;

    final hours = int.parse(match.group(1)!);
    final minutes = int.parse(match.group(2)!);
    final seconds = int.parse(match.group(3)!);
    final centiseconds = int.parse(match.group(4)!);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );
  }

  static List<SubtitleCue> parseFromContent(String content, String extension) {
    switch (extension.toLowerCase()) {
      case '.srt':
        return parseSrt(content);
      case '.vtt':
        return parseVtt(content);
      case '.ass':
      case '.ssa':
        return parseAss(content);
      default:
        return _parseAuto(content);
    }
  }

  static List<SubtitleCue> _parseAuto(String content) {
    final trimmed = content.trim();
    if (trimmed.startsWith('[Script Info]')) {
      return parseAss(trimmed);
    }
    if (trimmed.startsWith('WEBVTT')) {
      return parseVtt(trimmed);
    }
    return parseSrt(trimmed);
  }

  static List<SubtitleCue> _postProcess(List<SubtitleCue> cues) {
    if (cues.isEmpty) return cues;

    cues.sort((a, b) => a.start.compareTo(b.start));

    cues = _removeShortDuplicates(cues);
    cues = _mergeProgressiveCues(cues);

    final fixed = <SubtitleCue>[];
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      if (i > 0) {
        final prev = fixed.last;
        if (cue.start < prev.end) {
          final adjustedStart = prev.end + const Duration(milliseconds: 10);
          if (adjustedStart < cue.end) {
            fixed.add(SubtitleCue(
              id: cue.id,
              start: adjustedStart,
              end: cue.end,
              text: cue.text,
              nativeTranslation: cue.nativeTranslation,
              cefrTokens: cue.cefrTokens,
              collocationTokens: cue.collocationTokens,
            ));
            continue;
          }
        }
      }
      fixed.add(cue);
    }

    return fixed;
  }

  static List<SubtitleCue> _removeShortDuplicates(List<SubtitleCue> cues) {
    if (cues.length < 2) return cues;

    final result = <SubtitleCue>[];
    for (int i = 0; i < cues.length; i++) {
      final cue = cues[i];
      final duration = cue.end - cue.start;

      if (duration < const Duration(milliseconds: 100) && cue.text.trim().isEmpty) {
        continue;
      }

      if (duration < const Duration(milliseconds: 100) && i > 0) {
        final prev = cues[i - 1];
        if (_textsAreSimilar(cue.text, prev.text)) {
          continue;
        }
      }

      result.add(cue);
    }
    return result;
  }

  static List<SubtitleCue> _mergeProgressiveCues(List<SubtitleCue> cues) {
    if (cues.length < 2) return cues;

    final merged = <SubtitleCue>[];
    merged.add(cues[0]);

    for (int i = 1; i < cues.length; i++) {
      final prev = merged.last;
      final curr = cues[i];

      final prevText = prev.text.trim();
      final currText = curr.text.trim();

      if (currText.contains(prevText) && currText.length > prevText.length && prevText.length > 3) {
        final newText = currText;
        merged[merged.length - 1] = SubtitleCue(
          id: prev.id,
          start: prev.start,
          end: curr.end,
          text: newText,
          nativeTranslation: prev.nativeTranslation ?? curr.nativeTranslation,
          cefrTokens: curr.cefrTokens ?? prev.cefrTokens,
          collocationTokens: curr.collocationTokens ?? prev.collocationTokens,
        );
      } else {
        merged.add(curr);
      }
    }

    return merged;
  }

  static bool _textsAreSimilar(String a, String b) {
    final cleanA = a.trim().toLowerCase();
    final cleanB = b.trim().toLowerCase();
    if (cleanA == cleanB) return true;
    if (cleanA.isEmpty || cleanB.isEmpty) return false;
    final shorter = cleanA.length < cleanB.length ? cleanA : cleanB;
    final longer = cleanA.length < cleanB.length ? cleanB : cleanA;
    return longer.contains(shorter) && shorter.length > longer.length * 0.8;
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\\N', ' ')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}