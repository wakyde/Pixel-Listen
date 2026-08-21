import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_ui/shared_ui.dart';

import '../models/song_models.dart';
import '../providers/song_providers.dart';
import '../services/audio_playback_service.dart';
import '../services/liaison_detector.dart';
import '../services/recording_service.dart';
import '../services/scoring_service.dart';
import 'favorites_screen.dart';

class SongPlayerScreen extends ConsumerStatefulWidget {
  final String? songId;
  final List<SongLyricLine> lines;
  final String songTitle;
  final String? artist;
  final String format;
  final bool hasTimestamps;
  final String? audioFilePath;

  const SongPlayerScreen({
    super.key,
    this.songId,
    required this.lines,
    required this.songTitle,
    this.artist,
    required this.format,
    required this.hasTimestamps,
    this.audioFilePath,
  });

  @override
  ConsumerState<SongPlayerScreen> createState() => _SongPlayerScreenState();
}

class _SongPlayerScreenState extends ConsumerState<SongPlayerScreen> {
  final AudioPlaybackService _audioService = AudioPlaybackService();
  final RecordingService _recordingService = RecordingService();
  StreamSubscription<PlaybackState>? _stateSub;
  StreamSubscription<double>? _positionSub;
  StreamSubscription<double>? _durationSub;
  StreamSubscription<double>? _amplitudeSub;

  List<SongLyricLine> _lines = [];
  int _activeLineIndex = 0;
  bool _isPlaying = false;
  double _currentTime = 0;
  double _totalDuration = 0;
  bool _isLooping = false;
  double _playbackSpeed = 1.0;
  bool _showLiaisons = true;
  bool _liaisonDetecting = false;

  bool _isRecording = false;
  bool _showScoring = false;
  SongScoreResult? _currentScore;
  final _recordingController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  static const _liaisonColors = {
    LiaisonType.consonantVowel: Color(0xFF10B981),
    LiaisonType.sameConsonant: Color(0xFF3B82F6),
    LiaisonType.tPlusJ: Color(0xFFF97316),
    LiaisonType.dPlusJ: Color(0xFFEF4444),
    LiaisonType.weakForm: Color(0xFF6B7280),
    LiaisonType.linkingR: Color(0xFF8B5CF6),
    LiaisonType.intrusiveR: Color(0xFFEC4899),
    LiaisonType.elision: Color(0xFF14B8A6),
    LiaisonType.other: Color(0xFF6B7280),
  };

  @override
  void initState() {
    super.initState();
    _lines = List.from(widget.lines);
    _totalDuration = _lines.isNotEmpty && _lines.last.endTime != null
        ? _lines.last.endTime!
        : 120.0;
    _detectLiaisons();
    _loadBestAudio();
  }

