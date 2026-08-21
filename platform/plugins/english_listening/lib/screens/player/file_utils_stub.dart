Future<String> readFileAsString(String path) async {
  throw UnsupportedError('File operations not supported on web');
}

bool fileExists(String path) {
  return false;
}