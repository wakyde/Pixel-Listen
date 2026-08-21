import 'dart:typed_data';

abstract class MediaFileCachePlatform {
  void store(String path, Uint8List bytes, String name);
  bool hasBytes(String path);
  String? getBlobUrl(String path);
  Future<String?> loadFromIndexedDB(String path);
  Future<bool> hasBytesIndexedDB(String fileName);
  Future<String?> getBlobUrlFromIndexedDB(String fileName);
}