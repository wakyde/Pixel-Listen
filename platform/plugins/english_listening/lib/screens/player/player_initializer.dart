import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../models/subtitle.dart';
import '../../providers/player_provider.dart';
import '../../services/ai_service.dart';
import '../../services/cefr_detector.dart';
import '../../services/subtitle_parser.dart';
import 'player_layout.dart';

class PlayerInitializer {
  PlayerInitializer({
    required this.ref,
    required this.onCuesLoaded,
    required this.onVideoReady,
    required this.onError,
    required this.onSourceChanged,
    required this.onTranscribingStateChanged,
    this.subtitleContent,
    this.subtitlePath,
    this.subtitleExtension,
    this.mediaPath,
    this.mediaName,
    this.aiService,
  });

  final WidgetRef ref;
  final void Function(List<SubtitleCue> cues, SubtitleSource source) onCuesLoaded;
  final void Function(VideoPlayerController controller) onVideoReady;
  final VoidCallback onError;
  final void Function(SubtitleSource source) onSourceChanged;
  final void Function({required bool isTranscribing, String? error}) onTranscribingStateChanged;
  final String? subtitleContent;
  final String? subtitlePath;
  final String? subtitleExtension;
  final String? mediaPath;
  final String? mediaName;
  final AIService? aiService;

  final CefrDetector _cefrDetector = CefrDetector();

  VideoPlayerController? videoController;

  Future<void> initAll() async {
    final notifier = ref.read(playerProvider.notifier);
    notifier.setLoading();

    try {
      await _cefrDetector.loadDictionary();

      SubtitleSource source = SubtitleSource.local;
      List<SubtitleCue> cues;

      if (subtitleContent != null) {
        cues = _detectCefr(
          SubtitleParser.parseFromContent(
            subtitleContent!,
            subtitleExtension ?? '.srt',
          ),
        );
        source = SubtitleSource.local;
      } else if (subtitlePath != null) {
        final file = File(subtitlePath!);
        final content = await file.readAsString();
        final ext = subtitlePath!.toLowerCase();
        final extension = ext.contains('.') ? ext.substring(ext.lastIndexOf('.')) : '.srt';
        cues = _detectCefr(SubtitleParser.parseFromContent(content, extension));
        source = SubtitleSource.local;
      } else if (mediaPath != null && aiService != null) {
        source = SubtitleSource.ai;
        cues = await _loadAISubtitles();
      } else {
        cues = _detectCefr(_sampleSubtitles);
        source = SubtitleSource.local;
      }

      onCuesLoaded(cues, source);
      onSourceChanged(source);
    } catch (e) {
      onError();
      return;
    }

    try {
      final controller = await _initVideoController();
      if (controller != null) {
        videoController = controller;
        onVideoReady(controller);
      } else {
        ref.read(isVideoInitializedProvider.notifier).state = true;
      }
    } catch (e) {
      debugPrint('Video init failed, subtitles still available: $e');
      ref.read(isVideoInitializedProvider.notifier).state = true;
    }
  }

  Future<List<SubtitleCue>> _loadAISubtitles() async {
    if (mediaPath == null || aiService == null) return _detectCefr(_sampleSubtitles);

    onTranscribingStateChanged(isTranscribing: true, error: null);

    try {
      final cached = await aiService!.checkAISubtitleCache(mediaPath!);
      if (cached != null) {
        onTranscribingStateChanged(isTranscribing: false);
        return _detectCefr(SubtitleParser.parseFromContent(cached, '.srt'));
      }

      final srt = await aiService!.transcribeAudio(mediaPath!);
      if (srt != null && srt.isNotEmpty) {
        onTranscribingStateChanged(isTranscribing: false);
        return _detectCefr(SubtitleParser.parseFromContent(srt, '.srt'));
      }

      onTranscribingStateChanged(
        isTranscribing: false,
        error: 'AI 转录失败，请检查后端服务是否可用',
      );
      return _detectCefr(_sampleSubtitles);
    } catch (e, st) {
      debugPrint('AI subtitle transcription failed: $e\n$st');
      onTranscribingStateChanged(
        isTranscribing: false,
        error: 'AI 转录失败，请确认已配置 GROQ_API_KEY',
      );
      return _detectCefr(_sampleSubtitles);
    }
  }

