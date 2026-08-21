import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/subtitle.dart';
import 'file_picker_service.dart';
import 'subtitle_parser.dart';

class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<FilePickResult?> pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'mp4', 'mkv', 'webm', 'mov', 'avi',
        'mp3', 'm4a', 'wav', 'ogg', 'flac', 'aac',
      ],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      return FilePickResult(
        path: file.path ?? '',
        name: file.name,
      );
    }
    return null;
  }

  @override
  Future<FilePickResult?> pickSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'vtt', 'ass', 'ssa'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path ?? '';
      String? content;

      if (path.isNotEmpty) {
        final bytes = await File(path).readAsBytes();
        content = _tryDecode(bytes);
      }

      return FilePickResult(
        path: path,
        name: file.name,
        content: content,
      );
    }
    return null;
  }

  @override
  List<SubtitleCue> parseSubtitle(String content, String fileName) {
    final ext = fileName.toLowerCase();
    final extension = ext.contains('.') ? ext.substring(ext.lastIndexOf('.')) : '.srt';
    return SubtitleParser.parseFromContent(content, extension);
  }

  String _tryDecode(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return String.fromCharCodes(bytes);
      }
    }
  }
}