import 'dart:async';

import 'package:just_audio/just_audio.dart';

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
}

class AudioPlaybackService {
  final AudioPlayer _player = AudioPlayer();
  bool _isDisposed = false;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();
  final StreamController<double> _positionController =
      StreamController<double>.broadcast();
  final StreamController<double> _durationController =
      StreamController<double>.broadcast();
  final StreamController<double> _speedController =
      StreamController<double>.broadcast();

  Stream<PlaybackState> get stateStream => _stateController.stream;
  Stream<double> get positionStream => _positionController.stream;
  Stream<double> get durationStream => _durationController.stream;
  Stream<double> get speedStream => _speedController.stream;

  PlaybackState _state = PlaybackState.idle;
  PlaybackState get state => _state;

  double _duration = 0;
  double get duration => _duration;

  double _position = 0;
  double get position => _position;

  double _speed = 1.0;
  double get speed => _speed;

  AudioPlaybackService() {
    _player.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      PlaybackState newState;
      if (playerState.processingState == ProcessingState.loading ||
          playerState.processingState == ProcessingState.buffering) {
        newState = PlaybackState.loading;
      } else if (playerState.playing) {
        newState = PlaybackState.playing;
      } else if (playerState.processingState == ProcessingState.completed) {
        newState = PlaybackState.completed;
      } else {
        newState = PlaybackState.paused;
      }

      if (newState != _state) {
        _state = newState;
        _stateController.add(_state);
      }
    });

    _player.positionStream.listen((p) {
      if (_isDisposed) return;
      _position = p.inMilliseconds / 1000.0;
      _positionController.add(_position);
    });

    _player.durationStream.listen((d) {
      if (_isDisposed) return;
      if (d != null) {
        _duration = d.inMilliseconds / 1000.0;
        _durationController.add(_duration);
      }
    });

    _player.speedStream.listen((s) {
      if (_isDisposed) return;
      _speed = s;
      _speedController.add(s);
    });
  }

  Future<void> loadAudio(String filePath) async {
    if (_isDisposed) return;
    _state = PlaybackState.loading;
    _stateController.add(_state);

    try {
      if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
        await _player.setUrl(filePath);
      } else {
        await _player.setFilePath(filePath);
      }
    } catch (e) {
      if (_isDisposed) return;
      _state = PlaybackState.idle;
      _stateController.add(_state);
      rethrow;
    }
  }

  Future<void> play() async {
    if (_isDisposed) return;
    await _player.play();
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    await _player.pause();
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    await _player.stop();
    _state = PlaybackState.idle;
    _stateController.add(_state);
  }

  Future<void> seekTo(double seconds) async {
    if (_isDisposed) return;
    await _player.seek(Duration(milliseconds: (seconds * 1000).round()));
  }

  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    await _player.setSpeed(speed);
  }

  Future<void> setLoopMode(bool loop) async {
    if (_isDisposed) return;
    if (loop) {
      await _player.setLoopMode(LoopMode.one);
    } else {
      await _player.setLoopMode(LoopMode.off);
    }
  }

  Future<void> dispose() async {
    _isDisposed = true;
    await _player.dispose();
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _speedController.close();
  }
}