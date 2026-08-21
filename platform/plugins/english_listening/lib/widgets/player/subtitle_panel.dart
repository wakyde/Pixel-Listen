import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';

class SubtitlePanel extends StatefulWidget {
  final List<SubtitleCue> cues;
  final int? activeCueIndex;
  final Duration position;
  final double subtitleHeight;
  final SubtitleDisplayMode displayMode;
  final void Function(int index)? onCueTap;
  final bool Function(String text)? isFavorited;
  final void Function(SubtitleCue cue)? onToggleFavorite;
  final void Function(SubtitleCue cue)? onMemoTap;
  final void Function(SubtitleCue cue)? onGrammarTap;
  final double? Function(int index)? getMemorizationScore;
  final void Function(String word, String? meaning)? onWordTap;
  final void Function(String text, String? meaning)? onCollocationTap;
  final void Function(String word)? onAnyWordTap;
  final void Function(String text)? onTextSelection;

  const SubtitlePanel({
    super.key,
    required this.cues,
    this.activeCueIndex,
    this.position = Duration.zero,
    this.subtitleHeight = 160,
    this.displayMode = SubtitleDisplayMode.english,
    this.onCueTap,
    this.isFavorited,
    this.onToggleFavorite,
    this.onMemoTap,
    this.onGrammarTap,
    this.getMemorizationScore,
    this.onWordTap,
    this.onCollocationTap,
    this.onAnyWordTap,
    this.onTextSelection,
  });

  @override
  State<SubtitlePanel> createState() => _SubtitlePanelState();
}

class _SubtitlePanelState extends State<SubtitlePanel> {
  final ScrollController _scrollController = ScrollController();
  static const _itemHeight = 52.0;

  static const _levelColors = {
    'A1': Color(0xFF22C55E),
    'A2': Color(0xFF10B981),
    'B1': Color(0xFF3B82F6),
    'B2': Color(0xFF8B5CF6),
    'C1': Color(0xFFF97316),
    'C2': Color(0xFFEF4444),
  };

  static const _collocationColors = {
    'phrasalVerb': Color(0xFFF59E0B),
    'prepositionalPhrase': Color(0xFFF97316),
    'nounPhrase': Color(0xFF14B8A6),
    'adjectivePhrase': Color(0xFF0EA5E9),
    'idiom': Color(0xFFA855F7),
    'phrase': Color(0xFF6366F1),
  };