  Future<void> _loadBestAudio() async {
    _stateSub = _audioService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlaybackState.playing;
          if (state == PlaybackState.completed && !_isLooping) {
            _currentTime = 0;
            _activeLineIndex = 0;
          }
        });
      }
    });

    _positionSub = _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentTime = position;
          _updateActiveLine();
        });
      }
    });

    _durationSub = _audioService.durationStream.listen((duration) {
      if (mounted && duration > 0 && duration.isFinite) {
        setState(() => _totalDuration = duration);
      }
    });

    if (widget.artist != null && widget.artist!.isNotEmpty) {
      try {
        final streamUrl = Uri.parse(
          'http://localhost:8000/api/songs/stream'
          '?artist=${Uri.encodeComponent(widget.artist!)}'
          '&title=${Uri.encodeComponent(widget.songTitle)}',
        );
        await _audioService.loadAudio(streamUrl.toString());
        return;
      } catch (e) {
        print('Backend stream failed: $e');
      }
    }

    if (widget.audioFilePath != null && widget.audioFilePath!.isNotEmpty) {
      await _audioService.loadAudio(widget.audioFilePath!);
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _amplitudeSub?.cancel();
    _audioService.dispose();
    _recordingService.dispose();
    _scrollController.dispose();
    _recordingController.dispose();
    super.dispose();
  }

  Future<void> _detectLiaisons() async {
    setState(() => _liaisonDetecting = true);

    try {
      final updated = <SongLyricLine>[];
      for (final line in _lines) {
        final marks = LiaisonDetector.detect(line.text);
        updated.add(line.copyWith(liaisonMarks: marks.isNotEmpty ? marks : null));
      }

      if (mounted) {
        setState(() {
          _lines = updated;
          _liaisonDetecting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _liaisonDetecting = false);
      }
    }
  }

  SongLyricLine? get _currentLine {
    if (_lines.isEmpty || _activeLineIndex >= _lines.length) return null;
    return _lines[_activeLineIndex];
  }

  void _togglePlayPause() {
    if (!widget.hasTimestamps) return;

    if (_isPlaying) {
      _audioService.pause();
    } else {
      if (_audioService.state == PlaybackState.completed) {
        _audioService.seekTo(0);
      }
      _audioService.play();
    }
  }

  void _updateActiveLine() {
    for (int i = _lines.length - 1; i >= 0; i--) {
      final line = _lines[i];
      if (line.startTime != null && _currentTime >= line.startTime!) {
        if (_activeLineIndex != i) {
          setState(() => _activeLineIndex = i);
          _scrollToActiveLine();
        }
        return;
      }
    }
  }

  void _scrollToActiveLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final itemHeight = 48.0;
        final offset = (_activeLineIndex * itemHeight) -
            (_scrollController.position.viewportDimension / 2) +
            (itemHeight / 2);
        _scrollController.animateTo(
          offset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _jumpToLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    final line = _lines[index];
    if (line.startTime == null) return;

    setState(() {
      _activeLineIndex = index;
      _isLooping = false;
    });

    _audioService.seekTo(line.startTime!);
    _audioService.setLoopMode(false);
    _audioService.play();
    _scrollToActiveLine();
  }

  void _toggleLoop() {
    if (_currentLine?.startTime == null) return;
    setState(() => _isLooping = !_isLooping);
    _audioService.setLoopMode(_isLooping);
  }

  void _startRecording() async {
    if (_currentLine == null) return;

    try {
      final hasPermission = await _recordingService.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission required')),
          );
        }
        return;
      }

      await _recordingService.startRecording();

      setState(() {
        _isRecording = true;
        _showScoring = false;
        _currentScore = null;
        _recordingController.clear();
      });

      _amplitudeSub = _recordingService.amplitudeStream.listen((_) {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording... sing the current line!'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isRecording) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording failed: $e')),
        );
      }
    }
  }

  void _stopRecording() async {
    _amplitudeSub?.cancel();

    setState(() => _isRecording = false);

    final currentLine = _currentLine;
    if (currentLine == null) return;

    try {
      final result = await _recordingService.stopRecording();

      final simulatedText = _generateSimulatedRecording(currentLine.text);
      _recordingController.text = simulatedText;

      final score = SongScoringService.calculateScore(
        originalText: currentLine.text,
        recordedText: simulatedText,
        liaisonMarks: currentLine.liaisonMarks,
      );

      setState(() {
        _showScoring = true;
        _currentScore = score;
      });

      if (widget.songId != null) {
        try {
          final service = ref.read(songServiceProvider);
          final user = ref.read(currentUserProvider);
          await service.saveRecording(
            userId: user?.id ?? 'anonymous',
            songId: widget.songId!,
            lineId: currentLine.id,
            recordingPath: result.filePath,
            recognizedText: simulatedText,
            score: score,
          );
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stop recording failed: $e')),
        );
      }
    }
  }

  String _generateSimulatedRecording(String original) {
    final words = original.split(' ');
    final random = Random();
    final result = <String>[];

    for (final word in words) {
      if (random.nextDouble() > 0.15) {
        result.add(word);
      }
    }

    return result.join(' ');
  }

  void _nextLine() {
    if (_activeLineIndex < _lines.length - 1) {
      _jumpToLine(_activeLineIndex + 1);
    }
  }

  void _previousLine() {
    if (_activeLineIndex > 0) {
      _jumpToLine(_activeLineIndex - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.songTitle, style: PlatformTextStyles.title),
            if (widget.artist != null)
              Text(
                widget.artist!,
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Favorites',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showLiaisons ? Icons.link : Icons.link_off,
              color: _showLiaisons ? PlatformColors.primary : ThemeColors.of(context).onSurfaceVariant,
            ),
            tooltip: _showLiaisons ? 'Hide Liaisons' : 'Show Liaisons',
            onPressed: () => setState(() => _showLiaisons = !_showLiaisons),
          ),
          if (_liaisonDetecting)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          _buildPlaybackControls(),
          Expanded(child: _buildLyricsList()),
          if (_showScoring && _currentScore != null) _buildScoringPanel(),
          _buildRecordingBar(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: Row(
        children: [
          Text(
            _formatTime(_currentTime),
            style: PlatformTextStyles.caption,
          ),
          Expanded(
            child: Slider(
              value: _currentTime.clamp(0, _totalDuration),
              max: _totalDuration > 0 ? _totalDuration : 1.0,
              onChanged: widget.hasTimestamps
                  ? (v) {
                      _audioService.seekTo(v);
                      _updateActiveLine();
                    }
                  : null,
            ),
          ),
          Text(
            _formatTime(_totalDuration),
            style: PlatformTextStyles.caption,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 32,
            onPressed: widget.hasTimestamps ? _previousLine : null,
          ),
          const SizedBox(width: PlatformSpacing.md),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.hasTimestamps
                  ? PlatformColors.primary
                  : ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.3),
            ),
            child: IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 36,
              color: Colors.white,
              onPressed: _togglePlayPause,
            ),
          ),
          const SizedBox(width: PlatformSpacing.md),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: 32,
            onPressed: widget.hasTimestamps ? _nextLine : null,
          ),
          const SizedBox(width: PlatformSpacing.md),
          IconButton(
            icon: Icon(
              Icons.loop,
              color: _isLooping ? PlatformColors.amber : ThemeColors.of(context).onSurfaceVariant,
            ),
            iconSize: 28,
            tooltip: 'Loop current line',
            onPressed: widget.hasTimestamps ? _toggleLoop : null,
          ),
          const SizedBox(width: PlatformSpacing.xs),
          _buildSpeedControl(),
        ],
      ),
    );
  }

  Widget _buildSpeedControl() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5];
    final currentIndex = speeds.indexOf(_playbackSpeed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: currentIndex > 0
                ? () {
                    final newSpeed = speeds[currentIndex - 1];
                    setState(() => _playbackSpeed = newSpeed);
                    _audioService.setSpeed(newSpeed);
                  }
                : null,
            child: Icon(
              Icons.remove,
              size: 18,
              color: currentIndex > 0
                  ? ThemeColors.of(context).onSurface
                  : ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              final nextIndex = (currentIndex + 1) % speeds.length;
              setState(() => _playbackSpeed = speeds[nextIndex]);
              _audioService.setSpeed(speeds[nextIndex]);
            },
            child: Text(
              '${_playbackSpeed}x',
              style: PlatformTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: _playbackSpeed != 1.0
                    ? PlatformColors.primary
                    : ThemeColors.of(context).onSurface,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: currentIndex < speeds.length - 1
                ? () {
                    final newSpeed = speeds[currentIndex + 1];
                    setState(() => _playbackSpeed = newSpeed);
                    _audioService.setSpeed(newSpeed);
                  }
                : null,
            child: Icon(
              Icons.add,
              size: 18,
              color: currentIndex < speeds.length - 1
                  ? ThemeColors.of(context).onSurface
                  : ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsList() {
    if (_lines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 48, color: PlatformColors.gray),
            const SizedBox(height: PlatformSpacing.md),
            Text(
              'No lyrics available',
              style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: PlatformSpacing.md),
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        final isActive = widget.hasTimestamps && index == _activeLineIndex;
        return _buildLyricLine(line, isActive, index);
      },
    );
  }

  Widget _buildLyricLine(SongLyricLine line, bool isActive, int index) {
    return GestureDetector(
      onTap: () => _jumpToLine(index),
      onLongPress: () => _showLoopOption(index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: PlatformSpacing.md,
          vertical: PlatformSpacing.sm,
        ),
        color: isActive
            ? PlatformColors.amber.withValues(alpha: 0.2)
            : Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isActive && _isLooping)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.loop, size: 14, color: PlatformColors.amber),
                  ),
                Expanded(
                  child: isActive && line.wordTimings != null
                      ? _buildWordTimingText(line)
                      : _showLiaisons && line.liaisonMarks != null
                          ? _buildRichLyricText(line)
                          : Text(
                              line.text,
                              style: PlatformTextStyles.body.copyWith(
                                fontSize: 18,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                                color: isActive
                                    ? ThemeColors.of(context).onSurface
                                    : ThemeColors.of(context).onSurfaceVariant,
                                height: 1.6,
                              ),
                            ),
                ),
              ],
            ),
            if (line.liaisonMarks != null && _showLiaisons)
              _buildLiaisonHints(line),
          ],
        ),
      ),
    );
  }

  Widget _buildWordTimingText(SongLyricLine line) {
    final wordTimings = line.wordTimings!;
    final spans = <InlineSpan>[];

    for (int i = 0; i < wordTimings.length; i++) {
      final wt = wordTimings[i];
      final nextTime = i + 1 < wordTimings.length
          ? wordTimings[i + 1].time
          : line.endTime ?? _totalDuration;
      final isCurrentWord = _currentTime >= wt.time && _currentTime < nextTime;

      spans.add(TextSpan(
        text: '${wt.word}${i < wordTimings.length - 1 ? " " : ""}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: isCurrentWord ? FontWeight.w700 : FontWeight.w400,
          color: isCurrentWord
              ? PlatformColors.primary
              : ThemeColors.of(context).onSurface,
          backgroundColor: isCurrentWord
              ? PlatformColors.primary.withValues(alpha: 0.15)
              : null,
          height: 1.6,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: PlatformTextStyles.body.copyWith(
          fontSize: 18,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildRichLyricText(SongLyricLine line) {
    final marks = line.liaisonMarks!;
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    final sortedMarks = List<LiaisonMark>.from(marks)
      ..sort((a, b) => a.startChar.compareTo(b.startChar));

    for (final mark in sortedMarks) {
      if (mark.startChar > lastEnd) {
        spans.add(TextSpan(
          text: line.text.substring(lastEnd, mark.startChar),
        ));
      }

      if (mark.endChar <= line.text.length) {
        spans.add(TextSpan(
          text: line.text.substring(mark.startChar, mark.endChar),
          style: TextStyle(
            color: _liaisonColors[mark.type] ?? PlatformColors.gray,
            decoration: mark.type == LiaisonType.weakForm
                ? TextDecoration.underline
                : TextDecoration.underline,
            decorationColor: _liaisonColors[mark.type] ?? PlatformColors.gray,
            decorationStyle: mark.type == LiaisonType.weakForm
                ? TextDecorationStyle.dashed
                : TextDecorationStyle.solid,
            fontWeight: FontWeight.w600,
          ),
        ));
        lastEnd = mark.endChar;
      }
    }

    if (lastEnd < line.text.length) {
      spans.add(TextSpan(text: line.text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: PlatformTextStyles.body.copyWith(
          fontSize: 18,
          fontWeight: _activeLineIndex == _lines.indexOf(line)
              ? FontWeight.w700
              : FontWeight.w400,
          color: _activeLineIndex == _lines.indexOf(line)
              ? ThemeColors.of(context).onSurface
              : ThemeColors.of(context).onSurfaceVariant,
          height: 1.6,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildLiaisonHints(SongLyricLine line) {
    final marks = line.liaisonMarks!;
    if (marks.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: marks.map((mark) {
          return GestureDetector(
            onTap: () => _showLiaisonPopover(mark),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (_liaisonColors[mark.type] ?? PlatformColors.gray).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.link,
                    size: 12,
                    color: _liaisonColors[mark.type] ?? PlatformColors.gray,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mark.pronunciation,
                    style: PlatformTextStyles.caption.copyWith(
                      color: _liaisonColors[mark.type] ?? PlatformColors.gray,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLiaisonPopover(LiaisonMark mark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _liaisonColors[mark.type],
              ),
            ),
            const SizedBox(width: 8),
            Text(mark.text),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pronunciation: ${mark.pronunciation}',
                style: PlatformTextStyles.body),
            const SizedBox(height: 8),
            Text('Type: ${mark.type.displayName}',
                style: PlatformTextStyles.caption),
            const SizedBox(height: 4),
            Text('Detected by: ${mark.detectedBy}',
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final service = ref.read(songServiceProvider);
                final user = ref.read(currentUserProvider);
                await service.addFavorite(
                  userId: user?.id ?? 'anonymous',
                  songId: widget.songId,
                  lineId: _currentLine?.id,
                  text: mark.text,
                  pronunciation: mark.pronunciation,
                  type: mark.type.name,
                  startChar: mark.startChar,
                  endChar: mark.endChar,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved: ${mark.pronunciation}')),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Already saved')),
                  );
                }
              }
            },
            icon: const Icon(Icons.star_border, size: 18),
            label: const Text('Favorite'),
          ),
        ],
      ),
    );
  }

  void _showLoopOption(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.loop),
              title: const Text('Loop this line'),
              onTap: () {
                _jumpToLine(index);
                setState(() => _isLooping = true);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic),
              title: const Text('Record sing-along'),
              onTap: () {
                _jumpToLine(index);
                Navigator.pop(context);
                _startRecording();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        border: Border(
          top: BorderSide(color: ThemeColors.of(context).outline),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording) ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Recording...'),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_currentLine != null && _currentLine!.startTime != null) ...[
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? PlatformColors.red : PlatformColors.primary,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.mic, color: Colors.white),
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                  ),
                ),
                const SizedBox(width: PlatformSpacing.md),
              ],
              Text(
                _currentLine != null
                    ? 'Tap mic to sing along'
                    : 'Select a line to start',
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoringPanel() {
    final score = _currentScore!;
    final isLow = score.totalScore < 60;

    return Container(
      margin: const EdgeInsets.all(PlatformSpacing.md),
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLow ? PlatformColors.red.withValues(alpha: 0.3) : PlatformColors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Score', style: PlatformTextStyles.title),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _showScoring = false),
              ),
            ],
          ),
          const SizedBox(height: PlatformSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: score.totalScore / 100,
                      strokeWidth: 6,
                      backgroundColor: ThemeColors.of(context).outline,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isLow ? PlatformColors.red : PlatformColors.green,
                      ),
                    ),
                    Text(
                      '${score.totalScore}',
                      style: PlatformTextStyles.headline.copyWith(
                        color: isLow ? PlatformColors.red : PlatformColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PlatformSpacing.md),
          _buildScoreBar('Pronunciation', score.pronunciationScore),
          const SizedBox(height: PlatformSpacing.xs),
          _buildScoreBar('Rhythm', score.rhythmScore),
          if (score.liaisonScore != null) ...[
            const SizedBox(height: PlatformSpacing.xs),
            _buildScoreBar('Liaison', score.liaisonScore!),
          ],
          const SizedBox(height: PlatformSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _startRecording,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
              const SizedBox(width: PlatformSpacing.sm),
              FilledButton.icon(
                onPressed: _nextLine,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Next Line'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, int score) {
    final color = score >= 80
        ? PlatformColors.green
        : score >= 60
            ? PlatformColors.amber
            : PlatformColors.red;

    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: PlatformTextStyles.caption),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 100,
              backgroundColor: ThemeColors.of(context).outline,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$score',
            style: PlatformTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}