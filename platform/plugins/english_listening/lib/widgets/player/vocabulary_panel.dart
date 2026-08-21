import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';

class VocabularyPanel extends StatelessWidget {
  final List<CefrToken> tokens;
  final void Function(CefrToken token)? onAddToFlashcard;
  final bool Function(String word)? isInFlashcard;

  const VocabularyPanel({
    super.key,
    required this.tokens,
    this.onAddToFlashcard,
    this.isInFlashcard,
  });

  static const _levelColors = {
    'A1': PlatformColors.green,
    'A2': PlatformColors.teal,
    'B1': PlatformColors.primary,
    'B2': PlatformColors.purple,
    'C1': PlatformColors.orange,
    'C2': PlatformColors.red,
  };

  static const _levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Center(
        child: Text('暂无词汇数据',
            style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant)),
      );
    }

    final grouped = _groupByLevel();

    return ListView(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      children: [
        _buildSummary(context, grouped),
        const SizedBox(height: PlatformSpacing.md),
        for (final level in _levelOrder)
          if (grouped.containsKey(level)) ...[
            _buildLevelSection(context, level, grouped[level]!),
            const SizedBox(height: PlatformSpacing.sm),
          ],
      ],
    );
  }

  Map<String, List<CefrToken>> _groupByLevel() {
    final grouped = <String, List<CefrToken>>{};
    for (final token in tokens) {
      grouped.putIfAbsent(token.level, () => []).add(token);
    }
    return grouped;
  }

  Widget _buildSummary(BuildContext context, Map<String, List<CefrToken>> grouped) {
    final total = tokens.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('词汇统计',
                style: PlatformTextStyles.title
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: PlatformSpacing.sm),
            Text('共检测到 $total 个词汇',
                style: PlatformTextStyles.body.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant)),
            const SizedBox(height: PlatformSpacing.sm),
            Wrap(
              spacing: PlatformSpacing.sm,
              runSpacing: PlatformSpacing.xs,
              children: _levelOrder
                  .where((l) => grouped.containsKey(l))
                  .map((level) => Chip(
                        avatar: CircleAvatar(
                          backgroundColor: _levelColors[level],
                          radius: 6,
                        ),
                        label: Text('$level: ${grouped[level]!.length}',
                            style: PlatformTextStyles.caption),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelSection(BuildContext context, String level, List<CefrToken> levelTokens) {
    final color = _levelColors[level] ?? PlatformColors.gray;
    final unique = _uniqueTokens(levelTokens);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(level,
                      style: PlatformTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(width: PlatformSpacing.sm),
                Text('${unique.length} 个词汇',
                    style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: PlatformSpacing.sm),
            Wrap(
              spacing: PlatformSpacing.sm,
              runSpacing: PlatformSpacing.xs,
              children: unique.map((token) {
                final alreadyAdded =
                    isInFlashcard?.call(token.word) ?? false;
                return Tooltip(
                  message: token.meaning ?? '',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: alreadyAdded || onAddToFlashcard == null
                        ? null
                        : () => onAddToFlashcard!(token),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? PlatformColors.green.withAlpha(15)
                            : null,
                        border: Border.all(
                          color: alreadyAdded
                              ? PlatformColors.green.withAlpha(150)
                              : color.withAlpha(80),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            token.word,
                            style: PlatformTextStyles.body.copyWith(
                              color: alreadyAdded
                                  ? PlatformColors.green
                                  : color,
                            ),
                          ),
                          if (alreadyAdded) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle,
                                size: 14, color: PlatformColors.green),
                          ] else if (onAddToFlashcard != null) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.add_circle_outline,
                                size: 14, color: PlatformColors.primary),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<CefrToken> _uniqueTokens(List<CefrToken> tokens) {
    final seen = <String>{};
    return tokens.where((t) => seen.add(t.word.toLowerCase())).toList();
  }
}