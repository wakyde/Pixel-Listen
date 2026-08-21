import 'dart:io';

File createFile(String path) => File(path);

Future<String> readFileAsString(String path) async {
  final file = File(path);
  return file.readAsString();
}

bool fileExists(String path) {
  return File(path).existsSync();
}