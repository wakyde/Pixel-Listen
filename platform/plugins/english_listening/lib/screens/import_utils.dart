import 'package:flutter/material.dart';

import '../constants.dart';
import '../models/subtitle.dart';

IconData categoryIcon(String iconName) {
  switch (iconName) {
    case IconName.folder:
      return Icons.folder;
    case IconName.smartDisplay:
      return Icons.smart_display;
    case IconName.tv:
      return Icons.tv;
    case IconName.musicNote:
      return Icons.music_note;
    case IconName.language:
      return Icons.language;
    default:
      return Icons.videocam;
  }
}

String formatDurationSeconds(int totalSeconds) {
  final m = totalSeconds ~/ 60;
  final s = totalSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatRelativeTime(DateTime dateTime) {
  final diff = DateTime.now().difference(dateTime);
  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
  if (diff.inHours < 24) return '${diff.inHours}小时前';
  if (diff.inDays < 7) return '${diff.inDays}天前';
  return '${dateTime.month}/${dateTime.day}';
}

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

double cjkRatio(String text) {
  if (text.isEmpty) return 0;
  int cjk = 0;
  for (int i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    if ((c >= 0x4E00 && c <= 0x9FFF) ||
        (c >= 0x3400 && c <= 0x4DBF) ||
        (c >= 0x20000 && c <= 0x2A6DF) ||
        (c >= 0xF900 && c <= 0xFAFF) ||
        (c >= 0x3000 && c <= 0x303F) ||
        (c >= 0xFF00 && c <= 0xFFEF)) {
      cjk++;
    }
  }
  return cjk / text.length;
}

List<SubtitleCue> mergeBilingualCues(List<List<SubtitleCue>> groups) {
  if (groups.isEmpty) return [];
  if (groups.length == 1) return groups[0];

  List<SubtitleCue> enCues;
  List<SubtitleCue> nativeCues;

  final cjk0 = cjkRatio(groups[0].map((c) => c.text).join(' '));
  final cjk1 = cjkRatio(groups[1].map((c) => c.text).join(' '));

  if (cjk0 <= cjk1) {
    enCues = groups[0];
    nativeCues = groups[1];
  } else {
    enCues = groups[1];
    nativeCues = groups[0];
  }

  final merged = <SubtitleCue>[];
  final maxLen =
      enCues.length > nativeCues.length ? enCues.length : nativeCues.length;

  for (int i = 0; i < maxLen; i++) {
    final en = i < enCues.length ? enCues[i] : null;
    final native = i < nativeCues.length ? nativeCues[i] : null;

    if (en == null && native == null) continue;

    merged.add(SubtitleCue(
      id: 'cue_$i',
      start: en?.start ?? native!.start,
      end: en?.end ?? native!.end,
      text: en?.text ?? '',
      nativeTranslation: native?.text,
    ));
  }

  return merged;
}

String encodeCuesToAss(List<SubtitleCue> cues) {
  final buf = StringBuffer();
  buf.writeln('[Script Info]');
  buf.writeln('Title: Merged Bilingual');
  buf.writeln('ScriptType: v4.00+');
  buf.writeln();
  buf.writeln('[V4+ Styles]');
  buf.writeln(
      'Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
  buf.writeln(
      'Style: Default,Arial,20,&H00FFFFFF,&H000000FF,&H00000000,&H00000000,0,0,0,0,100,100,0,0,1,2,2,2,10,10,10,1');
  buf.writeln();
  buf.writeln('[Events]');
  buf.writeln(
      'Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

  for (final cue in cues) {
    final start = formatAssTime(cue.start);
    final end = formatAssTime(cue.end);
    final text =
        cue.nativeTranslation != null && cue.nativeTranslation!.isNotEmpty
            ? '${cue.text}\\N${cue.nativeTranslation}'
            : cue.text;
    buf.writeln('Dialogue: 0,$start,$end,Default,,0,0,0,,$text');
  }

  return buf.toString();
}

String formatAssTime(Duration d) {
  final h = d.inHours.toString().padLeft(1, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final cs = (d.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$h:$m:$s.$cs';
}