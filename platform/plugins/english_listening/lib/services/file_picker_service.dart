import 'dart:typed_data';

import '../models/subtitle.dart';

class FilePickResult {
  final String path;
  final String name;
  final String? content;
  final Uint8List? bytes;

  const FilePickResult({
    required this.path,
    required this.name,
    this.content,
    this.bytes,
  });
}

abstract class FilePickerService {
  Future<FilePickResult?> pickMedia();
  Future<FilePickResult?> pickSubtitle();
  List<SubtitleCue> parseSubtitle(String content, String fileName);
}