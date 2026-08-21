import 'dart:io';

import 'package:file_picker/file_picker.dart';

import 'file_picker_service.dart';

class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<FilePickResult?> pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'm4a', 'wav', 'ogg', 'flac', 'aac', 'wma'],
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
  Future<FilePickResult?> pickLyrics() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['lrc', 'srt', 'vtt', 'txt'],
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final path = file.path ?? '';
      String? content;

      if (path.isNotEmpty) {
        content = await File(path).readAsString();
      }

      return FilePickResult(
        path: path,
        name: file.name,
        content: content,
      );
    }
    return null;
  }
}