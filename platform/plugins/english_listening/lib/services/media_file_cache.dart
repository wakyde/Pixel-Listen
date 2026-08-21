import 'dart:typed_data';

import 'media_file_cache_platform.dart';
import 'media_file_cache_stub.dart'
    if (dart.library.html) 'media_file_cache_web.dart';

class MediaFileCache {
  MediaFileCache._();

  static final MediaFileCache instance = MediaFileCache._();

  final MediaFileCachePlatform _platform = createMediaFileCache();

  void store(String path, Uint8List bytes, String name) {
    _platform.store(path, bytes, name);
  }

  bool hasBytes(String path) {
    return _platform.hasBytes(path);
  }

  String? getBlobUrl(String path) {
    return _platform.getBlobUrl(path);
  }

  Future<String?> loadFromIndexedDB(String path) {
    return _platform.loadFromIndexedDB(path);
  }

  Future<bool> hasBytesIndexedDB(String fileName) {
    return _platform.hasBytesIndexedDB(fileName);
  }

  Future<String?> getBlobUrlFromIndexedDB(String fileName) {
    return _platform.getBlobUrlFromIndexedDB(fileName);
  }
}