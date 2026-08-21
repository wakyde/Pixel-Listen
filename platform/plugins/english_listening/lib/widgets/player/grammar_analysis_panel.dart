import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';

class GrammarAnalysisPanel extends StatelessWidget {
  final SubtitleCue cue;
  final GrammarAnalysis? analysis;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  const GrammarAnalysisPanel({
    super.key,
    required this.cue,
    this.analysis,
    this.isLoading = false,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(PlatformSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: PlatformSpacing.md),
          if (isLoading)
            _buildLoading()
          else if (error != null)
            _buildError(context)
          else if (analysis != null)
            _buildContent(context),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, size: 14, color: Color(0xFF6366F1)),
              SizedBox(width: 4),
              Text(
                '语法分析',
                style: TextStyle(
                  color: Color(0xFF6366F1),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: PlatformSpacing.sm),
        Expanded(
          child: Text(
            cue.text,
            style: PlatformTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '分析失败',
              style: PlatformTextStyles.body.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error ?? '未知错误',
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final a = analysis!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow(context, a),
        const SizedBox(height: PlatformSpacing.md),
        if (a.grammarPoints.isNotEmpty) ...[
          Text(
            '语法点',
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: PlatformSpacing.xs),
          ...a.grammarPoints.map((gp) => _buildGrammarPoint(context, gp)),
        ],
        if (a.notes.isNotEmpty) ...[
          const SizedBox(height: PlatformSpacing.md),
          _buildNotesBox(context, a),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(BuildContext context, GrammarAnalysis a) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (a.sentenceStructure.isNotEmpty) _buildTag(a.sentenceStructure, const Color(0xFF3B82F6)),
        if (a.sentenceType.isNotEmpty) _buildTag(a.sentenceType, const Color(0xFF10B981)),
        if (a.tense.isNotEmpty) _buildTag(a.tense, const Color(0xFFF59E0B)),
        if (a.difficulty.isNotEmpty) _buildTag(a.difficulty, const Color(0xFFEF4444)),
      ],
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildGrammarPoint(BuildContext context, GrammarPoint gp) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: ThemeColors.of(context).outline.withAlpha(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  gp.name,
                  style: const TextStyle(
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  gp.explanation,
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (gp.relatedText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote,
                      size: 14, color: Color(0xFFB45309)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '"${gp.relatedText}"',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (gp.example.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 14, color: Color(0xFF10B981)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '例：${gp.example}',
                    style: PlatformTextStyles.caption.copyWith(
                      color: const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, GrammarAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PlatformColors.primary.withAlpha(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.school, size: 16, color: PlatformColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              a.notes,
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}