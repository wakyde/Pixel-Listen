import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_db/shared_db.dart';
import 'package:shared_ui/shared_ui.dart';

import '../utils/sm2.dart';
import '../services/notification_service.dart';

final dueCardsProvider = FutureProvider.autoDispose<List<Flashcard>>((ref) async {
  final db = getAppDatabase();
  final now = DateTime.now();
  final query = db.select(db.flashcards)
    ..where((f) => f.nextReviewAt.isSmallerOrEqualValue(now))
    ..orderBy([(f) => OrderingTerm.asc(f.nextReviewAt)]);
  return query.get();
});

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _currentIndex = 0;
  bool _isFlipped = false;
  bool _isPersisting = false;

  static const _ratingLabels = ['忘记了', '困难', '良好', '简单'];
  static const _ratingIcons = [
    Icons.restart_alt,
    Icons.thumb_down_alt,
    Icons.thumb_up_alt,
    Icons.thumb_up,
  ];
  static const _ratingColors = [
    PlatformColors.red,
    PlatformColors.amber,
    PlatformColors.green,
    PlatformColors.primary,
  ];

  Flashcard? get _currentCard {
    final cards = ref.read(dueCardsProvider).valueOrNull;
    if (cards == null || cards.isEmpty || _currentIndex >= cards.length) {
      return null;
    }
    return cards[_currentIndex];
  }

  List<Flashcard> get _cards => ref.read(dueCardsProvider).valueOrNull ?? [];

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(dueCardsProvider);

    if (cardsAsync.isLoading) {
      return _buildScaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cardsAsync.hasError) {
      return _buildScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PlatformColors.error),
              const SizedBox(height: PlatformSpacing.md),
              Text(cardsAsync.error.toString(), style: PlatformTextStyles.body),
              const SizedBox(height: PlatformSpacing.md),
              ElevatedButton(
                onPressed: () => ref.invalidate(dueCardsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    final cards = cardsAsync.valueOrNull ?? [];

    if (cards.isEmpty) {
      return _buildScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64,
                  color: PlatformColors.green.withAlpha(200)),
              const SizedBox(height: PlatformSpacing.md),
              Text('今日无到期卡片', style: PlatformTextStyles.title),
              const SizedBox(height: PlatformSpacing.sm),
              Text('干得漂亮，明天再来吧！',
                  style: PlatformTextStyles.body.copyWith(
                      color: ThemeColors.of(context).onSurfaceVariant)),
              const SizedBox(height: PlatformSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dueCardsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
        ),
      );
    }

    final card = _currentCard;
    if (card == null) {
      return _buildScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 64,
                  color: PlatformColors.primary.withAlpha(200)),
              const SizedBox(height: PlatformSpacing.md),
              const Text('本轮复习完成！', style: PlatformTextStyles.title),
              const SizedBox(height: PlatformSpacing.sm),
              Text('已完成 ${cards.length} 张卡片',
                  style: PlatformTextStyles.body.copyWith(
                      color: ThemeColors.of(context).onSurfaceVariant)),
              const SizedBox(height: PlatformSpacing.lg),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(dueCardsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('开始新一轮'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildScaffold(
      body: Column(
        children: [
          _buildProgress(cards),
          Expanded(child: _buildCard(card)),
          _buildRatingBar(card, cards.length),
        ],
      ),
    );
  }

  Widget _buildScaffold({required Widget body}) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闪卡复习'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: '查看列表',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildProgress(List<Flashcard> cards) {
    final total = cards.length;
    final done = _currentIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: PlatformSpacing.md, vertical: PlatformSpacing.xs),
      child: Row(
        children: [
          Text('${done + 1} / $total',
              style: PlatformTextStyles.caption
                  .copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
          const SizedBox(width: PlatformSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? (done + 1) / total : 0,
                minHeight: 4,
                backgroundColor:
                    PlatformColors.primary.withAlpha(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Flashcard card) {
    return GestureDetector(
      onTap: () {
        if (!_isFlipped) {
          setState(() => _isFlipped = true);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isFlipped ? _buildBack(card) : _buildFront(card),
        ),
      ),
    );
  }

  Widget _buildFront(Flashcard card) {
    return Container(
      key: ValueKey('front_${card.id}_$_currentIndex'),
      width: double.infinity,
      padding: const EdgeInsets.all(PlatformSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app, size: 32, color: PlatformColors.primary),
          const SizedBox(height: PlatformSpacing.md),
          SelectableText(
            card.frontText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          if (card.frontHint != null) ...[
            const SizedBox(height: PlatformSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: PlatformSpacing.sm, vertical: PlatformSpacing.xs),
              decoration: BoxDecoration(
                color: PlatformColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${card.frontHint}',
                style: PlatformTextStyles.caption
                    .copyWith(color: PlatformColors.primary),
              ),
            ),
          ],
          const SizedBox(height: PlatformSpacing.lg),
          Text('点击翻转查看答案',
              style: PlatformTextStyles.caption
                  .copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildBack(Flashcard card) {
    return Container(
      key: ValueKey('back_${card.id}_$_currentIndex'),
      width: double.infinity,
      padding: const EdgeInsets.all(PlatformSpacing.lg),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.backAnswer,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: PlatformColors.primary,
            ),
            textAlign: TextAlign.center,
          ),
          if (card.backMeaning != null) ...[
            const SizedBox(height: PlatformSpacing.sm),
            Text(
              card.backMeaning!,
              style: PlatformTextStyles.body
                  .copyWith(color: ThemeColors.of(context).onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (card.backOriginal != null) ...[
            const SizedBox(height: PlatformSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PlatformSpacing.sm),
              decoration: BoxDecoration(
                color: PlatformColors.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                card.backOriginal!,
                style: PlatformTextStyles.caption
                    .copyWith(color: ThemeColors.of(context).onSurfaceVariant),
              ),
            ),
          ],
          if (card.sourceTitle != null) ...[
            const SizedBox(height: PlatformSpacing.sm),
            Text(
              '— ${card.sourceTitle}',
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (card.examples != null) ...[
            const SizedBox(height: PlatformSpacing.md),
            _buildExamples(card.examples!),
          ],
        ],
      ),
    );
  }

  Widget _buildExamples(String examplesJson) {
    try {
      final list = jsonDecode(examplesJson) as List<dynamic>;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(PlatformSpacing.sm),
        decoration: BoxDecoration(
          color: PlatformColors.green.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📝 更多例句',
                style: PlatformTextStyles.caption.copyWith(
                    color: PlatformColors.green, fontWeight: FontWeight.w600)),
            const SizedBox(height: PlatformSpacing.xs),
            for (int i = 0; i < list.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i > 0 ? PlatformSpacing.xs : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list[i]['sentence_en'] as String? ?? '',
                      style: PlatformTextStyles.caption,
                    ),
                    Text(
                      list[i]['sentence_zh'] as String? ?? '',
                      style: PlatformTextStyles.caption.copyWith(
                          color: ThemeColors.of(context).onSurfaceVariant),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildRatingBar(Flashcard card, int totalCards) {
    final progress = totalCards > 0
        ? '已复习 ${_currentIndex + 1} / $totalCards'
        : '';

    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: PlatformSpacing.xs),
              child: Text(progress,
                  style: PlatformTextStyles.caption.copyWith(
                      color: ThemeColors.of(context).onSurfaceVariant)),
            ),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : PlatformSpacing.xs,
                    right: i == 3 ? 0 : PlatformSpacing.xs,
                  ),
                  child: ElevatedButton(
                    onPressed: _isPersisting
                        ? null
                        : () => _rateCard(card, i),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _ratingColors[i],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: PlatformSpacing.sm),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_ratingIcons[i], size: 18),
                        const SizedBox(height: 2),
                        Text(_ratingLabels[i],
                            style: const TextStyle(fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _rateCard(Flashcard card, int rating) async {
    final result = Sm2Algorithm.compute(
      rating: rating,
      interval: card.interval,
      easeFactor: card.easeFactor,
      reviewCount: card.reviewCount,
      now: DateTime.now(),
    );

    setState(() => _isPersisting = true);

    try {
      final db = getAppDatabase();
      final now = DateTime.now();

      await db.into(db.flashcardReviews).insert(FlashcardReviewsCompanion(
        id: Value(_uuid()),
        flashcardId: Value(card.id),
        rating: Value(rating),
        reviewedAt: Value(now),
      ));

      await (db.update(db.flashcards)
            ..where((f) => f.id.equals(card.id)))
          .write(FlashcardsCompanion(
        interval: Value(result.interval),
        easeFactor: Value(result.easeFactor),
        reviewCount: Value(result.reviewCount),
        nextReviewAt: Value(result.nextReviewAt),
        updatedAt: Value(now),
      ));

      ReviewNotificationService.scheduleDailyReview();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }

    setState(() {
      _isPersisting = false;
      _isFlipped = false;
      if (_currentIndex < _cards.length - 1) {
        _currentIndex++;
      }
    });
  }

  String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
  }
}