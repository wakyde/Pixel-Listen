import 'dart:async';
import 'dart:io' show Platform, Process;

import 'package:flutter/foundation.dart';

Process? _currentProcess;

Future<void> speak(String text) async {
  if (!Platform.isMacOS) {
    debugPrint('[TtsService] TTS only supported on macOS');
    return;
  }

  await stop();

  _currentProcess = await Process.start('say', [text]);
  unawaited(_currentProcess!.exitCode.then((_) {
    _currentProcess = null;
  }));
}

Future<void> stop() async {
  if (_currentProcess != null) {
    _currentProcess!.kill();
    _currentProcess = null;
  }
}