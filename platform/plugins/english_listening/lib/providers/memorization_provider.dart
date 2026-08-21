import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/subtitle.dart';
import '../services/memorization_scorer.dart';
import '../services/ai_service.dart';

class MemorizationState {
  final Map<int, MemorizationMeta> evaluations;
  final int totalLines;
  final int aiCompleted;
  final bool isAiAnalyzing;
  final String? aiError;

  const MemorizationState({
    this.evaluations = const {},
    this.totalLines = 0,
    this.aiCompleted = 0,
    this.isAiAnalyzing = false,
    this.aiError,
  });

  MemorizationState copyWith({
    Map<int, MemorizationMeta>? evaluations,
    int? totalLines,
    int? aiCompleted,
    bool? isAiAnalyzing,
    String? aiError,
    bool clearAiError = false,
  }) {
    return MemorizationState(
      evaluations: evaluations ?? this.evaluations,
      totalLines: totalLines ?? this.totalLines,
      aiCompleted: aiCompleted ?? this.aiCompleted,
      isAiAnalyzing: isAiAnalyzing ?? this.isAiAnalyzing,
      aiError: clearAiError ? null : (aiError ?? this.aiError),
    );
  }
}

class MemorizationNotifier extends StateNotifier<MemorizationState> {
  final MemorizationScorer _scorer = MemorizationScorer();
  final AIService? _aiService;
  Timer? _analysisTimer;
  bool _isCancelled = false;

  MemorizationNotifier(this._aiService) : super(const MemorizationState());

  void loadCues(List<SubtitleCue> cues) {
    _isCancelled = false;
    _analysisTimer?.cancel();

    final metas = _scorer.evaluateAll(cues);
    final evaluations = <int, MemorizationMeta>{};
    for (int i = 0; i < metas.length; i++) {
      evaluations[i] = metas[i];
    }

    state = MemorizationState(
      evaluations: evaluations,
      totalLines: cues.length,
      aiCompleted: 0,
      isAiAnalyzing: false,
    );

    if (_aiService != null && cues.isNotEmpty) {
      _startBackgroundAnalysis(cues);
    }
  }

  void _startBackgroundAnalysis(List<SubtitleCue> cues) {
    if (_aiService == null) return;

    state = state.copyWith(isAiAnalyzing: true);

    _analysisTimer = Timer(const Duration(milliseconds: 100), () {
      _processChunk(cues, 0);
    });
  }

  Future<void> _processChunk(List<SubtitleCue> cues, int startIndex) async {
    if (_isCancelled || _aiService == null) return;

    const chunkSize = 20;
    final endIndex = (startIndex + chunkSize).clamp(0, cues.length);

    final lines = <Map<String, dynamic>>[];
    for (int i = startIndex; i < endIndex; i++) {
      lines.add({'index': i, 'text': cues[i].text});
    }

    try {
      final results = await _aiService.evaluateChunk(lines);
      if (_isCancelled || results == null) return;

      final newEvaluations = Map<int, MemorizationMeta>.from(state.evaluations);
      for (final result in results) {
        final idx = result.index;
        if (idx == null) continue;
        final existing = newEvaluations[idx];
        newEvaluations[idx] = MemorizationMeta(
          score: result.score,
          reason: result.reason ?? existing?.reason,
          highlights:
              result.highlights.isNotEmpty ? result.highlights : existing?.highlights ?? [],
          scenario: result.scenario ?? existing?.scenario,
          isAiEnhanced: true,
        );
      }

      state = state.copyWith(
        evaluations: newEvaluations,
        aiCompleted: endIndex,
      );

      if (endIndex < cues.length) {
        _analysisTimer = Timer(const Duration(milliseconds: 200), () {
          _processChunk(cues, endIndex);
        });
      } else {
        state = state.copyWith(isAiAnalyzing: false);
      }
    } catch (e, st) {
      debugPrint('[MemorizationNotifier] chunk failed: $e\n$st');
      if (endIndex < cues.length) {
        _analysisTimer = Timer(const Duration(seconds: 2), () {
          _processChunk(cues, endIndex);
        });
      } else {
        state = state.copyWith(isAiAnalyzing: false);
      }
    }
  }

  MemorizationMeta? getEvaluation(int index) {
    return state.evaluations[index];
  }

  void cancel() {
    _isCancelled = true;
    _analysisTimer?.cancel();
    state = state.copyWith(isAiAnalyzing: false);
  }

  @override
  void dispose() {
    cancel();
    super.dispose();
  }
}

final memorizationProvider =
    StateNotifierProvider<MemorizationNotifier, MemorizationState>(
  (ref) {
    final aiService = AIService(getToken: () => 'mock-token');
    return MemorizationNotifier(aiService);
  },
);