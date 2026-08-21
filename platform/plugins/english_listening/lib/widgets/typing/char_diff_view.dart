import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../utils/scoring.dart';

class CharDiffView extends StatelessWidget {
  final List<CharDiff> diffs;

  const CharDiffView({super.key, required this.diffs});

  static const _statusColors = {
    CharDiffStatus.correct: PlatformColors.green,
    CharDiffStatus.incorrect: PlatformColors.red,
    CharDiffStatus.missing: PlatformColors.gray,
    CharDiffStatus.extra: PlatformColors.amber,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 4,
      children: diffs.map((diff) {
        final color = _statusColors[diff.status] ?? PlatformColors.gray;
        final displayChar = diff.status == CharDiffStatus.extra
            ? diff.char
            : diff.char;
        final bgColor = diff.status == CharDiffStatus.correct
            ? color.withAlpha(30)
            : diff.status == CharDiffStatus.incorrect
                ? color.withAlpha(20)
                : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(3),
            border: diff.status == CharDiffStatus.missing
                ? Border.all(color: color.withAlpha(80), width: 1)
                : null,
          ),
          child: Text(
            displayChar,
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: color,
              decoration: diff.status == CharDiffStatus.incorrect
                  ? TextDecoration.lineThrough
                  : null,
              decorationColor: color.withAlpha(150),
            ),
          ),
        );
      }).toList(),
    );
  }
}