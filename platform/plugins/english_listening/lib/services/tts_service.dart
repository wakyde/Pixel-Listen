import 'dart:async';

import 'tts_platform_web.dart'
    if (dart.library.io) 'tts_platform_io.dart' as platform;

class TtsService {
  Future<void> speak(String text) async {
    await platform.speak(text);
  }

  Future<void> stop() async {
    await platform.stop();
  }

  void dispose() {
    stop();
  }
}