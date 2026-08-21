import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subtitle.dart';
import '../screens/player/player_layout.dart';

class PlayerNotifier extends StateNotifier<PlayerStatus> {
  Timer? _positionTimer;
  final List<SubtitleCue> _cues = [];

  PlayerNotifier() : super(const PlayerStatus());

  List<SubtitleCue> get cues => _cues;

  void loadSubtitles(List<SubtitleCue> cues) {
    _cues.clear();
    _cues.addAll(cues);
    _updateActiveCue();
  }

  void setDuration(Duration duration) {
    state = state.copyWith(duration: duration);
  }

  void startPositionTimer(void Function(Duration) onTick) {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      onTick(state.position);
    });
  }

  void updatePosition(Duration position) {
    if (!mounted) return;
    state = state.copyWith(position: position);
    _updateActiveCue();
  }

  void play() {
    state = state.copyWith(state: PlayerState.playing);
  }

  void pause() {
    state = state.copyWith(state: PlayerState.paused);
  }

  void setLoading() {
    state = state.copyWith(state: PlayerState.loading);
  }

  void setError() {
    state = state.copyWith(state: PlayerState.error);
  }

  void setLoopStart(Duration position) {
    final loopEnd = state.loopEnd;
    if (loopEnd != null && position >= loopEnd) {
      return;
    }
    state = state.copyWith(loopStart: position);
  }

  void setLoopEnd(Duration position) {
    final loopStart = state.loopStart;
    if (loopStart != null && position <= loopStart) {
      return;
    }
    state = state.copyWith(loopEnd: position);
  }

  bool toggleLoop() {
    if (state.loopStart == null || state.loopEnd == null) {
      return false;
    }
    state = state.copyWith(isLooping: !state.isLooping);
    return true;
  }

  void setLeadTime(Duration leadTime) {
    state = state.copyWith(leadTime: leadTime);
  }

  void clearLoop() {
    state = state.copyWith(
      isLooping: false,
      clearLoopStart: true,
      clearLoopEnd: true,
    );
  }

  void toggleSkipSilent() {
    state = state.copyWith(skipSilent: !state.skipSilent);
  }

  void _updateActiveCue() {
    final pos = state.position;
    int? activeIndex;
    for (int i = 0; i < _cues.length; i++) {
      if (pos >= _cues[i].start && pos <= _cues[i].end) {
        activeIndex = i;
        break;
      }
    }
    if (activeIndex != state.activeCueIndex) {
      state = state.copyWith(activeCueIndex: activeIndex);
    }
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }
}

final playerProvider = StateNotifierProvider<PlayerNotifier, PlayerStatus>((ref) {
  return PlayerNotifier();
});

final subtitleSourceProvider = StateProvider<SubtitleSource>((ref) => SubtitleSource.local);

final subtitleDisplayModeProvider = StateProvider<SubtitleDisplayMode>(
  (ref) => SubtitleDisplayMode.english,
);

final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

final isVideoInitializedProvider = StateProvider<bool>((ref) => false);