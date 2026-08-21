import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';

/// Preferred voice names in order of quality.
/// - "Samantha" / "Alex" are macOS system voices, very natural
/// - "Google US English" is Chrome's built-in HD voice
/// - "Microsoft Zira" is Windows built-in
const _preferredVoices = [
  'Google US English',
  'Samantha',
  'Alex',
  'Microsoft Zira Desktop',
  'Microsoft David Desktop',
  'Karen',
  'Moira',
  'Tessa',
];

html.SpeechSynthesisVoice? _cachedVoice;
Completer<void>? _voicesReady;

Future<void> _ensureVoicesLoaded() async {
  if (_cachedVoice != null) return;

  if (_voicesReady != null) {
    await _voicesReady!.future;
    return;
  }

  _voicesReady = Completer<void>();

  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      _voicesReady!.complete();
      return;
    }

    // Try to get voices immediately
    var voices = synth.getVoices();
    if (voices.isNotEmpty) {
      _selectVoice(voices);
      _voicesReady!.complete();
      return;
    }

    // Voices not loaded yet, wait for onvoiceschanged
    final eventCompleter = Completer<void>();
    synth.addEventListener('voiceschanged', (html.Event _) {
      if (!eventCompleter.isCompleted) {
        eventCompleter.complete();
      }
    });

    // Timeout after 3 seconds
    await eventCompleter.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () {
        debugPrint('[TtsService] Voice loading timed out');
      },
    );

    voices = synth.getVoices();
    if (voices.isNotEmpty) {
      _selectVoice(voices);
    }
  } catch (e) {
    debugPrint('[TtsService] Error loading voices: $e');
  } finally {
    if (!_voicesReady!.isCompleted) {
      _voicesReady!.complete();
    }
  }
}

void _selectVoice(List<html.SpeechSynthesisVoice> voices) {
  // Log available voices for debugging
  for (final v in voices) {
    debugPrint('[TtsService] Voice: ${v.name} lang=${v.lang} local=${v.localService}');
  }

  // Try preferred voices first
  for (final preferred in _preferredVoices) {
    for (final v in voices) {
      if (v.name == preferred) {
        _cachedVoice = v;
        debugPrint('[TtsService] Selected voice: ${v.name}');
        return;
      }
    }
  }

  // Fallback: pick best en-US voice (prefer local service)
  html.SpeechSynthesisVoice? best;
  for (final v in voices) {
    final lang = v.lang;
    if (lang == null || !lang.startsWith('en-US')) continue;
    if (best == null) {
      best = v;
      continue;
    }
    // Prefer local service voices over network ones
    if (v.localService == true && best.localService != true) {
      best = v;
    }
  }

  if (best != null) {
    _cachedVoice = best;
    debugPrint('[TtsService] Fallback voice: ${best.name}');
  }
}

Future<void> speak(String text) async {
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) {
      debugPrint('[TtsService] Web Speech API not available');
      return;
    }

    await _ensureVoicesLoaded();
    await stop();

    final utterance = html.SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    utterance.rate = 0.9;
    utterance.pitch = 1.0;

    if (_cachedVoice != null) {
      utterance.voice = _cachedVoice;
    }

    synth.speak(utterance);
  } catch (e) {
    debugPrint('[TtsService] Web TTS error: $e');
  }
}

Future<void> stop() async {
  try {
    final synth = html.window.speechSynthesis;
    if (synth == null) return;
    synth.cancel();
  } catch (e) {
    debugPrint('[TtsService] Web TTS stop error: $e');
  }
}