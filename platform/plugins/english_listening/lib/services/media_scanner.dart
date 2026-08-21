import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/subtitle.dart';
import 'subtitle_parser.dart';

class MediaEpisode {
  final String path;
  final String name;
  final String? subtitlePath;
  final String? subtitleName;
  final int index;

  const MediaEpisode({
    required this.path,
    required this.name,
    this.subtitlePath,
    this.subtitleName,
    required this.index,
  });
}

class MediaFolder {
  final String folderPath;
  final String folderName;
  final List<MediaEpisode> episodes;

  const MediaFolder({
    required this.folderPath,
    required this.folderName,
    required this.episodes,
  });

  bool get hasMultipleEpisodes => episodes.length > 1;
}

class MediaScanner {
  static const _videoExtensions = {
    '.mp4', '.mkv', '.webm', '.mov', '.avi',
    '.mp3', '.m4a', '.wav', '.ogg', '.flac', '.aac',
  };

  static const _subtitleExtensions = {
    '.srt', '.vtt', '.ass', '.ssa',
  };

  static MediaFolder? scanFolder(String mediaPath) {
    if (kIsWeb) return null;

    try {
      final file = File(mediaPath);
      if (!file.existsSync()) return null;

      final dir = file.parent;
      final folderName = dir.path.split('/').last;

      final allFiles = dir.listSync().whereType<File>().toList();

      final mediaFiles = allFiles
          .where((f) {
            final ext = f.path.toLowerCase();
            return _videoExtensions.any((e) => ext.endsWith(e));
          })
          .toList();

      if (mediaFiles.isEmpty) return null;

      final subtitleFiles = allFiles
          .where((f) {
            final ext = f.path.toLowerCase();
            return _subtitleExtensions.any((e) => ext.endsWith(e));
          })
          .toList();

      final episodes = <MediaEpisode>[];
      for (int i = 0; i < mediaFiles.length; i++) {
        final media = mediaFiles[i];
        final baseName = _baseName(media.path);

        final matchedSub = subtitleFiles.firstWhere(
          (s) {
            final subBase = _baseName(s.path);
            return subBase.startsWith(baseName) || baseName.startsWith(subBase);
          },
          orElse: () => _fuzzyMatchSubtitle(media.path, subtitleFiles),
        );

        File? actualSubFile;
        if (matchedSub.path != media.path) {
          actualSubFile = matchedSub;
        }

        episodes.add(MediaEpisode(
          path: media.path,
          name: media.path.split('/').last,
          subtitlePath: actualSubFile?.path,
          subtitleName: actualSubFile?.path.split('/').last,
          index: i,
        ));
      }

      episodes.sort((a, b) => _naturalSortCompare(a.name, b.name));

      return MediaFolder(
        folderPath: dir.path,
        folderName: folderName,
        episodes: episodes,
      );
    } catch (e, st) {
      debugPrint('[MediaScanner] scanFolder failed: $e\n$st');
      return null;
    }
  }

  static String _baseName(String path) {
    final name = path.split('/').last;
    final lastDot = name.lastIndexOf('.');
    return lastDot > 0 ? name.substring(0, lastDot) : name;
  }

  static File _fuzzyMatchSubtitle(String mediaPath, List<File> subtitleFiles) {
    final mediaBase = _baseName(mediaPath).toLowerCase();

    final candidates = subtitleFiles
        .where((s) => _baseName(s.path).toLowerCase().contains(mediaBase))
        .toList();

    if (candidates.isNotEmpty) return candidates.first;

    final mediaNumber = _extractEpisodeNumber(mediaBase);
    if (mediaNumber != null) {
      for (final sub in subtitleFiles) {
        final subBase = _baseName(sub.path).toLowerCase();
        final subNumber = _extractEpisodeNumber(subBase);
        if (subNumber == mediaNumber) return sub;
      }
    }

    return subtitleFiles.isEmpty ? File(mediaPath) : subtitleFiles.first;
  }

  static int? _extractEpisodeNumber(String name) {
    final patterns = [
      RegExp(r'[eE][pP]?\s*(\d+)'),
      RegExp(r'第\s*(\d+)\s*[集话]'),
      RegExp(r'[_-](\d{2,})[_-]'),
      RegExp(r'(\d+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(name);
      if (match != null) {
        return int.tryParse(match.group(1)!);
      }
    }
    return null;
  }

  static int _naturalSortCompare(String a, String b) {
    final aNum = _extractEpisodeNumber(a) ?? 0;
    final bNum = _extractEpisodeNumber(b) ?? 0;
    if (aNum != bNum) return aNum.compareTo(bNum);
    return a.compareTo(b);
  }

  static Future<String?> loadSubtitleContent(String subtitlePath) async {
    try {
      final file = File(subtitlePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e, st) {
      debugPrint('[MediaScanner] loadSubtitleContent failed: $e\n$st');
    }
    return null;
  }

  static List<SubtitleCue> parseSubtitleForEpisode(String content, String fileName) {
    return SubtitleParser.parseFromContent(
      content,
      fileName.contains('.') ? fileName.substring(fileName.lastIndexOf('.')) : '.srt',
    );
  }
}