import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  final StreamController<RecordingState> _stateController =
      StreamController<RecordingState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  StreamSubscription<RecordState>? _stateSub;
  StreamSubscription<Amplitude>? _amplitudeSub;

  String? _currentPath;

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission not granted');
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/recording_$timestamp.m4a';

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      numChannels: 1,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _recorder.start(config, path: _currentPath!);

    _state = RecordingState.recording;
    _stateController.add(_state);

    _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
      _amplitudeController.add(amp.current);
    });
  }

  Future<RecordingResult> stopRecording() async {
    _amplitudeSub?.cancel();

    final path = await _recorder.stop();
    if (path == null) {
      throw Exception('Recording failed');
    }

    _state = RecordingState.idle;
    _stateController.add(_state);

    return RecordingResult(filePath: path);
  }

  Future<void> cancelRecording() async {
    _amplitudeSub?.cancel();
    await _recorder.stop();
    _state = RecordingState.idle;
    _stateController.add(_state);
  }

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> dispose() async {
    _amplitudeSub?.cancel();
    _stateSub?.cancel();
    await _recorder.dispose();
    await _stateController.close();
    await _amplitudeController.close();
  }
}

enum RecordingState {
  idle,
  recording,
}

class RecordingResult {
  final String filePath;

  const RecordingResult({required this.filePath});
}