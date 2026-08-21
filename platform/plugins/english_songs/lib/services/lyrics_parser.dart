import 'dart:math';

import '../models/song_models.dart';

class LyricsParser {
  LyricsParser._();

  static String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(999999);
    return '${now.toRadixString(36)}-${rand.toRadixString(36)}';
  }

  static LyricsParseResult parse(String content, String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.lrc')) {
      return _parseLrc(content, fileName);
    } else if (ext.endsWith('.srt')) {
      return _parseSrt(content, fileName);
    } else if (ext.endsWith('.vtt')) {
      return _parseVtt(content, fileName);
    } else if (ext.endsWith('.txt')) {
      if (_looksLikeLrc(content)) {
        return _parseLrc(content, fileName);
      }
      return _parseTxt(content, fileName);
    } else {
      if (_looksLikeLrc(content)) {
        return _parseLrc(content, fileName);
      }
      return LyricsParseResult(
        lines: [],
        format: 'unknown',
        hasTimestamps: false,
        parseErrors: ['Unsupported file format: $ext'],
        songTitle: fileName,
        artist: null,
      );
    }
  }

  static bool _looksLikeLrc(String content) {
    final firstLines = content.split('\n').take(5).join('\n');
    return RegExp(r'\[\d{2}:\d{2}[.,]\d{2,3}\]').hasMatch(firstLines);
  }

  static LyricsParseResult _parseLrc(String content, String fileName) {
    final lines = <SongLyricLine>[];
    final parseErrors = <String>[];
    String? songTitle;
    String? artist;
    bool hasEnhancedTags = false;
    final now = DateTime.now();

    final rawLines = content.split('\n');
    for (final raw in rawLines) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;

      final tiMatch = RegExp(r'\[ti:(.*)\]', caseSensitive: false).firstMatch(trimmed);
      if (tiMatch != null) {
        songTitle = tiMatch.group(1)!.trim();
        continue;
      }

      final arMatch = RegExp(r'\[ar:(.*)\]', caseSensitive: false).firstMatch(trimmed);
      if (arMatch != null) {
        artist = arMatch.group(1)!.trim();
        continue;
      }

      if (trimmed.contains('<') && trimmed.contains('>')) {
        hasEnhancedTags = true;
      }

      final timeMatches = RegExp(r'\[(\d{2}):(\d{2})[.,](\d{2,3})\]').allMatches(trimmed).toList();
      if (timeMatches.isEmpty) continue;

      final textOnly = trimmed.replaceAll(RegExp(r'\[\d{2}:\d{2}[.,]\d{2,3}\]'), '').trim();
      if (textOnly.isEmpty) continue;

      List<WordTiming>? wordTimings;
      if (hasEnhancedTags) {
        final wordMatches =
            RegExp(r'<(\d{2}):(\d{2})[.,](\d{2,3})>([^<]+)').allMatches(trimmed).toList();
        if (wordMatches.isNotEmpty) {
          wordTimings = wordMatches.map((m) {
            final minutes = int.parse(m.group(1)!);
            final seconds = int.parse(m.group(2)!);
            final frac = m.group(3)!;
            final ms = frac.length == 2 ? int.parse(frac) * 10 : int.parse(frac);
            final time = minutes * 60.0 + seconds + ms / 1000.0;
            return WordTiming(word: m.group(4)!.trim(), time: time);
          }).toList();
        }
      }

      for (final match in timeMatches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final frac = match.group(3)!;
        final ms = frac.length == 2 ? int.parse(frac) * 10 : int.parse(frac);
        final startTime = minutes * 60.0 + seconds + ms / 1000.0;

        lines.add(SongLyricLine(
          id: _uuid(),
          songId: '',
          lineIndex: lines.length,
          startTime: startTime,
          endTime: null,
          text: textOnly,
          wordTimings: wordTimings,
          createdAt: now,
        ));
      }
    }

    lines.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    for (int i = 0; i < lines.length; i++) {
      final endTime = i < lines.length - 1
          ? lines[i + 1].startTime
          : (lines[i].startTime ?? 0) + 5.0;
      lines[i] = SongLyricLine(
        id: lines[i].id,
        songId: lines[i].songId,
        lineIndex: i,
        startTime: lines[i].startTime,
        endTime: endTime,
        text: lines[i].text,
        wordTimings: lines[i].wordTimings,
        createdAt: lines[i].createdAt,
      );
    }

    return LyricsParseResult(
      lines: lines,
      format: hasEnhancedTags ? 'enhanced_lrc' : 'lrc',
      hasTimestamps: true,
      parseErrors: parseErrors,
      songTitle: songTitle ?? fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      artist: artist,
    );
  }

  static LyricsParseResult _parseSrt(String content, String fileName) {
    final lines = <SongLyricLine>[];
    final parseErrors = <String>[];
    final now = DateTime.now();
    final blocks = content.trim().split(RegExp(r'\n\s*\n'));

    for (final block in blocks) {
      final blockLines = block.trim().split('\n');
      if (blockLines.length < 2) continue;

      final timeLine = blockLines.firstWhere(
        (l) => l.contains('-->'),
        orElse: () => '',
      );
      if (timeLine.isEmpty) continue;

      final timeMatch = RegExp(
        r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})',
      ).firstMatch(timeLine);
      if (timeMatch == null) {
        parseErrors.add('Invalid timestamp in block: ${blockLines.first}');
        continue;
      }

      final startTime = int.parse(timeMatch.group(1)!) * 3600.0 +
          int.parse(timeMatch.group(2)!) * 60.0 +
          int.parse(timeMatch.group(3)!) +
          int.parse(timeMatch.group(4)!) / 1000.0;
      final endTime = int.parse(timeMatch.group(5)!) * 3600.0 +
          int.parse(timeMatch.group(6)!) * 60.0 +
          int.parse(timeMatch.group(7)!) +
          int.parse(timeMatch.group(8)!) / 1000.0;

      final textLines = blockLines
          .where((l) => l != timeLine && !RegExp(r'^\d+$').hasMatch(l.trim()))
          .toList();
      final text = textLines.join(' ').trim();

      if (text.isNotEmpty) {
        lines.add(SongLyricLine(
          id: _uuid(),
          songId: '',
          lineIndex: lines.length,
          startTime: startTime,
          endTime: endTime,
          text: _cleanText(text),
          createdAt: now,
        ));
      }
    }

    lines.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    return LyricsParseResult(
      lines: lines,
      format: 'srt',
      hasTimestamps: true,
      parseErrors: parseErrors,
      songTitle: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      artist: null,
    );
  }

  static LyricsParseResult _parseVtt(String content, String fileName) {
    final lines = <SongLyricLine>[];
    final parseErrors = <String>[];
    final now = DateTime.now();
    final rawLines = content.split('\n');

    final blocks = <String>[];
    final currentBlock = <String>[];

    for (final line in rawLines) {
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
      if (block.startsWith('WEBVTT') ||
          block.startsWith('Kind:') ||
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

      if (timeMatch == null) {
        parseErrors.add('Invalid VTT timestamp: $timeLine');
        continue;
      }

      final startTime = int.parse(timeMatch.group(1)!) * 3600.0 +
          int.parse(timeMatch.group(2)!) * 60.0 +
          int.parse(timeMatch.group(3)!) +
          int.parse(timeMatch.group(4)!) / 1000.0;
      final endTime = int.parse(timeMatch.group(5)!) * 3600.0 +
          int.parse(timeMatch.group(6)!) * 60.0 +
          int.parse(timeMatch.group(7)!) +
          int.parse(timeMatch.group(8)!) / 1000.0;

      final textLines = blockLines
          .where((l) =>
              l != timeLine &&
              !l.trim().startsWith('WEBVTT') &&
              !l.trim().startsWith('NOTE') &&
              !l.trim().startsWith('Kind:') &&
              !l.trim().startsWith('Language:') &&
              !RegExp(r'^\d+$').hasMatch(l.trim()))
          .toList();
      final text = textLines.join(' ').trim();

      if (text.isNotEmpty) {
        lines.add(SongLyricLine(
          id: _uuid(),
          songId: '',
          lineIndex: lines.length,
          startTime: startTime,
          endTime: endTime,
          text: _cleanText(text),
          createdAt: now,
        ));
      }
    }

    lines.sort((a, b) => (a.startTime ?? 0).compareTo(b.startTime ?? 0));

    return LyricsParseResult(
      lines: lines,
      format: 'vtt',
      hasTimestamps: true,
      parseErrors: parseErrors,
      songTitle: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      artist: null,
    );
  }

  static LyricsParseResult _parseTxt(String content, String fileName) {
    final lines = <SongLyricLine>[];
    final now = DateTime.now();
    final paragraphs = content.trim().split(RegExp(r'\n\s*\n'));

    for (final para in paragraphs) {
      final paraLines = para.trim().split('\n');
      for (final line in paraLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final englishOnly = RegExp(r"^[a-zA-Z0-9\s',.!?;:()\-" '"' r'\u2018\u2019\u201c\u201d]' r"+$");
        if (!englishOnly.hasMatch(trimmed)) {
          final cjkCount = RegExp(r'[\u4e00-\u9fff\u3400-\u4dbf]').allMatches(trimmed).length;
          if (cjkCount > trimmed.length * 0.3) continue;
        }

        lines.add(SongLyricLine(
          id: _uuid(),
          songId: '',
          lineIndex: lines.length,
          startTime: null,
          endTime: null,
          text: _cleanText(trimmed),
          createdAt: now,
        ));
      }
    }

    return LyricsParseResult(
      lines: lines,
      format: 'txt',
      hasTimestamps: false,
      parseErrors: [],
      songTitle: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''),
      artist: null,
    );
  }

  static String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .trim();
  }
}

class LyricsParseResult {
  final List<SongLyricLine> lines;
  final String format;
  final bool hasTimestamps;
  final List<String> parseErrors;
  final String songTitle;
  final String? artist;

  const LyricsParseResult({
    required this.lines,
    required this.format,
    required this.hasTimestamps,
    required this.parseErrors,
    required this.songTitle,
    this.artist,
  });
}