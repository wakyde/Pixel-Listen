// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

import 'file_picker_service.dart';

class FilePickerServiceImpl implements FilePickerService {
  @override
  Future<FilePickResult?> pickAudio() {
    final completer = Completer<FilePickResult?>();

    final input = html.FileUploadInputElement()
      ..accept = 'audio/*,.mp3,.m4a,.wav,.ogg,.flac,.aac,.wma'
      ..click();

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        completer.complete(null);
        return;
      }

      final file = files.first;
      final blobUrl = html.Url.createObjectUrl(file);

      completer.complete(FilePickResult(
        path: blobUrl,
        name: file.name,
      ));
    });

    input.onAbort.listen((_) => completer.complete(null));

    return completer.future;
  }

  @override
  Future<FilePickResult?> pickLyrics() {
    final completer = Completer<FilePickResult?>();

    final input = html.FileUploadInputElement()
      ..accept = '.lrc,.srt,.vtt,.txt,text/plain'
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
}