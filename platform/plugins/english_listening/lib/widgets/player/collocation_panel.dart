import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';

class CollocationPanel extends StatelessWidget {
  final List<CollocationToken> tokens;
  final void Function(CollocationToken token)? onAddToFlashcard;
  final bool Function(String text)? isInFlashcard;

  const CollocationPanel({
    super.key,
    required this.tokens,
    this.onAddToFlashcard,
    this.isInFlashcard,
  });

  static const _typeColors = {
    'phrasalVerb': Color(0xFFF59E0B),
    'prepositionalPhrase': Color(0xFFF97316),
    'nounPhrase': Color(0xFF14B8A6),
    'adjectivePhrase': Color(0xFF0EA5E9),
    'idiom': Color(0xFFA855F7),
    'phrase': Color(0xFF6366F1),
  };

  static const _typeLabels = {
    'phrasalVerb': '动词短语',
    'prepositionalPhrase': '介词搭配',
    'nounPhrase': '名词搭配',
    'adjectivePhrase': '形容词搭配',
    'idiom': '习语',
    'phrase': '短语',
  };

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Center(
        child: Text('暂无固定搭配',
            style: TextStyle(color: ThemeColors.of(context).onSurfaceVariant)),
      );
    }

    final grouped = _groupByType();

    return ListView(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      children: [
        _buildSummary(context, grouped),
        const SizedBox(height: PlatformSpacing.md),
        for (final entry in grouped.entries) ...[
          _buildTypeSection(context, entry.key, entry.value),
          const SizedBox(height: PlatformSpacing.sm),
        ],
      ],
    );
  }

  Map<String, List<CollocationToken>> _groupByType() {
    final grouped = <String, List<CollocationToken>>{};
    for (final token in tokens) {
      grouped.putIfAbsent(token.type, () => []).add(token);
    }
    return grouped;
  }

  Widget _buildSummary(BuildContext context, Map<String, List<CollocationToken>> grouped) {
    final total = tokens.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('固定搭配统计',
                style: PlatformTextStyles.title
                    .copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: PlatformSpacing.sm),
            Text('共检测到 $total 个搭配',
                style: PlatformTextStyles.body.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant)),
            const SizedBox(height: PlatformSpacing.sm),
            Wrap(
              spacing: PlatformSpacing.sm,
              runSpacing: PlatformSpacing.xs,
              children: grouped.entries.map((entry) => Chip(
                    avatar: CircleAvatar(
                      backgroundColor: _typeColors[entry.key] ?? PlatformColors.gray,
                      radius: 6,
                    ),
                    label: Text(
                        '${_typeLabels[entry.key] ?? entry.key}: ${entry.value.length}',
                        style: PlatformTextStyles.caption),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSection(BuildContext context, String type, List<CollocationToken> typeTokens) {
    final color = _typeColors[type] ?? PlatformColors.gray;
    final unique = _uniqueTokens(typeTokens);

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
                  child: Text(_typeLabels[type] ?? type,
                      style: PlatformTextStyles.caption.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      )),
                ),
                const SizedBox(width: PlatformSpacing.sm),
                Text('${unique.length} 个搭配',
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
                    isInFlashcard?.call(token.text) ?? false;
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
                            token.text,
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

  List<CollocationToken> _uniqueTokens(List<CollocationToken> tokens) {
    final seen = <String>{};
    return tokens.where((t) => seen.add(t.text.toLowerCase())).toList();
  }
}