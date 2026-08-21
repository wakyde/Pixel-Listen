import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:video_player/video_player.dart';

import '../constants.dart';
import '../models/subtitle.dart';
import '../providers/ab_loop_history.dart';
import '../providers/favorites_store.dart';
import '../providers/flashcard_store.dart';
import '../providers/listening_history_store.dart';
import '../providers/memorization_provider.dart';
import '../providers/player_provider.dart';
import '../services/cefr_detector.dart';
import '../services/collocation_detector.dart';
import '../services/file_picker_factory.dart';
import '../services/file_picker_service.dart';
import '../services/media_scanner.dart';
import '../services/subtitle_parser.dart';
import '../services/ai_service.dart';
import '../widgets/player/tutor_chat_panel.dart';
import '../widgets/player/collocation_panel.dart';
import '../widgets/player/memo_card_template_panel.dart';
import '../widgets/player/grammar_analysis_panel.dart';
import '../widgets/error_boundary.dart';
import '../widgets/player/control_bar.dart';
import '../widgets/player/vocabulary_panel.dart';
import 'player/player_app_bar.dart';
import 'player/player_dialogs.dart';
import 'player/player_initializer.dart';
import 'player/player_keyboard.dart';
import 'player/player_layout.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final String? mediaPath;
  final String? subtitlePath;
  final String? subtitleContent;
  final String? subtitleExtension;
  final String? mediaName;

  const PlayerScreen({
    super.key,
    this.mediaPath,
    this.subtitlePath,
    this.subtitleContent,
    this.subtitleExtension,
    this.mediaName,
  });

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  VideoPlayerController? _videoController;
  final CefrDetector _cefrDetector = CefrDetector();
  final CollocationDetector _collocationDetector = CollocationDetector();
  final AIService _aiService = AIService(getToken: () => 'mock-token');
  final FilePickerService _picker = createFilePickerService();
  bool _isCollocationDetecting = false;
  bool _isLookingUp = false;
  PersistentBottomSheetController? _lookupController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<SubtitleCue> _subtitleCues = [];
  String? _importedSubtitleContent;
  double _videoHeight = 220;
  double? _wideVideoWidth;
  final FocusNode _keyboardFocusNode = FocusNode();
  late final PlayerKeyboardHandler _keyboardHandler;
  late final PlayerInitializer _initializer;
  Timer? _silenceTimer;
  Duration? _lastPosition;
  bool _isTranscribing = false;
  String? _transcribeError;
  MediaFolder? _mediaFolder;
  int _currentEpisodeIndex = 0;
  Timer? _historySaveTimer;

  @override
  void initState() {
    super.initState();
    _keyboardHandler = PlayerKeyboardHandler(
      onPlayPause: _handlePlayPause,
      onSeekBack5s: () {
        final pos = _videoController?.value.position ?? Duration.zero;
        _handleSeek(pos - PlayerConstants.seekStep);
      },
      onSeekForward5s: () {
        final pos = _videoController?.value.position ?? Duration.zero;
        _handleSeek(pos + PlayerConstants.seekStep);
      },
      onPreviousCue: _handlePreviousCue,
      onNextCue: _handleNextCue,
      onEscape: () {
        if (_videoController?.value.isPlaying ?? false) {
          _handlePlayPause();
        }
      },
      onGoBack: () => context.pop(),
      isPlaying: () => _videoController?.value.isPlaying ?? false,
    );
    _initializer = PlayerInitializer(
      ref: ref,
      onCuesLoaded: (cues, source) {
        if (mounted) {
          setState(() {
            _subtitleCues = cues;
          });
          ref.read(subtitleSourceProvider.notifier).state = source;
          ref.read(playerProvider.notifier).loadSubtitles(cues);
          final isImported = widget.subtitleContent != null || widget.subtitlePath != null;
          final isAi = source == SubtitleSource.ai;
          if (isImported || isAi) {
            ref.read(memorizationProvider.notifier).loadCues(cues);
          }
        }
      },
      onVideoReady: (controller) {
        if (mounted) {
          setState(() {
            _videoController = controller;
          });
          ref.read(isVideoInitializedProvider.notifier).state = true;
          _videoController!.addListener(_onVideoUpdate);
          _videoController!.play();
          ref.read(playerProvider.notifier).play();
        }
      },
      onError: () {
        ref.read(playerProvider.notifier).setError();
      },
      onSourceChanged: (source) {
        if (mounted) {
          ref.read(subtitleSourceProvider.notifier).state = source;
        }
      },
      onTranscribingStateChanged: ({required bool isTranscribing, String? error}) {
        if (mounted) {
          setState(() {
            _isTranscribing = isTranscribing;
            _transcribeError = error;
          });
        }
      },
      subtitleContent: widget.subtitleContent,
      subtitlePath: widget.subtitlePath,
      subtitleExtension: widget.subtitleExtension,
      mediaPath: widget.mediaPath,
      mediaName: widget.mediaName,
      aiService: _aiService,
    );
    Future.microtask(() => _initAll());
  }

  @override
  void dispose() {
    _historySaveTimer?.cancel();
    _silenceTimer?.cancel();
    _lookupController?.close();
    _videoController?.removeListener(_onVideoUpdate);
    _saveHistory();
    _keyboardFocusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initAll() async {
    await _cefrDetector.loadDictionary();
    await _initializer.initAll();
    _detectCollocations();
    _scanMediaFolder();
    _startHistoryTracking();
  }

  void _scanMediaFolder() {
    if (widget.mediaPath == null) return;
    final folder = MediaScanner.scanFolder(widget.mediaPath!);
    if (folder != null && folder.hasMultipleEpisodes) {
      setState(() => _mediaFolder = folder);
    }
  }

  void _startHistoryTracking() {
    _historySaveTimer?.cancel();
    _historySaveTimer = Timer.periodic(PlayerConstants.historySaveInterval, (_) {
      if (!mounted) return;
      _saveHistory();
    });
  }

  void _saveHistory() {
    if (widget.mediaPath == null) return;
    final progress = _videoController?.value.position.inSeconds.toDouble() ?? 0;
    final duration = _videoController?.value.duration.inSeconds.toDouble();

    final episode = _mediaFolder?.episodes.elementAtOrNull(_currentEpisodeIndex);

    final effectiveSubtitleContent = _importedSubtitleContent ?? widget.subtitleContent;

    ref.read(listeningHistoryProvider.notifier).recordPlayback(
      mediaPath: widget.mediaPath!,
      mediaName: widget.mediaName ?? widget.mediaPath!.split('/').last,
      subtitlePath: widget.subtitlePath,
      subtitleContent: effectiveSubtitleContent,
      progress: progress,
      duration: duration,
      episodeIndex: _currentEpisodeIndex.toString(),
      episodeTitle: episode?.name,
    );
  }

  Future<void> _playEpisode(int index) async {
    if (_mediaFolder == null || index >= _mediaFolder!.episodes.length) return;
    if (index == _currentEpisodeIndex) return;

    _saveHistory();

    final episode = _mediaFolder!.episodes[index];
    _videoController?.removeListener(_onVideoUpdate);
    _videoController?.dispose();

    if (episode.path.startsWith('blob:') || episode.path.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(episode.path));
    } else {
      _videoController = VideoPlayerController.file(File(episode.path));
    }

    await _videoController!.initialize();
    _videoController!.addListener(_onVideoUpdate);

    String? subtitleContent;
    if (episode.subtitlePath != null) {
      subtitleContent = await MediaScanner.loadSubtitleContent(episode.subtitlePath!);
    }

    if (!mounted) return;

    if (subtitleContent != null) {
      _subtitleCues = _detectCefr(MediaScanner.parseSubtitleForEpisode(subtitleContent, episode.subtitleName ?? ''));
    }

    setState(() {
      _currentEpisodeIndex = index;
    });
    ref.read(isVideoInitializedProvider.notifier).state = true;

    ref.read(playerProvider.notifier).loadSubtitles(_subtitleCues);
    _videoController!.play();
    ref.read(playerProvider.notifier).play();
  }

  void _showEpisodeSelector() {
    if (_mediaFolder == null || _mediaFolder!.episodes.length <= 1) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => EpisodeSelectorDialog(
        mediaFolder: _mediaFolder!,
        currentEpisodeIndex: _currentEpisodeIndex,
        onEpisodeSelected: _playEpisode,
      ),
    );
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

  Future<void> _detectCollocations() async {
    setState(() => _isCollocationDetecting = true);

    try {
      await _collocationDetector.loadDictionary();
      if (!mounted) return;

      setState(() {
        _subtitleCues = _subtitleCues.map((cue) {
          final tokens = _collocationDetector.detect(cue.text);
          return SubtitleCue(
            id: cue.id,
            start: cue.start,
            end: cue.end,
            text: cue.text,
            nativeTranslation: cue.nativeTranslation,
            cefrTokens: cue.cefrTokens,
            collocationTokens: tokens.isEmpty ? null : tokens,
          );
        }).toList();
        _isCollocationDetecting = false;
      });

      ref.read(playerProvider.notifier).loadSubtitles(_subtitleCues);
    } catch (e, st) {
      debugPrint('Collocation detection failed: $e\n$st');
      setState(() => _isCollocationDetecting = false);
    }
  }

  Future<void> _switchToSource(SubtitleSource source) async {
    if (source == ref.read(subtitleSourceProvider)) return;

    if (source == SubtitleSource.ai) {
      await _initializer.switchToSource(source);
      return;
    }

    if (source == SubtitleSource.local) {
      if (widget.subtitleContent != null) {
        _subtitleCues = SubtitleParser.parseFromContent(
          widget.subtitleContent!, widget.subtitleExtension ?? '.srt',
        );
      } else if (widget.subtitlePath != null) {
        final file = File(widget.subtitlePath!);
        final content = await file.readAsString();
        if (!mounted) return;
        final ext = widget.subtitlePath!.toLowerCase();
        final extension = ext.contains('.') ? ext.substring(ext.lastIndexOf('.')) : '.srt';
        _subtitleCues = SubtitleParser.parseFromContent(content, extension);
      }
      _subtitleCues = _detectCefr(_subtitleCues);
      ref.read(subtitleSourceProvider.notifier).state = SubtitleSource.local;
      ref.read(playerProvider.notifier).loadSubtitles(_subtitleCues);
      _detectCollocations();
    }
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    final position = _videoController!.value.position;
    ref.read(playerProvider.notifier).updatePosition(position);

    final playerState = ref.read(playerProvider);
    _checkLoopBoundarySeek(playerState, position);
    _checkSilentSkip(playerState, position);
  }

  void _checkLoopBoundarySeek(PlayerStatus state, Duration position) {
    if (!state.isLooping || state.loopStart == null || state.loopEnd == null) {
      return;
    }
    if (position >= state.loopEnd!) {
      final target = state.loopStart! - state.leadTime;
      final clamped = target < Duration.zero ? Duration.zero : target;
      _videoController?.seekTo(clamped);
    }
  }

  void _checkSilentSkip(PlayerStatus state, Duration position) {
    if (!state.skipSilent || _subtitleCues.isEmpty) return;

    final isInCue = _subtitleCues.any(
      (cue) => position >= cue.start && position <= cue.end,
    );

    if (isInCue) {
      _silenceTimer?.cancel();
      _silenceTimer = null;
      _lastPosition = null;
      return;
    }

    if (_lastPosition == null) {
      _lastPosition = position;
      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(milliseconds: 200), () {
        _performSilentSkip(position);
      });
      return;
    }

    final movedForward = position > _lastPosition!;
    if (!movedForward) {
      _lastPosition = position;
      return;
    }
  }

  void _performSilentSkip(Duration position) {
    if (!mounted) return;
    if (!(_videoController?.value.isPlaying ?? false)) return;
    final playerState = ref.read(playerProvider);
    if (!playerState.skipSilent) return;

    Duration? nextCueStart;
    for (final cue in _subtitleCues) {
      if (cue.start > position) {
        nextCueStart = cue.start;
        break;
      }
    }

    if (nextCueStart != null) {
      _videoController?.seekTo(nextCueStart);
    }
    _lastPosition = null;
  }

  void _handlePlayPause() {
    if (_videoController == null) return;
    final notifier = ref.read(playerProvider.notifier);
    if (_videoController!.value.isPlaying) {
      _videoController!.pause();
      notifier.pause();
    } else {
      _videoController!.play();
      notifier.play();
    }
  }

  void _handleSeek(Duration position) {
    _videoController?.seekTo(position);
  }

  void _handleCueTap(int index) {
    if (index < _subtitleCues.length) {
      final cue = _subtitleCues[index];
      _handleSeek(cue.start);
    }
  }

  void _handlePreviousCue() {
    final activeIndex = ref.read(playerProvider).activeCueIndex;
    if (activeIndex != null && activeIndex > 0) {
      _handleCueTap(activeIndex - 1);
    }
  }

  void _handleNextCue() {
    final activeIndex = ref.read(playerProvider).activeCueIndex;
    if (activeIndex != null && activeIndex < _subtitleCues.length - 1) {
      _handleCueTap(activeIndex + 1);
    }
  }

  void _showVocabularyPanel() {
    final allTokens = _subtitleCues
        .where((c) => c.cefrTokens != null)
        .expand((c) => c.cefrTokens!)
        .toList();

    final flashcardWords =
        ref.read(flashcardWordSetProvider).valueOrNull ?? <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PlatformSpacing.md, vertical: PlatformSpacing.sm),
              child: Row(
                children: [
                  Text('词汇面板',
                      style: PlatformTextStyles.title
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: VocabularyPanel(
                tokens: allTokens,
                onAddToFlashcard: (token) =>
                    _addCefrToFlashcard(token),
                isInFlashcard: (word) =>
                    flashcardWords.contains(word.toLowerCase()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCollocationPanel() {
    final allTokens = _subtitleCues
        .where((c) => c.collocationTokens != null)
        .expand((c) => c.collocationTokens!)
        .toList();

    final flashcardWords =
        ref.read(flashcardWordSetProvider).valueOrNull ?? <String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.25,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PlatformSpacing.md, vertical: PlatformSpacing.sm),
              child: Row(
                children: [
                  if (_isCollocationDetecting)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(width: PlatformSpacing.sm),
                  Text('固定搭配',
                      style: PlatformTextStyles.title
                          .copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isCollocationDetecting
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: PlatformSpacing.md),
                          Text('正在检测固定搭配...',
                              style: TextStyle(
                                  color: ThemeColors.of(context).onSurfaceVariant)),
                        ],
                      ),
                    )
                  : CollocationPanel(
                      tokens: allTokens,
                      onAddToFlashcard: (token) =>
                          _addCollocationToFlashcard(token),
                      isInFlashcard: (text) =>
                          flashcardWords.contains(text.toLowerCase()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _addCefrToFlashcard(CefrToken token) async {
    if (_subtitleCues.isEmpty) return;
    final cue = _subtitleCues.firstWhere(
      (c) => c.cefrTokens?.any((t) => t.word == token.word) ?? false,
      orElse: () => _subtitleCues.first,
    );

    final added = await addFlashcard(
      word: token.word,
      meaning: token.meaning,
      level: token.level,
      originalSentence: cue.text,
      sourceTitle: widget.mediaName ?? 'Bee Video',
      aiService: _aiService,
    );

    if (added) {
      ref.invalidate(flashcardWordSetProvider);
      ref.invalidate(flashcardCountProvider);
      _showFlashcardSnackbar(token.word);
    }
  }

  void _addCollocationToFlashcard(CollocationToken token) async {
    if (_subtitleCues.isEmpty) return;
    final cue = _subtitleCues.firstWhere(
      (c) =>
          c.collocationTokens?.any((t) => t.text == token.text) ?? false,
      orElse: () => _subtitleCues.first,
    );

    final added = await addFlashcard(
      word: token.text,
      meaning: token.meaning,
      level: token.type,
      originalSentence: cue.text,
      sourceTitle: widget.mediaName ?? 'Bee Video',
      aiService: _aiService,
    );

    if (added) {
      ref.invalidate(flashcardWordSetProvider);
      ref.invalidate(flashcardCountProvider);
      _showFlashcardSnackbar(token.text);
    }
  }

  void _showFlashcardSnackbar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('「$text」已添加到闪卡'),
        action: SnackBarAction(
          label: '去复习',
          onPressed: _navigateToFlashcards,
        ),
        behavior: SnackBarBehavior.floating,
        duration: PlayerConstants.snackbarLong,
      ),
    );
  }

  void _toggleFavorite(SubtitleCue cue) async {
    final store = ref.read(favoritesStoreProvider.notifier);
    final isNowFavorited = await store.toggleFavorite(
      text: cue.text,
      type: FavoriteType.sentence,
      context: cue.text,
      cueId: cue.id,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isNowFavorited ? '已收藏' : '已取消收藏'),
        behavior: SnackBarBehavior.floating,
        duration: PlayerConstants.snackbarShort,
      ),
    );
  }

  void _navigateToFlashcards() {
    context.push('/flashcards');
  }

  void _navigateToFavorites() {
    context.push('/favorites');
  }

  Future<void> _importSubtitle() async {
    final result = await _picker.pickSubtitle();
    if (result == null || result.content == null) return;

    final content = result.content!;
    final name = result.name;
    final ext = name.toLowerCase();
    final extension = ext.contains('.') ? ext.substring(ext.lastIndexOf('.')) : '.srt';

    final rawCues = SubtitleParser.parseFromContent(content, extension);
    final cues = rawCues.map((cue) {
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

    if (cues.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未解析到字幕条目，请检查文件格式')),
      );
      return;
    }

    setState(() => _subtitleCues = cues);
    _importedSubtitleContent = content;
    ref.read(playerProvider.notifier).loadSubtitles(cues);
    ref.read(subtitleSourceProvider.notifier).state = SubtitleSource.local;

    _detectCollocations();
    _saveHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入字幕: $name (${cues.length} 条)')),
    );
  }

  Future<void> _translateCurrentCue() async {
    final playerState = ref.read(playerProvider);
    final index = playerState.activeCueIndex;
    if (index == null || index >= _subtitleCues.length) return;

    final cue = _subtitleCues[index];
    final text = cue.text;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('AI 翻译'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: PlatformTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
                color: PlatformColors.primary,
              ),
            ),
            const SizedBox(height: PlatformSpacing.md),
            const Divider(),
            const SizedBox(height: PlatformSpacing.md),
            FutureBuilder<String?>(
              future: _aiService.translate(text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(PlatformSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Text(
                    'AI 服务暂时不可用，请检查后端是否启动',
                    style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant),
                  );
                }
                return Text(
                  snapshot.data!,
                  style: PlatformTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.5,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _detectCollocationsAI() async {
    final playerState = ref.read(playerProvider);
    final index = playerState.activeCueIndex;
    if (index == null || index >= _subtitleCues.length) return;

    final cue = _subtitleCues[index];
    setState(() => _isCollocationDetecting = true);

    try {
      final tokens = await _aiService.detectCollocationsAI(cue.text);
      if (tokens.isNotEmpty && mounted) {
        setState(() {
          _subtitleCues[index] = SubtitleCue(
            id: cue.id,
            start: cue.start,
            end: cue.end,
            text: cue.text,
            nativeTranslation: cue.nativeTranslation,
            cefrTokens: cue.cefrTokens,
            collocationTokens: tokens,
          );
          _isCollocationDetecting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('检测到 ${tokens.length} 个搭配')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('AI collocation detection failed: $e\n$st');
      if (mounted) {
        setState(() => _isCollocationDetecting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI 搭配检测失败，请检查后端是否启动')),
        );
      }
    }
  }

  void _closeLookup() {
    _lookupController?.close();
    _lookupController = null;
    if (mounted) setState(() => _isLookingUp = false);
  }

  void _showWordPopover(String word, String? meaning) {
    if (_isLookingUp) return;

    final store = ref.read(favoritesStoreProvider.notifier);
    final isFav = store.isFavorited(word);

    setState(() => _isLookingUp = true);

    _lookupController = _scaffoldKey.currentState!.showBottomSheet(
      (ctx) => WordLookupDialog(
        word: word,
        aiService: _aiService,
        isFavorited: isFav,
        onToggleFavorite: () {
          store.toggleFavorite(
            text: word,
            type: FavoriteType.word,
          );
          _closeLookup();
        },
        onAddFlashcard: () {
          _addCefrToFlashcard(CefrToken(
            word: word,
            level: '',
            meaning: meaning,
            startIndex: 0,
            endIndex: word.length,
          ));
          _closeLookup();
        },
        onClose: _closeLookup,
      ),
    );

    _lookupController!.closed.whenComplete(() {
      _lookupController = null;
      if (mounted) setState(() => _isLookingUp = false);
    });
  }

  void _showAnyWordPopover(String word) {
    _showWordPopover(word, null);
  }

  void _showTextSelectionDialog(String text) {
    final controller = TextEditingController(text: text);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('选择文本查词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '长按并拖动选择要查询的文本：',
              style: TextStyle(fontSize: 13, color: PlatformColors.gray),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              readOnly: true,
              maxLines: null,
              style: const TextStyle(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final selection = controller.selection;
              String selectedText = text;
              if (selection.isValid && selection.start < selection.end) {
                selectedText = text.substring(selection.start, selection.end);
              }
              Navigator.pop(ctx);
              _showWordPopover(selectedText.trim(), null);
            },
            child: const Text('查询'),
          ),
        ],
      ),
    );
  }

  void _showCollocationPopover(String text, String? meaning) {
    showDialog(
      context: context,
      builder: (ctx) => CollocationPopover(
        text: text,
        meaning: meaning,
        isFavorited: false,
        onToggleFavorite: () => Navigator.pop(ctx),
        onAddFlashcard: () {
          _addCollocationToFlashcard(CollocationToken(
            text: text,
            type: 'phrase',
            meaning: meaning,
            startIndex: 0,
            endIndex: text.length,
          ));
          Navigator.pop(ctx);
        },
        onLookup: () => Navigator.pop(ctx),
      ),
    );
  }

  void _showTutorChat() {
    final playerState = ref.read(playerProvider);
    final activeIndex = playerState.activeCueIndex;
    String currentSubtitle = '';
    final List<String> contextSubtitles = [];

    if (activeIndex != null && activeIndex < _subtitleCues.length) {
      currentSubtitle = _subtitleCues[activeIndex].text;
      for (int i = activeIndex - 2; i <= activeIndex + 2; i++) {
        if (i >= 0 && i < _subtitleCues.length && i != activeIndex) {
          contextSubtitles.add(_subtitleCues[i].text);
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => TutorChatPanel(
          aiService: _aiService,
          currentSubtitle: currentSubtitle,
          contextSubtitles: contextSubtitles,
        ),
      ),
    );
  }

  void _showMemoPanel(SubtitleCue cue) {
    final cueIndex = _subtitleCues.indexOf(cue);
    final meta = cueIndex >= 0
        ? ref.read(memorizationProvider).evaluations[cueIndex]
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _MemoPanelContent(
          cue: cue,
          memorizationMeta: meta,
          aiService: _aiService,
          onPlayClip: () => _playClip(cue),
          onAddToFavorites: () {
            Navigator.pop(ctx);
            _toggleFavorite(cue);
          },
          onAddToAnki: () {
            Navigator.pop(ctx);
            _addCueToAnki(cue);
          },
        );
      },
    );
  }

  void _addCueToAnki(SubtitleCue cue) {
    final cueIndex = _subtitleCues.indexOf(cue);
    final meta = cueIndex >= 0
        ? ref.read(memorizationProvider).evaluations[cueIndex]
        : null;
    final highlights = meta?.highlights ?? [];
    final primaryPhrase = highlights.isNotEmpty ? highlights.first : cue.text;

    addFlashcard(
      word: primaryPhrase,
      meaning: meta?.reason,
      originalSentence: cue.text,
      sourceTitle: widget.mediaName ?? widget.mediaPath,
      aiService: _aiService,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已添加到记忆卡组'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showGrammarPanel(SubtitleCue cue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return _GrammarPanelContent(
          cue: cue,
          aiService: _aiService,
        );
      },
    );
  }

  void _playClip(SubtitleCue cue) {
    Navigator.pop(context);
    _videoController?.seekTo(cue.start);
    _videoController?.play();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    ref.watch(memorizationProvider);

    if (playerState.state == PlayerState.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('英语听力')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: PlatformColors.error),
              const SizedBox(height: PlatformSpacing.md),
              const Text('视频加载失败', style: PlatformTextStyles.title),
              const SizedBox(height: PlatformSpacing.sm),
              Text('请检查网络连接后重试',
                  style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _keyboardHandler.handleKeyEvent,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PlayerAppBar(
          showEpisodeButton: _mediaFolder != null &&
              _mediaFolder!.hasMultipleEpisodes,
          onEpisodeSelect: _showEpisodeSelector,
          onNavigateToFavorites: _navigateToFavorites,
          onNavigateToFlashcards: _navigateToFlashcards,
          onVocabulary: _showVocabularyPanel,
          onCollocation: _showCollocationPanel,
          onImportSubtitle: _importSubtitle,
          onTyping: () => context.push('/typing', extra: {
            'cues': _subtitleCues,
            'mediaPath': widget.mediaPath,
            'mediaName': widget.mediaName,
          }),
          onTranslate: _translateCurrentCue,
          onAICollocation: _detectCollocationsAI,
          onTutorChat: _showTutorChat,
        ),
        body: ErrorBoundary(
          message: '播放器加载失败',
          child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= PlayerConstants.wideLayoutBreakpoint;
            return Column(
              children: [
                Expanded(
                  child: isWide
                      ? PlayerWideLayout(
                          controller: _videoController,
                          isVideoInitialized: ref.watch(isVideoInitializedProvider),
                          wideVideoWidth: _wideVideoWidth,
                          onWideVideoWidthChanged: (v) =>
                              setState(() => _wideVideoWidth = v),
                          cues: _subtitleCues,
                          displayMode: ref.watch(subtitleDisplayModeProvider),
                          onDisplayModeChanged: (m) =>
                              ref.read(subtitleDisplayModeProvider.notifier).state = m,
                          subtitleSource: ref.watch(subtitleSourceProvider),
                          onSourceChanged: _switchToSource,
                          isTranscribing: _isTranscribing,
                          transcribeError: _transcribeError,
                          onCueTap: _handleCueTap,
                          onToggleFavorite: _toggleFavorite,
                          onWordTap: _showWordPopover,
                          onCollocationTap: _showCollocationPopover,
                          onPlayPause: _handlePlayPause,
                          onMemoTap: _showMemoPanel,
                          onGrammarTap: _showGrammarPanel,
                          getMemorizationScore: (index) =>
                              ref.read(memorizationProvider).evaluations[index]?.score,
                          onAnyWordTap: _showAnyWordPopover,
                          onTextSelection: _showTextSelectionDialog,
                        )
                      : PlayerNarrowLayout(
                          controller: _videoController,
                          isVideoInitialized: ref.watch(isVideoInitializedProvider),
                          videoHeight: _videoHeight,
                          onVideoHeightChanged: (v) =>
                              setState(() => _videoHeight = v),
                          cues: _subtitleCues,
                          displayMode: ref.watch(subtitleDisplayModeProvider),
                          onDisplayModeChanged: (m) =>
                              ref.read(subtitleDisplayModeProvider.notifier).state = m,
                          subtitleSource: ref.watch(subtitleSourceProvider),
                          onSourceChanged: _switchToSource,
                          isTranscribing: _isTranscribing,
                          transcribeError: _transcribeError,
                          onCueTap: _handleCueTap,
                          onToggleFavorite: _toggleFavorite,
                          onWordTap: _showWordPopover,
                          onCollocationTap: _showCollocationPopover,
                          onPlayPause: _handlePlayPause,
                          onMemoTap: _showMemoPanel,
                          onGrammarTap: _showGrammarPanel,
                          getMemorizationScore: (index) =>
                              ref.read(memorizationProvider).evaluations[index]?.score,
                          onAnyWordTap: _showAnyWordPopover,
                          onTextSelection: _showTextSelectionDialog,
                        ),
                ),
                ControlBar(
                  playerState: playerState,
                  onPlayPause: _handlePlayPause,
                  onSeek: _handleSeek,
                  onSetLoopStart: () {
                    ref
                        .read(playerProvider.notifier)
                        .setLoopStart(playerState.position);
                  },
                  onSetLoopEnd: () {
                    ref
                        .read(playerProvider.notifier)
                        .setLoopEnd(playerState.position);
                  },
                  onToggleLoop: () {
                    final ok = ref.read(playerProvider.notifier).toggleLoop();
                    if (!ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请先设置起点和终点'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  onClearLoop: () {
                    ref.read(playerProvider.notifier).clearLoop();
                  },
                  onSaveLoop: (label) {
                    final loopStart = playerState.loopStart;
                    final loopEnd = playerState.loopEnd;
                    if (loopStart != null && loopEnd != null) {
                      ref.read(abLoopHistoryProvider.notifier).saveEntry(
                            label: label,
                            pointA: loopStart,
                            pointB: loopEnd,
                          );
                    }
                  },
                  onLoadHistory: (entry) {
                    final notifier = ref.read(playerProvider.notifier);
                    notifier.setLoopStart(entry.pointA);
                    notifier.setLoopEnd(entry.pointB);
                    notifier.toggleLoop();
                  },
                  onSkipSilent: () {
                    final notifier = ref.read(playerProvider.notifier);
                    notifier.toggleSkipSilent();
                  },
                  onPreviousCue: _handlePreviousCue,
                  onNextCue: _handleNextCue,
                  skipSilentEnabled: playerState.skipSilent,
                  loopHistory: ref.watch(abLoopHistoryProvider),
                  playbackSpeed: ref.watch(playbackSpeedProvider),
                  onSpeedChanged: (speed) {
                    ref.read(playbackSpeedProvider.notifier).state = speed;
                    _videoController?.setPlaybackSpeed(speed);
                  },
                ),
              ],
            );
          },
        ),
        ),
      ),
    );
  }
}

