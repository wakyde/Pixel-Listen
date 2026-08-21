// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
}

class AudioPlaybackService {
  html.AudioElement? _audio;
  bool _isLooping = false;
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

  Timer? _positionTimer;

  AudioPlaybackService() {
    _stateController.add(PlaybackState.idle);
  }

  Future<void> loadAudio(String filePath) async {
    if (_isDisposed) return;
    _setState(PlaybackState.loading);

    _audio?.remove();
    _audio = html.AudioElement(filePath);
    _audio!.preload = 'auto';

    final completer = Completer<void>();
    var resolved = false;

    void resolve() {
      if (!resolved) {
        resolved = true;
        if (!completer.isCompleted) completer.complete();
      }
    }

    _audio!.onCanPlay.listen((_) {
      if (_isDisposed) return;
      final d = _audio!.duration;
      _duration = (d is double && d.isFinite) ? d : 0;
      _durationController.add(_duration);
      _setState(PlaybackState.paused);
      resolve();
    });

    _audio!.onLoadedMetadata.listen((_) {
      if (_isDisposed) return;
      final d = _audio!.duration;
      if (d is double && d.isFinite && d > 0) {
        _duration = d;
        _durationController.add(_duration);
      }
    });

    _audio!.onEnded.listen((_) {
      if (_isDisposed) return;
      _positionTimer?.cancel();
      if (_isLooping) {
        _audio!.currentTime = 0;
        _audio!.play();
      } else {
        _setState(PlaybackState.completed);
      }
    });

    _audio!.onError.listen((e) {
      if (_isDisposed) return;
      print('Audio error: ${e.type}');
      _setState(PlaybackState.idle);
      resolve();
    });

    _audio!.load();

    await Future.any([completer.future, Future.delayed(const Duration(seconds: 60))]);
    if (!resolved) {
      print('Audio load timeout for: $filePath');
      _setState(PlaybackState.paused);
    }
  }

  void _startPositionTimer() {
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isDisposed || _audio == null) return;
      final t = _audio!.currentTime;
      _position = t is double ? t : t.toDouble();
      _positionController.add(_position);
    });
  }

  Future<void> play() async {
    if (_isDisposed || _audio == null) return;
    await _audio!.play();
    _setState(PlaybackState.playing);
    _startPositionTimer();
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    _audio?.pause();
    _positionTimer?.cancel();
    _setState(PlaybackState.paused);
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    _audio?.pause();
    if (_audio != null) {
      _audio!.currentTime = 0;
    }
    _positionTimer?.cancel();
    _position = 0;
    _positionController.add(0);
    _setState(PlaybackState.idle);
  }

  Future<void> seekTo(double seconds) async {
    if (_isDisposed) return;
    if (_audio != null) {
      _audio!.currentTime = seconds;
    }
    _position = seconds;
    _positionController.add(_position);
  }

  Future<void> setSpeed(double speed) async {
    if (_isDisposed) return;
    if (_audio != null) {
      _audio!.playbackRate = speed;
    }
    _speed = speed;
    _speedController.add(speed);
  }

  Future<void> setLoopMode(bool loop) async {
    if (_isDisposed) return;
    _isLooping = loop;
  }

  Future<void> dispose() async {
    _isDisposed = true;
    _positionTimer?.cancel();
    _audio?.pause();
    _audio?.remove();
    _audio = null;
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _speedController.close();
  }

  void _setState(PlaybackState newState) {
    if (_isDisposed) return;
    if (_state != newState) {
      _state = newState;
      _stateController.add(_state);
    }
  }
}