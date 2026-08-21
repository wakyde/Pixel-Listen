import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PlayerKeyboardHandler {
  const PlayerKeyboardHandler({
    required this.onPlayPause,
    required this.onSeekBack5s,
    required this.onSeekForward5s,
    required this.onPreviousCue,
    required this.onNextCue,
    required this.onEscape,
    required this.isPlaying,
    this.onGoBack,
  });

  final VoidCallback onPlayPause;
  final VoidCallback onSeekBack5s;
  final VoidCallback onSeekForward5s;
  final VoidCallback onPreviousCue;
  final VoidCallback onNextCue;
  final VoidCallback onEscape;
  final bool Function() isPlaying;
  final VoidCallback? onGoBack;

  static bool _isTextInputFocused(FocusNode node) {
    if (node.context == null) return false;
    final widget = node.context!.widget;
    return widget is EditableText;
  }

  KeyEventResult handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space) {
      if (_isTextInputFocused(node)) return KeyEventResult.ignored;
      onPlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      onSeekBack5s();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      onSeekForward5s();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      onPreviousCue();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      onNextCue();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (isPlaying()) {
        onPlayPause();
      } else if (onGoBack != null) {
        onGoBack!();
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}