class _MemoPanelContent extends StatefulWidget {
  final SubtitleCue cue;
  final MemorizationMeta? memorizationMeta;
  final AIService aiService;
  final VoidCallback? onPlayClip;
  final VoidCallback onAddToFavorites;
  final VoidCallback onAddToAnki;

  const _MemoPanelContent({
    required this.cue,
    this.memorizationMeta,
    required this.aiService,
    this.onPlayClip,
    required this.onAddToFavorites,
    required this.onAddToAnki,
  });

  @override
  State<_MemoPanelContent> createState() => _MemoPanelContentState();
}

class _MemoPanelContentState extends State<_MemoPanelContent> {
  MemoCardTemplate? _template;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateTemplate();
  }

  Future<void> _generateTemplate() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final highlights = widget.memorizationMeta?.highlights ?? [];
      final template = await widget.aiService.generateMemoTemplate(
        text: widget.cue.text,
        highlights: highlights,
      );
      if (mounted) {
        setState(() {
          _template = template;
          _isLoading = false;
          if (template == null) {
            _error = '生成模板失败，请重试';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '生成模板失败，请重试';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('生成模板失败', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateTemplate,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }
    return MemoCardTemplatePanel(
      cue: widget.cue,
      memorizationMeta: widget.memorizationMeta,
      template: _template,
      isLoading: _isLoading,
      onPlayClip: widget.onPlayClip,
      onAddToFavorites: widget.onAddToFavorites,
      onAddToAnki: widget.onAddToAnki,
    );
  }
}

class _GrammarPanelContent extends StatefulWidget {
  final SubtitleCue cue;
  final AIService aiService;

  const _GrammarPanelContent({
    required this.cue,
    required this.aiService,
  });

  @override
  State<_GrammarPanelContent> createState() => _GrammarPanelContentState();
}

class _GrammarPanelContentState extends State<_GrammarPanelContent> {
  GrammarAnalysis? _analysis;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyze();
  }

  Future<void> _analyze() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final analysis = await widget.aiService.analyzeGrammar(widget.cue.text);
      if (mounted) {
        setState(() {
          _analysis = analysis;
          _isLoading = false;
          if (analysis == null) {
            _error = '语法分析失败，请重试';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '语法分析失败，请重试';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GrammarAnalysisPanel(
      cue: widget.cue,
      analysis: _analysis,
      isLoading: _isLoading,
      error: _error,
      onRetry: _analyze,
    );
  }
}