  @override
  void didUpdateWidget(SubtitlePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeCueIndex != oldWidget.activeCueIndex &&
        widget.activeCueIndex != null) {
      _scrollToActive();
    }
  }

  void _scrollToActive() {
    if (!_scrollController.hasClients) return;
    final index = widget.activeCueIndex;
    if (index == null) return;

    final viewportHeight = _scrollController.position.viewportDimension;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target = (index * _itemHeight) - (viewportHeight / 2) + (_itemHeight / 2);
    final clamped = target.clamp(0.0, maxExtent);
    _scrollController.animateTo(
      clamped,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: widget.subtitleHeight),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).background,
        border: Border(
          top: BorderSide(color: ThemeColors.of(context).outline),
        ),
      ),
      child: widget.cues.isEmpty
          ? Center(
              child: Text(
                '暂无字幕',
                style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant),
              ),
            )
          : Column(
              children: [
                _buildProgressBar(),
                const Divider(height: 1),
                Expanded(child: _buildSubtitleList()),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    final totalDuration = widget.cues.isNotEmpty
        ? widget.cues.last.end
        : const Duration(seconds: 1);
    final progress = totalDuration.inMilliseconds > 0
        ? widget.position.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        return SizedBox(
          height: 24,
          child: Stack(
            children: [
              for (int i = 0; i < widget.cues.length; i++)
                _buildCueSegment(widget.cues[i], totalDuration, barWidth, i),
              Positioned(
                left: progress * barWidth - 1,
                child: Container(
                  width: 2,
                  height: 24,
                  color: PlatformColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCueSegment(
      SubtitleCue cue, Duration total, double barWidth, int index) {
    final left = cue.start.inMilliseconds / total.inMilliseconds * barWidth;
    final width = (cue.end.inMilliseconds - cue.start.inMilliseconds) /
        total.inMilliseconds *
        barWidth;
    final isActive = index == widget.activeCueIndex;

    return Positioned(
      left: left,
      width: width.clamp(2.0, barWidth),
      child: Container(
        height: 24,
        color: isActive
            ? PlatformColors.primary.withAlpha(60)
            : ThemeColors.of(context).outline.withAlpha(40),
      ),
    );
  }

  Widget _buildSubtitleList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: widget.cues.length,
      itemExtent: _itemHeight,
      itemBuilder: (context, index) {
        final cue = widget.cues[index];
        final isActive = index == widget.activeCueIndex;
        return _buildCueRow(cue, index, isActive);
      },
    );
  }

  Widget _buildCueRow(SubtitleCue cue, int index, bool isActive) {
    final displayText = _getDisplayText(cue);
    if (displayText == null) return const SizedBox.shrink();

    final showRichTokens = widget.displayMode == SubtitleDisplayMode.english;
    final score = widget.getMemorizationScore?.call(index);

    return GestureDetector(
      key: ValueKey('cue_${index}_${score?.toStringAsFixed(1) ?? 'none'}'),
      onTap: widget.onCueTap != null ? () => widget.onCueTap!(index) : null,
      onLongPress: widget.onTextSelection != null
          ? () => widget.onTextSelection!(cue.text)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PlatformSpacing.md,
          vertical: PlatformSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? PlatformColors.primary.withAlpha(25)
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: ThemeColors.of(context).outline.withAlpha(30),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Text(
                _formatTime(cue.start),
                style: PlatformTextStyles.caption.copyWith(
                  color: isActive
                      ? PlatformColors.primary
                      : ThemeColors.of(context).onSurfaceVariant,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: PlatformSpacing.sm),
            Expanded(
              child: showRichTokens
                  ? _buildRichCueText(cue, isActive)
                  : _buildPlainCueText(displayText, isActive),
            ),
            if (widget.onGrammarTap != null) _buildGrammarButton(cue),
            if (widget.onMemoTap != null) _buildMemoButton(cue, index, score),
            if (widget.onToggleFavorite != null)
              _buildFavoriteButton(cue),
          ],
        ),
      ),
    );
  }

  String? _getDisplayText(SubtitleCue cue) {
    switch (widget.displayMode) {
      case SubtitleDisplayMode.hidden:
        return null;
      case SubtitleDisplayMode.native:
        return cue.nativeTranslation ?? cue.text;
      case SubtitleDisplayMode.bilingual:
        final en = cue.text;
        final native = cue.nativeTranslation;
        if (native != null && native.isNotEmpty) {
          return '$en\n$native';
        }
        return en;
      case SubtitleDisplayMode.english:
        return cue.text;
    }
  }

  Widget _buildGrammarButton(SubtitleCue cue) {
    return SizedBox(
      width: 44,
      child: InkWell(
        onTap: () => widget.onGrammarTap?.call(cue),
        borderRadius: BorderRadius.circular(6),
        child: const Icon(Icons.menu_book, size: 16, color: PlatformColors.gray),
      ),
    );
  }

  Widget _buildMemoButton(SubtitleCue cue, int index, double? score) {
    return SizedBox(
      width: 44,
      child: InkWell(
        onTap: () => widget.onMemoTap?.call(cue),
        borderRadius: BorderRadius.circular(6),
        child: score != null
            ? _buildScoreChip(score)
            : const Icon(Icons.add_circle_outline, size: 16, color: PlatformColors.gray),
      ),
    );
  }

  Widget _buildScoreChip(double score) {
    final color = score >= 7
        ? const Color(0xFF22C55E)
        : score >= 5
            ? const Color(0xFFF59E0B)
            : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        score.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(SubtitleCue cue) {
    return SizedBox(
      width: 32,
      child: IconButton(
        icon: Icon(
          (widget.isFavorited?.call(cue.text) ?? false)
              ? Icons.star
              : Icons.star_border,
          color: (widget.isFavorited?.call(cue.text) ?? false)
              ? const Color(0xFFF59E0B)
              : PlatformColors.gray,
          size: 16,
        ),
        onPressed: () => widget.onToggleFavorite!(cue),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildPlainCueText(String text, bool isActive) {
    return Text(
      text,
      style: PlatformTextStyles.body.copyWith(
        color: isActive
            ? ThemeColors.of(context).onSurface
            : ThemeColors.of(context).onSurfaceVariant,
        height: 1.3,
        fontSize: 13,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRichCueText(SubtitleCue cue, bool isActive) {
    final sourceText = cue.text;
    final tokens = _mergeTokens(cue);

    final Map<int, _SpanToken> charTokenMap = {};
    for (final token in tokens) {
      for (int i = token.startIndex; i < token.endIndex; i++) {
        charTokenMap[i] = token;
      }
    }

    final spans = <TextSpan>[];
    final wordPattern = RegExp(r"[a-zA-Z'-]+");
    int lastEnd = 0;

    for (final match in wordPattern.allMatches(sourceText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: sourceText.substring(lastEnd, match.start),
          style: _defaultTextStyle(isActive),
        ));
      }

      final wordText = match.group(0)!;
      final token = charTokenMap[match.start];

      if (token != null && token.isCollocation) {
        final color = _getTokenColor(token);
        spans.add(TextSpan(
          text: wordText,
          style: TextStyle(
            color: color,
            fontSize: 13,
            height: 1.3,
            decoration: TextDecoration.underline,
            decorationColor: color,
            fontWeight: FontWeight.w600,
          ),
          recognizer: _buildTapRecognizer(token, sourceText),
        ));
      } else if (token != null && token.cefrLevel != null) {
        final color = _getTokenColor(token);
        spans.add(TextSpan(
          text: wordText,
          style: TextStyle(
            color: color,
            fontSize: 13,
            height: 1.3,
            fontWeight: FontWeight.w600,
          ),
          recognizer: _buildTapRecognizer(token, sourceText),
        ));
      } else {
        spans.add(TextSpan(
          text: wordText,
          style: _defaultTextStyle(isActive),
          recognizer: widget.onAnyWordTap != null
              ? (TapGestureRecognizer()
                ..onTap = () => widget.onAnyWordTap!(wordText))
              : null,
        ));
      }

      lastEnd = match.end;
    }

    if (lastEnd < sourceText.length) {
      spans.add(TextSpan(
        text: sourceText.substring(lastEnd),
        style: _defaultTextStyle(isActive),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  TextStyle _defaultTextStyle(bool isActive) {
    return TextStyle(
      color: isActive
          ? ThemeColors.of(context).onSurface
          : ThemeColors.of(context).onSurfaceVariant,
      fontSize: 13,
      height: 1.3,
    );
  }

  String _formatTime(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  List<_SpanToken> _mergeTokens(SubtitleCue cue) {
    final tokens = <_SpanToken>[];

    if (cue.collocationTokens != null) {
      for (final ct in cue.collocationTokens!) {
        tokens.add(_SpanToken(
          startIndex: ct.startIndex,
          endIndex: ct.endIndex,
          isCollocation: true,
          collocationType: ct.type,
          collocationMeaning: ct.meaning,
        ));
      }
    }

    if (cue.cefrTokens != null) {
      for (final cefr in cue.cefrTokens!) {
        final isCoveredByCollocation = tokens.any((t) =>
            t.isCollocation &&
            t.startIndex <= cefr.startIndex &&
            t.endIndex >= cefr.endIndex);
        if (!isCoveredByCollocation) {
          tokens.add(_SpanToken(
            startIndex: cefr.startIndex,
            endIndex: cefr.endIndex,
            isCollocation: false,
            cefrLevel: cefr.level,
            cefrMeaning: cefr.meaning,
          ));
        }
      }
    }

    tokens.sort((a, b) => a.startIndex.compareTo(b.startIndex));

    final merged = <_SpanToken>[];
    for (final token in tokens) {
      if (merged.isEmpty) {
        merged.add(token);
        continue;
      }

      final last = merged.last;
      if (token.startIndex >= last.endIndex) {
        merged.add(token);
      } else if (token.endIndex > last.endIndex) {
        merged.add(_SpanToken(
          startIndex: last.endIndex,
          endIndex: token.endIndex,
          isCollocation: token.isCollocation,
          cefrLevel: token.cefrLevel,
          cefrMeaning: token.cefrMeaning,
          collocationType: token.collocationType,
          collocationMeaning: token.collocationMeaning,
        ));
      }
    }

    return merged;
  }

  Color _getTokenColor(_SpanToken token) {
    if (token.isCollocation) {
      return _collocationColors[token.collocationType] ?? const Color(0xFF6366F1);
    }
    if (token.cefrLevel != null) {
      return _levelColors[token.cefrLevel] ?? PlatformColors.gray;
    }
    return ThemeColors.of(context).onSurface;
  }

  TapGestureRecognizer? _buildTapRecognizer(_SpanToken token, String fullText) {
    final tokenText = fullText.substring(token.startIndex, token.endIndex);
    if (token.isCollocation && widget.onCollocationTap != null) {
      return (TapGestureRecognizer()
        ..onTap = () {
          widget.onCollocationTap!(tokenText, token.collocationMeaning);
        });
    }
    if (!token.isCollocation && token.cefrLevel != null && widget.onWordTap != null) {
      return (TapGestureRecognizer()
        ..onTap = () {
          widget.onWordTap!(tokenText, token.cefrMeaning);
        });
    }
    return null;
  }
}

class _SpanToken {
  final int startIndex;
  final int endIndex;
  final bool isCollocation;
  final String? cefrLevel;
  final String? cefrMeaning;
  final String? collocationType;
  final String? collocationMeaning;

  const _SpanToken({
    required this.startIndex,
    required this.endIndex,
    required this.isCollocation,
    this.cefrLevel,
    this.cefrMeaning,
    this.collocationType,
    this.collocationMeaning,
  });
}