// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import '../models/subtitle.dart';
import 'file_picker_service.dart';
import 'media_file_cache.dart';
import 'subtitle_parser.dart';

class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<FilePickResult?> pickMedia() {
    final completer = Completer<FilePickResult?>();

    final input = html.FileUploadInputElement()
      ..accept = 'video/*,audio/*,.mp4,.mkv,.webm,.mov,.avi,.mp3,.m4a,.wav,.ogg,.flac,.aac'
      ..click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files.first;
      final blobUrl = html.Url.createObjectUrl(file);
      final reader = html.FileReader();

      reader.onLoad.listen((_) {
        final bytes = reader.result as Uint8List?;
        if (bytes != null) {
          MediaFileCache.instance.store(blobUrl, bytes, file.name);
        }

        completer.complete(FilePickResult(
          path: blobUrl,
          name: file.name,
          bytes: bytes,
        ));
      });

      reader.onError.listen((_) {
        completer.complete(FilePickResult(
          path: blobUrl,
          name: file.name,
        ));
      });

      reader.readAsArrayBuffer(file);
    });

    input.onAbort.listen((_) => completer.complete(null));

    return completer.future;
  }

  @override
  Future<FilePickResult?> pickSubtitle() {
    final completer = Completer<FilePickResult?>();

    final input = html.FileUploadInputElement()
      ..accept = '.srt,.vtt,.ass,.ssa,text/plain'
      ..click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files.first;
      final reader = html.FileReader();

      reader.onLoad.listen((_) {
        final content = reader.result as String? ?? '';
        completer.complete(FilePickResult(
          path: file.name,
          name: file.name,
          content: content,
        ));
      });

      reader.onError.listen((_) {
        completer.complete(null);
      });

      reader.readAsText(file);
    });

    input.onAbort.listen((_) => completer.complete(null));

    return completer.future;
  }

  @override
  List<SubtitleCue> parseSubtitle(String content, String fileName) {
    final ext = fileName.toLowerCase();
    final extension = ext.contains('.') ? ext.substring(ext.lastIndexOf('.')) : '.srt';
    return SubtitleParser.parseFromContent(content, extension);
  }
}