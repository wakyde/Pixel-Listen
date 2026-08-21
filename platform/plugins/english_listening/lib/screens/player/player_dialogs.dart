import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../services/media_scanner.dart';
import '../../services/ai_service.dart';
import '../../services/tts_service.dart';

import '../../models/subtitle.dart';

class EpisodeSelectorDialog extends StatelessWidget {
  const EpisodeSelectorDialog({
    super.key,
    required this.mediaFolder,
    required this.currentEpisodeIndex,
    required this.onEpisodeSelected,
  });

  final MediaFolder mediaFolder;
  final int currentEpisodeIndex;
  final void Function(int index) onEpisodeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PlatformSpacing.md,
            vertical: PlatformSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '选集 (${mediaFolder.episodes.length} 集)',
                style: PlatformTextStyles.title
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: mediaFolder.episodes.length,
            itemBuilder: (_, index) {
              final episode = mediaFolder.episodes[index];
              final isCurrent = index == currentEpisodeIndex;
              return ListTile(
                selected: isCurrent,
                selectedTileColor: PlatformColors.primary.withAlpha(15),
                leading: Icon(
                  isCurrent
                      ? Icons.play_circle_filled
                      : Icons.play_circle_outline,
                  color: isCurrent
                      ? PlatformColors.primary
                      : ThemeColors.of(context).onSurfaceVariant,
                ),
                title: Text(
                  episode.name,
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                subtitle: episode.subtitleName != null
                    ? Text(
                        '字幕: ${episode.subtitleName}',
                        style: PlatformTextStyles.caption,
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  onEpisodeSelected(index);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class SubtitleBrowserSheet extends StatelessWidget {
  const SubtitleBrowserSheet({
    super.key,
    required this.cues,
    required this.activeIndex,
    required this.onCueTap,
    required this.formatDuration,
  });

  final List<SubtitleCue> cues;
  final int activeIndex;
  final ValueChanged<int> onCueTap;
  final String Function(Duration) formatDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PlatformSpacing.md,
            vertical: PlatformSpacing.sm,
          ),
          child: Row(
            children: [
              Text('字幕列表',
                  style: PlatformTextStyles.title.copyWith(
                    fontWeight: FontWeight.w600,
                  )),
              const SizedBox(width: PlatformSpacing.sm),
              Text('${cues.length} 条',
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant)),
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
          child: ListView.builder(
            itemCount: cues.length,
            itemBuilder: (_, index) {
              final cue = cues[index];
              final isActive = index == activeIndex;
              return ListTile(
                selected: isActive,
                selectedTileColor: PlatformColors.primary.withAlpha(15),
                leading: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? PlatformColors.primary.withAlpha(30)
                        : ThemeColors.of(context).surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive
                          ? PlatformColors.primary
                          : ThemeColors.of(context).outline,
                    ),
                  ),
                  child: Text(
                    formatDuration(cue.start),
                    style: PlatformTextStyles.caption.copyWith(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: isActive
                          ? PlatformColors.primary
                          : ThemeColors.of(context).onSurfaceVariant,
                    ),
                  ),
                ),
                title: Text(
                  cue.text,
                  style: PlatformTextStyles.body.copyWith(
                    color: isActive
                        ? PlatformColors.primary
                        : ThemeColors.of(context).onSurface,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                dense: true,
                onTap: () {
                  onCueTap(index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class CollocationPopover extends StatelessWidget {
  const CollocationPopover({
    super.key,
    required this.text,
    required this.meaning,
    required this.isFavorited,
    required this.onToggleFavorite,
    required this.onAddFlashcard,
    required this.onLookup,
  });

  final String text;
  final String? meaning;
  final bool isFavorited;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAddFlashcard;
  final VoidCallback onLookup;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(text),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (meaning != null) ...[
            Text('释义: $meaning',
                style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant)),
            const SizedBox(height: PlatformSpacing.sm),
          ],
          Text('这是一个固定搭配',
              style: TextStyle(
                color: ThemeColors.of(context).onSurfaceVariant,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              )),
          const SizedBox(height: PlatformSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorited ? Icons.star : Icons.star_border,
                  color: isFavorited
                      ? const Color(0xFFF59E0B)
                      : ThemeColors.of(context).onSurfaceVariant,
                ),
                label: Text(isFavorited ? '已收藏' : '收藏'),
              ),
              TextButton.icon(
                onPressed: onAddFlashcard,
                icon: const Icon(Icons.style),
                label: const Text('闪卡'),
              ),
              TextButton.icon(
                onPressed: onLookup,
                icon: const Icon(Icons.search),
                label: const Text('查词典'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

class WordLookupDialog extends StatefulWidget {
  final String word;
  final AIService aiService;
  final bool isFavorited;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onAddFlashcard;
  final VoidCallback? onClose;

  const WordLookupDialog({
    super.key,
    required this.word,
    required this.aiService,
    this.isFavorited = false,
    this.onToggleFavorite,
    this.onAddFlashcard,
    this.onClose,
  });

  @override
  State<WordLookupDialog> createState() => _WordLookupDialogState();
}

class _WordLookupDialogState extends State<WordLookupDialog> {
  WordLookupResult? _result;
  bool _isLoading = true;
  String? _error;
  bool _showChinese = false;
  final TtsService _tts = TtsService();

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await widget.aiService.lookupWord(widget.word);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = 'AI 服务不可用，请检查后端是否启动';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ThemeColors.of(context).outline.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.word,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!_isLoading && _error == null) ...[
                        IconButton(
                          icon: Icon(
                            _showChinese ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                          ),
                          tooltip: _showChinese ? '隐藏中文' : '显示中文',
                          onPressed: () => setState(() => _showChinese = !_showChinese),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up, size: 20),
                          tooltip: '播放发音',
                          onPressed: () => _tts.speak(widget.word),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                      if (_isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildContent(context),
                  if (!_isLoading && _error == null) ...[
                    const SizedBox(height: 12),
                    _buildActions(context),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        if (widget.onToggleFavorite != null)
          TextButton.icon(
            onPressed: widget.onToggleFavorite,
            icon: Icon(
              widget.isFavorited ? Icons.star : Icons.star_border,
              color: widget.isFavorited
                  ? const Color(0xFFF59E0B)
                  : PlatformColors.gray,
              size: 18,
            ),
            label: Text(widget.isFavorited ? '已收藏' : '收藏'),
          ),
        if (widget.onAddFlashcard != null)
          TextButton.icon(
            onPressed: widget.onAddFlashcard,
            icon: const Icon(Icons.style, size: 18),
            label: const Text('闪卡'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => widget.onClose?.call(),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: Text('AI 正在查询中...')),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _error!,
          style: const TextStyle(color: PlatformColors.error),
        ),
      );
    }

    final result = _result!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPhonetic(context, result),
          const SizedBox(height: PlatformSpacing.md),
          _buildSenses(context, result),
          const SizedBox(height: PlatformSpacing.md),
          _buildExamples(context, result),
          const SizedBox(height: PlatformSpacing.md),
          _buildCollocations(context, result),
          const SizedBox(height: PlatformSpacing.md),
          _buildConfusableWords(context, result),
        ],
      ),
    );
  }

  Widget _buildPhonetic(BuildContext context, WordLookupResult result) {
    if (result.phoneticUs.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _tts.speak(widget.word),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.volume_up, size: 16, color: PlatformColors.primary),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'US ${result.phoneticUs}',
            style: PlatformTextStyles.body.copyWith(
              color: PlatformColors.primary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenses(BuildContext context, WordLookupResult result) {
    if (result.senses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('释义'),
        const SizedBox(height: PlatformSpacing.xs),
        ...result.senses.asMap().entries.map((entry) {
          final idx = entry.key;
          final sense = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: PlatformSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${idx + 1}. ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: ThemeColors.of(context).onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(sense.definitionEn, style: PlatformTextStyles.body),
                          ),
                          InkWell(
                            onTap: () => _tts.speak(sense.definitionEn),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.volume_up, size: 14, color: PlatformColors.primary),
                            ),
                          ),
                        ],
                      ),
                      if (_showChinese) ...[
                        const SizedBox(height: 2),
                        Text(
                          sense.definitionZh,
                          style: PlatformTextStyles.caption.copyWith(
                            color: ThemeColors.of(context).onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExamples(BuildContext context, WordLookupResult result) {
    if (result.examples.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('例句'),
        const SizedBox(height: PlatformSpacing.xs),
        ...result.examples.map((example) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
              padding: const EdgeInsets.all(PlatformSpacing.sm),
              decoration: BoxDecoration(
                color: ThemeColors.of(context).surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ThemeColors.of(context).outline.withAlpha(80),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          example.sentenceEn,
                          style: PlatformTextStyles.body.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _tts.speak(example.sentenceEn),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.volume_up, size: 14, color: PlatformColors.primary),
                        ),
                      ),
                    ],
                  ),
                  if (_showChinese) ...[
                    const SizedBox(height: 2),
                    Text(
                      example.sentenceZh,
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCollocations(BuildContext context, WordLookupResult result) {
    if (result.collocations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('常见搭配'),
        const SizedBox(height: PlatformSpacing.xs),
        Wrap(
          spacing: PlatformSpacing.sm,
          runSpacing: PlatformSpacing.xs,
          children: result.collocations.map((c) => Chip(
                label: Text(
                  _showChinese ? '${c.phrase}  ${c.meaning}' : c.phrase,
                  style: PlatformTextStyles.caption,
                ),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: PlatformColors.secondary.withAlpha(15),
                side: BorderSide(
                  color: PlatformColors.secondary.withAlpha(60),
                ),
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildConfusableWords(BuildContext context, WordLookupResult result) {
    if (result.confusableWords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('易混词辨析'),
        const SizedBox(height: PlatformSpacing.xs),
        ...result.confusableWords.map((cw) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
              padding: const EdgeInsets.all(PlatformSpacing.sm),
              decoration: BoxDecoration(
                color: PlatformColors.orange.withAlpha(10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: PlatformColors.orange.withAlpha(60),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cw.word}${_showChinese ? ' (${cw.meaning})' : ''}',
                    style: PlatformTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: PlatformColors.orange,
                    ),
                  ),
                  if (_showChinese) ...[
                    const SizedBox(height: 2),
                    Text(
                      cw.difference,
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            )),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: PlatformTextStyles.body.copyWith(
        fontWeight: FontWeight.w700,
        color: PlatformColors.primary,
      ),
    );
  }
}