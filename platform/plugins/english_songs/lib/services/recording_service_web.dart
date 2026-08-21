import 'dart:async';

class RecordingService {
  final StreamController<RecordingState> _stateController =
      StreamController<RecordingState>.broadcast();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();

  Stream<RecordingState> get stateStream => _stateController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  RecordingState _state = RecordingState.idle;
  RecordingState get state => _state;

  Future<void> startRecording() async {
    _state = RecordingState.recording;
    _stateController.add(_state);
  }

  Future<RecordingResult> stopRecording() async {
    _state = RecordingState.idle;
    _stateController.add(_state);
    return const RecordingResult(filePath: '');
  }

  Future<void> cancelRecording() async {
    _state = RecordingState.idle;
    _stateController.add(_state);
  }

  Future<bool> hasPermission() async {
    return true;
  }

  Future<void> dispose() async {
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