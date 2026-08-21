import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:video_player/video_player.dart';

import '../models/subtitle.dart';
import '../services/ai_service.dart';
import '../services/cefr_detector.dart';
import '../utils/scoring.dart';
import '../widgets/typing/char_diff_view.dart';

class TypingScreen extends ConsumerStatefulWidget {
  final List<SubtitleCue>? cues;
  final String? mediaPath;
  final String? mediaName;

  const TypingScreen({
    super.key,
    this.cues,
    this.mediaPath,
    this.mediaName,
  });

  @override
  ConsumerState<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends ConsumerState<TypingScreen> {
  VideoPlayerController? _videoController;
  final CefrDetector _cefrDetector = CefrDetector();
  final AIService _aiService = AIService(getToken: () => 'mock-token');
  bool _isVideoInitialized = false;
  String? _initError;
  List<SubtitleCue> _cues = [];

  int _cueIndex = 0;
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();

  TypingResult? _result;
  bool _showSuccessBurst = false;
  Timer? _debounceTimer;
  bool _isPlaying = false;

  int _typingLeadMs = 200;

  final List<MistakeRecord> _mistakeHistory = [];
  bool _isAnalyzing = false;
  MistakeAnalysis? _analysis;
  List<DictationSentence>? _adaptiveSentences;
  bool _isGeneratingDictation = false;

  static const _sampleVideoUrl =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

  static final _sampleSubtitles = [
    SubtitleCue(
      id: '1',
      start: const Duration(seconds: 0, milliseconds: 500),
      end: const Duration(seconds: 2, milliseconds: 500),
      text: 'When a bee finds a good flower full of nectar,',
    ),
    SubtitleCue(
      id: '2',
      start: const Duration(seconds: 2, milliseconds: 800),
      end: const Duration(seconds: 5, milliseconds: 200),
      text: 'it flies back to the hive and tells the other bees.',
    ),
    SubtitleCue(
      id: '3',
      start: const Duration(seconds: 5, milliseconds: 500),
      end: const Duration(seconds: 8, milliseconds: 0),
      text: 'The bee does a special dance to show the direction and distance.',
    ),
    SubtitleCue(
      id: '4',
      start: const Duration(seconds: 8, milliseconds: 300),
      end: const Duration(seconds: 11, milliseconds: 0),
      text: 'The other bees watch the dance and then fly to the flowers.',
    ),
  ];

  SubtitleCue? get _currentCue {
    if (_cues.isEmpty || _cueIndex >= _cues.length) return null;
    return _cues[_cueIndex];
  }

  bool _isCueEmptyOrPunctuation(String text) {
    final cleaned = ScoringUtils.normalizeForCompare(text);
    return cleaned.isEmpty;
  }

  List<SubtitleCue> get _validCues =>
      _cues.where((c) => !_isCueEmptyOrPunctuation(c.text)).toList();

  int get _validCueCount => _validCues.length;

  int get _validCueIndex {
    final current = _currentCue;
    if (current == null) return 0;
    return _validCues.indexOf(current).clamp(0, _validCueCount - 1);
  }

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      await _cefrDetector.loadDictionary();

      if (widget.cues != null && widget.cues!.isNotEmpty) {
        _cues = _detectCefr(widget.cues!);
      } else {
        _cues = _detectCefr(_sampleSubtitles);
      }

      _skipToFirstValidCue();

      if (widget.mediaPath != null) {
        if (widget.mediaPath!.startsWith('blob:') || widget.mediaPath!.startsWith('http')) {
          _videoController = VideoPlayerController.networkUrl(
            Uri.parse(widget.mediaPath!),
          );
        } else {
          _videoController = VideoPlayerController.file(File(widget.mediaPath!));
        }
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(_sampleVideoUrl),
        );
      }

