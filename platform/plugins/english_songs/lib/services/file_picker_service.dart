class FilePickResult {
  final String path;
  final String name;
  final String? content;

  const FilePickResult({
    required this.path,
    required this.name,
    this.content,
  });
}

abstract class FilePickerService {
  Future<FilePickResult?> pickAudio();
  Future<FilePickResult?> pickLyrics();
}