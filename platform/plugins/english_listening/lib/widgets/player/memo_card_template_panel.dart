import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';

class MemoCardTemplatePanel extends StatefulWidget {
  final SubtitleCue cue;
  final MemorizationMeta? memorizationMeta;
  final MemoCardTemplate? template;
  final bool isLoading;
  final VoidCallback? onAddToFavorites;
  final VoidCallback? onAddToAnki;
  final VoidCallback? onPlayClip;

  const MemoCardTemplatePanel({
    super.key,
    required this.cue,
    this.memorizationMeta,
    this.template,
    this.isLoading = false,
    this.onAddToFavorites,
    this.onAddToAnki,
    this.onPlayClip,
  });

  @override
  State<MemoCardTemplatePanel> createState() => _MemoCardTemplatePanelState();
}

class _MemoCardTemplatePanelState extends State<MemoCardTemplatePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_isFront) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

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
          else
            _buildFlipCard(),
          const SizedBox(height: PlatformSpacing.lg),
          _buildActions(context),
        ],
      ),
    );
  }

  bool get isLoading => widget.isLoading;

  Widget _buildHeader() {
    final score = widget.memorizationMeta?.score ?? 0;
    final isAi = widget.memorizationMeta?.isAiEnhanced ?? false;
    return Row(
      children: [
        _buildScoreBadge(score, isAi),
        const SizedBox(width: PlatformSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.cue.text,
                style: PlatformTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.memorizationMeta?.reason != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.memorizationMeta!.reason!,
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBadge(double score, bool isAi) {
    final color = score >= 7
        ? const Color(0xFF22C55E)
        : score >= 5
            ? const Color(0xFFF59E0B)
            : const Color(0xFF9CA3AF);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.toStringAsFixed(1),
            style: PlatformTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          if (isAi) ...[
            const SizedBox(width: 4),
            Icon(Icons.auto_awesome, size: 12, color: color),
          ],
        ],
      ),
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

  Widget _buildFlipCard() {
    return GestureDetector(
      onTap: _toggleFlip,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isFrontVisible = _flipAnimation.value < 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(_flipAnimation.value * pi),
            child: isFrontVisible
                ? _buildFront()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateX(pi),
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    final t = widget.template;
    return Container(
      height: 200,
      padding: const EdgeInsets.all(PlatformSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(40),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.touch_app, color: Colors.white54, size: 20),
          const SizedBox(height: 8),
          const Text(
            '点击翻转查看答案',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const Spacer(),
          if (t != null && t.clozeText.isNotEmpty)
            Text(
              t.clozeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              widget.cue.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          if (t != null && t.hint.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '提示：${t.hint}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBack() {
    final t = widget.template;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PlatformSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeColors.of(context).outline.withAlpha(50),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Color(0xFF22C55E), size: 18),
              const SizedBox(width: 6),
              Text(
                '答案与知识点',
                style: PlatformTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.touch_app, color: Colors.grey, size: 16),
              const SizedBox(width: 4),
              const Text('点击翻转', style: TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          _buildOriginalText(),
          if (t != null && t.keyPhrases.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildKeyPhrases(t),
          ],
          if (t != null && t.usageNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildUsageNote(t),
          ],
          const Spacer(),
          if (widget.onPlayClip != null) _buildPlayClipButton(),
        ],
      ),
    );
  }

  Widget _buildOriginalText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface.withAlpha(150),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ThemeColors.of(context).outline.withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '原文',
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.cue.text,
            style: PlatformTextStyles.body.copyWith(
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPhrases(MemoCardTemplate t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '固定搭配',
          style: PlatformTextStyles.caption.copyWith(
            color: ThemeColors.of(context).onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: t.keyPhrases.map((kp) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withAlpha(50),
                ),
              ),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12),
                  children: [
                    TextSpan(
                      text: kp.phrase,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const TextSpan(
                      text: '  ',
                    ),
                    TextSpan(
                      text: kp.meaning,
                      style: TextStyle(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildUsageNote(MemoCardTemplate t) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline,
              size: 14, color: PlatformColors.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              t.usageNote,
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayClipButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onPlayClip,
        icon: const Icon(Icons.play_circle_outline, size: 18),
        label: const Text('播放原声片段'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onAddToFavorites,
            icon: const Icon(Icons.star_border, size: 18),
            label: const Text('加入收藏'),
          ),
        ),
        const SizedBox(width: PlatformSpacing.md),
        Expanded(
          child: FilledButton.icon(
            onPressed: widget.onAddToAnki,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('记忆模板'),
          ),
        ),
      ],
    );
  }
}