      await _videoController!.initialize();
      if (mounted) setState(() => _isVideoInitialized = true);
      if (mounted) _playCurrentCue();
    } catch (e, st) {
      debugPrint('[TypingScreen] init video failed: $e\n$st');
      if (mounted) setState(() => _initError = '视频加载失败，请检查文件或网络连接');
    }
  }

  void _skipToFirstValidCue() {
    for (int i = 0; i < _cues.length; i++) {
      if (!_isCueEmptyOrPunctuation(_cues[i].text)) {
        _cueIndex = i;
        return;
      }
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
        cefrTokens: tokens.isEmpty ? null : tokens,
      );
    }).toList();
  }

  Future<void> _playCurrentCue() async {
    final cue = _currentCue;
    if (cue == null || _videoController == null) return;

    final leadMs = _typingLeadMs.toDouble();
    final leadDuration = Duration(milliseconds: leadMs.toInt());
    final startPos = cue.start - leadDuration;
    final clampedStart = startPos < Duration.zero ? Duration.zero : startPos;

    if (cue.start == cue.end) {
      _inputFocusNode.requestFocus();
      return;
    }

    setState(() => _isPlaying = true);

    await _videoController!.seekTo(clampedStart);
    await _videoController!.play();

    final playDuration = cue.end - clampedStart;
    await Future.delayed(playDuration);
    if (mounted && _videoController != null) {
      await _videoController!.pause();
      setState(() => _isPlaying = false);
      _inputFocusNode.requestFocus();
    }
  }

  void _submitAnswer() {
    final cue = _currentCue;
    if (cue == null) return;

    if (_debounceTimer?.isActive == true) return;
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {});

    final typed = _inputController.text;
    final accuracy = ScoringUtils.calcAccuracy(cue.text, typed);
    final perfect = accuracy == 100.0;
    final diffs = perfect ? null : ScoringUtils.buildCharDiff(cue.text, typed);

    if (!perfect) {
      _mistakeHistory.add(MistakeRecord(
        expected: cue.text,
        typed: typed,
        accuracy: accuracy,
      ));
    }

    setState(() {
      _result = TypingResult(
        accuracy: accuracy,
        expected: cue.text,
        typed: typed,
        diffs: diffs,
        perfect: perfect,
      );
      if (perfect) {
        _showSuccessBurst = true;
      }
    });

    if (perfect) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _showSuccessBurst = false);
      });
    }
  }

  void _goTo(int delta) {
    final validIdx = _validCueIndex;
    final newValidIdx = validIdx + delta;
    if (newValidIdx < 0 || newValidIdx >= _validCueCount) return;

    final targetCue = _validCues[newValidIdx];
    final realIndex = _cues.indexOf(targetCue);

    setState(() {
      _cueIndex = realIndex;
      _result = null;
      _showSuccessBurst = false;
      _inputController.clear();
    });

    _playCurrentCue();
  }

  void _replayCurrentCue() {
    setState(() {
      _result = null;
      _showSuccessBurst = false;
      _inputController.clear();
    });
    _playCurrentCue();
  }

  Future<void> _analyzeMistakes() async {
    if (_mistakeHistory.isEmpty) {
      _showEmptyAnalysis();
      return;
    }

    setState(() => _isAnalyzing = true);

    final analysis = await _aiService.analyzeMistakes(_mistakeHistory);

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      _analysis = analysis;
    });
  }

  Future<void> _generateAdaptiveDictation() async {
    setState(() => _isGeneratingDictation = true);

    final patterns = _analysis?.patterns.map((p) => p.type).toList() ?? [];
    final sourceSentences = _cues.map((c) => c.text).toList();

    final sentences = await _aiService.generateDictation(
      sourceSentences: sourceSentences,
      weakPatterns: patterns,
      count: 5,
    );

    if (!mounted) return;

    setState(() {
      _isGeneratingDictation = false;
      _adaptiveSentences = sentences;
    });
  }

  void _showEmptyAnalysis() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('练习完成 🎉'),
        content: const Text('太棒了！你全部答对了，没有发现薄弱点。继续保持！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }

  void _showSessionComplete() {
    if (_isAnalyzing) {
      _showAnalysisDialog();
      return;
    }

    if (_analysis == null) {
      _analyzeMistakes().then((_) {
        if (mounted && _analysis != null) {
          _showAnalysisDialog();
        }
      });
      return;
    }

    _showAnalysisDialog();
  }

  void _showAnalysisDialog() {
    final isAnalyzing = _isAnalyzing;
    final analysis = _analysis;
    final adaptiveSentences = _adaptiveSentences;
    final isGenerating = _isGeneratingDictation;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.analytics, color: PlatformColors.primary),
                const SizedBox(width: PlatformSpacing.sm),
                const Expanded(
                  child: Text('练习报告', style: PlatformTextStyles.title),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSessionStats(),
                  const SizedBox(height: PlatformSpacing.md),
                  if (isAnalyzing)
                    _buildLoadingSection('正在分析你的错误模式...')
                  else if (analysis != null) ...[
                    _buildAnalysisSection(analysis),
                    const SizedBox(height: PlatformSpacing.md),
                    if (adaptiveSentences != null)
                      _buildAdaptiveSection(adaptiveSentences)
                    else if (isGenerating)
                      _buildLoadingSection('正在生成专属练习...')
                    else
                      _buildGenerateButton(),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('关闭'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _resetSession();
                },
                child: const Text('重新开始'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionStats() {
    final total = _validCueCount;
    final mistakes = _mistakeHistory.length;
    final correct = total - mistakes;
    final avgAccuracy = mistakes > 0
        ? _mistakeHistory.fold(0.0, (sum, m) => sum + m.accuracy) / mistakes
        : 100.0;

    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text('本次练习', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: PlatformSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总题数', '$total'),
              _buildStatItem('正确', '$correct', PlatformColors.green),
              _buildStatItem('错误', '$mistakes',
                  mistakes > 0 ? PlatformColors.red : PlatformColors.green),
              _buildStatItem('均分', '${avgAccuracy.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, [Color? color]) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color ?? ThemeColors.of(context).onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ThemeColors.of(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.lg),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: PlatformSpacing.md),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisSection(MistakeAnalysis analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, size: 18, color: PlatformColors.amber),
            const SizedBox(width: PlatformSpacing.xs),
            const Text('AI 分析', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: PlatformSpacing.sm),
        if (analysis.patterns.isEmpty)
          Text(
            '没有发现明显的错误模式，你的表现很稳定！',
            style: TextStyle(
              fontSize: 13,
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          )
        else
          ...analysis.patterns.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: PlatformSpacing.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(PlatformSpacing.sm),
                  decoration: BoxDecoration(
                    color: PlatformColors.amber.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PlatformColors.amber.withAlpha(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.description,
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (p.examples.isNotEmpty) ...[
                        const SizedBox(height: PlatformSpacing.xs),
                        Text(
                          '示例: ${p.examples.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.of(context).onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )),
        if (analysis.suggestions.isNotEmpty) ...[
          const SizedBox(height: PlatformSpacing.sm),
          Row(
            children: [
              const Icon(Icons.tips_and_updates, size: 18, color: PlatformColors.primary),
              const SizedBox(width: PlatformSpacing.xs),
              const Text('建议', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: PlatformSpacing.xs),
          ...analysis.suggestions.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: PlatformSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(s, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          _generateAdaptiveDictation().then((_) {
            if (mounted) {
              _showAnalysisDialog();
            }
          });
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('生成专属练习'),
        style: ElevatedButton.styleFrom(
          backgroundColor: PlatformColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildAdaptiveSection(List<DictationSentence> sentences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center, size: 18, color: PlatformColors.green),
            const SizedBox(width: PlatformSpacing.xs),
            const Text('专属练习', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: PlatformSpacing.sm),
        ...sentences.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: PlatformSpacing.xs),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PlatformSpacing.sm),
              decoration: BoxDecoration(
                color: PlatformColors.green.withAlpha(10),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: PlatformColors.green.withAlpha(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${i + 1}. ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: ThemeColors.of(context).onSurfaceVariant,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PlatformColors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          s.focusPattern,
                          style: const TextStyle(
                            fontSize: 10,
                            color: PlatformColors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PlatformSpacing.xs),
                  Text(
                    s.text,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _resetSession() {
    setState(() {
      _cueIndex = 0;
      _result = null;
      _showSuccessBurst = false;
      _inputController.clear();
      _mistakeHistory.clear();
      _analysis = null;
      _adaptiveSentences = null;
    });
    _skipToFirstValidCue();
    _playCurrentCue();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isPlaying) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _goTo(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _goTo(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (_result != null) {
        _goTo(1);
      } else {
        _submitAnswer();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _replayCurrentCue();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    _videoController?.removeListener(() {});
    _videoController?.dispose();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('打字练习'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PlatformColors.error),
              const SizedBox(height: 16),
              Text(_initError!, style: PlatformTextStyles.body),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() => _initError = null);
                  _initAll();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final cue = _currentCue;

    return Focus(
      focusNode: _inputFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('打字练习'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildVideoArea(),
            _buildProgressBar(),
            _buildLeadTimeSlider(),
            _buildCueInfo(cue),
            _buildResultArea(),
            _buildInputArea(),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 200,
        color: PlatformColors.gray.withAlpha(30),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '第 ${_validCueIndex + 1} / $_validCueCount 句',
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                ),
              ),
              if (_isPlaying)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '播放中...',
                      style: PlatformTextStyles.caption.copyWith(
                        color: PlatformColors.primary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: _validCueCount > 0 ? (_validCueIndex + 1) / _validCueCount : 0,
            backgroundColor: PlatformColors.gray.withAlpha(30),
            valueColor: AlwaysStoppedAnimation(PlatformColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadTimeSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: Row(
        children: [
          Text(
            '提前量',
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Slider(
              value: _typingLeadMs.toDouble(),
              min: 0,
              max: 500,
              divisions: 10,
              label: '${_typingLeadMs}ms',
              onChanged: (v) {
                setState(() => _typingLeadMs = v.round());
              },
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              '${_typingLeadMs}ms',
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            onPressed: _replayCurrentCue,
            icon: const Icon(Icons.replay, size: 18),
            tooltip: '重播当前句',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildCueInfo(SubtitleCue? cue) {
    if (_result == null || cue == null) {
      return const SizedBox(height: 8);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: Text(
        cue.text,
        style: PlatformTextStyles.body.copyWith(
          color: ThemeColors.of(context).onSurface,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildResultArea() {
    if (_result == null) return const SizedBox.shrink();

    if (_showSuccessBurst) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
        child: Container(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          decoration: BoxDecoration(
            color: PlatformColors.green.withAlpha(30),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: PlatformColors.green),
              const SizedBox(width: PlatformSpacing.sm),
              Text(
                '完美！100%',
                style: PlatformTextStyles.title.copyWith(
                  color: PlatformColors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final diffs = _result!.diffs;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: Column(
        children: [
          Text(
            '准确率: ${_result!.accuracy.toStringAsFixed(1)}%',
            style: PlatformTextStyles.title.copyWith(
              color: _result!.accuracy >= 80
                  ? PlatformColors.green
                  : _result!.accuracy >= 50
                      ? PlatformColors.amber
                      : PlatformColors.red,
            ),
          ),
          const SizedBox(height: PlatformSpacing.sm),
          if (diffs != null) CharDiffView(diffs: diffs),
          const SizedBox(height: PlatformSpacing.sm),
          Text(
            '标准答案: ${_result!.expected}',
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          ),
          Text(
            '你的输入: ${_result!.typed}',
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      child: TextField(
        controller: _inputController,
        focusNode: _inputFocusNode,
        onSubmitted: _result != null ? (_) => _goTo(1) : (_) => _submitAnswer(),
        enabled: !_isPlaying,
        decoration: InputDecoration(
          hintText: _isPlaying ? '正在播放音频...' : '输入你听到的内容...',
          border: const OutlineInputBorder(),
          suffixIcon: _isPlaying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : const Icon(Icons.keyboard),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildActions() {
    final canGoPrev = _validCueIndex > 0;
    final canGoNext = _validCueIndex < _validCueCount - 1;
    final isLast = _validCueIndex >= _validCueCount - 1;
    final hasResult = _result != null;

    return Padding(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: !_isPlaying && canGoPrev ? () => _goTo(-1) : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('上一句'),
          ),
          if (isLast && hasResult)
            ElevatedButton.icon(
              onPressed: _showSessionComplete,
              icon: const Icon(Icons.flag),
              label: const Text('完成练习'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PlatformColors.green,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isPlaying
                  ? null
                  : hasResult
                      ? canGoNext
                          ? () => _goTo(1)
                          : null
                      : _inputController.text.isNotEmpty
                          ? _submitAnswer
                          : null,
              icon: Icon(hasResult ? Icons.arrow_forward : Icons.check),
              label: Text(hasResult ? '下一句' : '检查'),
              style: ElevatedButton.styleFrom(
                backgroundColor: PlatformColors.primary,
                foregroundColor: PlatformColors.onPrimary,
              ),
            ),
          TextButton.icon(
            onPressed: !_isPlaying && canGoNext ? () => _goTo(1) : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('下一句'),
          ),
        ],
      ),
    );
  }
}

class TypingResult {
  final double accuracy;
  final String expected;
  final String typed;
  final List<CharDiff>? diffs;
  final bool perfect;

  const TypingResult({
    required this.accuracy,
    required this.expected,
    required this.typed,
    this.diffs,
    this.perfect = false,
  });
}