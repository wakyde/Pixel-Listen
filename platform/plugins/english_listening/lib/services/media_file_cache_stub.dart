import 'dart:typed_data';

import 'media_file_cache_platform.dart';

class _MediaFileCacheStub implements MediaFileCachePlatform {
  @override
  void store(String path, Uint8List bytes, String name) {}

  @override
  bool hasBytes(String path) => false;

  @override
  String? getBlobUrl(String path) => null;

  @override
  Future<String?> loadFromIndexedDB(String path) async => null;

  @override
  Future<bool> hasBytesIndexedDB(String fileName) async => false;

  @override
  Future<String?> getBlobUrlFromIndexedDB(String fileName) async => null;
}

MediaFileCachePlatform createMediaFileCache() => _MediaFileCacheStub();