  Future<void> switchToSource(SubtitleSource source) async {
    if (source == SubtitleSource.ai) {
      onTranscribingStateChanged(isTranscribing: true, error: null);
      final cues = await _loadAISubtitles();
      onCuesLoaded(cues, SubtitleSource.ai);
      onSourceChanged(SubtitleSource.ai);
    }
  }

  List<SubtitleCue> _detectCefr(List<SubtitleCue> cues) {
    return cues.map((cue) {
      final tokens = _cefrDetector.detect(cue.text);
      return SubtitleCue(
        id: cue.id,
        start: cue.start,
        end: cue.end,
        text: cue.text,
        nativeTranslation: cue.nativeTranslation,
        cefrTokens: tokens.isEmpty ? null : tokens,
        collocationTokens: cue.collocationTokens,
      );
    }).toList();
  }

  Future<VideoPlayerController?> _initVideoController() async {
    final path = mediaPath ?? subtitlePath;
    if (path == null || path.isEmpty) return null;

    final controller = path.startsWith('http://') || path.startsWith('https://') || path.startsWith('blob:')
        ? VideoPlayerController.networkUrl(Uri.parse(path))
        : VideoPlayerController.file(File(path));

    await controller.initialize();
    return controller;
  }

  static final List<SubtitleCue> _sampleSubtitles = [
    SubtitleCue(
      id: '1',
      start: const Duration(seconds: 0, milliseconds: 500),
      end: const Duration(seconds: 3),
      text: 'Hello! Welcome to English Listening Practice.',
    ),
    SubtitleCue(
      id: '2',
      start: const Duration(seconds: 3, milliseconds: 500),
      end: const Duration(seconds: 7),
      text: 'Let\'s learn some useful English expressions today.',
    ),
    SubtitleCue(
      id: '3',
      start: const Duration(seconds: 7, milliseconds: 500),
      end: const Duration(seconds: 11),
      text: 'First, try to listen carefully without reading the subtitles.',
    ),
    SubtitleCue(
      id: '4',
      start: const Duration(seconds: 11, milliseconds: 500),
      end: const Duration(seconds: 15),
      text: 'Then, check the transcript to see if you understood correctly.',
    ),
    SubtitleCue(
      id: '5',
      start: const Duration(seconds: 15, milliseconds: 500),
      end: const Duration(seconds: 19),
      text: 'Practice makes perfect. Keep listening every day!',
    ),
    SubtitleCue(
      id: '6',
      start: const Duration(seconds: 19, milliseconds: 500),
      end: const Duration(seconds: 23),
      text: 'Review the vocabulary you learned in each session.',
    ),
    SubtitleCue(
      id: '7',
      start: const Duration(seconds: 23, milliseconds: 500),
      end: const Duration(seconds: 27),
      text: 'Try to use new words in your own sentences.',
    ),
    SubtitleCue(
      id: '8',
      start: const Duration(seconds: 27, milliseconds: 500),
      end: const Duration(seconds: 31),
      text: 'Listening to native speakers helps improve your pronunciation.',
    ),
    SubtitleCue(
      id: '9',
      start: const Duration(seconds: 31, milliseconds: 500),
      end: const Duration(seconds: 35),
      text: 'Don\'t worry if you don\'t understand everything at first.',
    ),
    SubtitleCue(
      id: '10',
      start: const Duration(seconds: 35, milliseconds: 500),
      end: const Duration(seconds: 39),
      text: 'The more you practice, the better you will become.',
    ),
  ];
}