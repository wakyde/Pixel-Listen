import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:html' as html;
import 'dart:typed_data';

import 'media_file_cache_platform.dart';

const _kDbName = 'english_listening_media_cache';
const _kStoreName = 'files';
const _kDbVersion = 1;

class _MediaFileCacheWeb implements MediaFileCachePlatform {
  final Map<String, _CachedFile> _memory = {};
  JSObject? _db;

  Future<JSObject> _getDatabase() async {
    if (_db != null) return _db!;
    final completer = Completer<JSObject>();
    final window = html.window;
    final indexedDB = (window as JSObject).getProperty('indexedDB'.toJS) as JSObject?;
    if (indexedDB == null) {
      completer.completeError('IndexedDB not available');
      return completer.future;
    }
    final request = indexedDB.callMethod('open'.toJS, _kDbName.toJS, _kDbVersion.toJS) as JSObject?;
    if (request == null) {
      completer.completeError('Failed to open IndexedDB');
      return completer.future;
    }
    request.callMethod('addEventListener'.toJS, 'upgradeneeded'.toJS, (JSObject event) {
      final target = event.getProperty('target'.toJS) as JSObject?;
      if (target == null) return;
      final db = target.getProperty('result'.toJS) as JSObject?;
      if (db == null) return;
      final names = db.getProperty('objectStoreNames'.toJS) as JSObject?;
      if (names == null) return;
      final hasStore = names.callMethod('contains'.toJS, _kStoreName.toJS);
      if (hasStore.dartify() != true) {
        db.callMethod('createObjectStore'.toJS, _kStoreName.toJS);
      }
    }.toJS);
    request.callMethod('addEventListener'.toJS, 'success'.toJS, (JSObject event) {
      final target = event.getProperty('target'.toJS) as JSObject?;
      if (target == null) return;
      final db = target.getProperty('result'.toJS) as JSObject?;
      if (db == null) return;
      _db = db;
      completer.complete(_db);
    }.toJS);
    request.callMethod('addEventListener'.toJS, 'error'.toJS, (JSObject event) {
      completer.completeError('Failed to open IndexedDB');
    }.toJS);
    return completer.future;
  }

  JSObject? _getStoreSync(JSObject db, String mode) {
    final transaction = db.callMethod('transaction'.toJS, _kStoreName.toJS, mode.toJS) as JSObject?;
    if (transaction == null) return null;
    final store = transaction.callMethod('objectStore'.toJS, _kStoreName.toJS) as JSObject?;
    return store;
  }

  @override
  void store(String path, Uint8List bytes, String name) {
    _memory[path] = _CachedFile(bytes: bytes, name: name);
    _storeToIndexedDB(name, bytes);
  }

  Future<void> _storeToIndexedDB(String fileName, Uint8List bytes) async {
    try {
      final db = await _getDatabase();
      final store = _getStoreSync(db, 'readwrite');
      if (store == null) return;
      store.callMethod('put'.toJS, bytes.buffer.toJS, fileName.toJS);
    } catch (e) {
      // ignore errors; IndexedDB may be unavailable
    }
  }

  @override
  bool hasBytes(String path) {
    return _memory.containsKey(path);
  }

  @override
  String? getBlobUrl(String path) {
    final cached = _memory[path];
    if (cached != null) {
      return html.Url.createObjectUrl(html.Blob([cached.bytes]));
    }
    return null;
  }

  @override
  Future<String?> loadFromIndexedDB(String path) async {
    return null;
  }

  @override
  Future<bool> hasBytesIndexedDB(String fileName) async {
    try {
      final db = await _getDatabase();
      final store = _getStoreSync(db, 'readonly');
      if (store == null) return false;
      final completer = Completer<bool>();
      final request = store.callMethod('get'.toJS, fileName.toJS) as JSObject?;
      if (request == null) return false;
      request.callMethod('addEventListener'.toJS, 'success'.toJS, (JSObject event) {
        final target = event.getProperty('target'.toJS) as JSObject?;
        if (target == null) {
          completer.complete(false);
          return;
        }
        final result = target.getProperty('result'.toJS);
        completer.complete(result != null);
      }.toJS);
      request.callMethod('addEventListener'.toJS, 'error'.toJS, (JSObject event) {
        completer.complete(false);
      }.toJS);
      return await completer.future;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<String?> getBlobUrlFromIndexedDB(String fileName) async {
    try {
      final db = await _getDatabase();
      final store = _getStoreSync(db, 'readonly');
      if (store == null) return null;
      final completer = Completer<String?>();
      final request = store.callMethod('get'.toJS, fileName.toJS) as JSObject?;
      if (request == null) return null;
      request.callMethod('addEventListener'.toJS, 'success'.toJS, (JSObject event) {
        final target = event.getProperty('target'.toJS) as JSObject?;
        if (target == null) {
          completer.complete(null);
          return;
        }
        final result = target.getProperty('result'.toJS);
        if (result != null) {
          final reader = html.FileReader();
          reader.onLoadEnd.first.then((_) {
            final bytes = reader.result as Uint8List?;
            if (bytes != null) {
              final blobUrl = html.Url.createObjectUrl(html.Blob([bytes]));
              _memory[blobUrl] = _CachedFile(bytes: bytes, name: fileName);
              completer.complete(blobUrl);
            } else {
              completer.complete(null);
            }
          });
          reader.onError.first.then((_) {
            completer.complete(null);
          });
          reader.readAsArrayBuffer(html.Blob([result]));
        } else {
          completer.complete(null);
        }
      }.toJS);
      request.callMethod('addEventListener'.toJS, 'error'.toJS, (JSObject event) {
        completer.complete(null);
      }.toJS);
      return await completer.future;
    } catch (e) {
      return null;
    }
  }
}

class _CachedFile {
  final Uint8List bytes;
  final String name;

  const _CachedFile({required this.bytes, required this.name});
}

MediaFileCachePlatform createMediaFileCache() => _MediaFileCacheWeb();