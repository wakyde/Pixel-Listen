import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_db/shared_db.dart';
import 'package:shared_ui/shared_ui.dart';

final _statsProvider = FutureProvider.autoDispose<_FlashcardStats>((ref) async {
  final db = getAppDatabase();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final allCards = await db.select(db.flashcards).get();
  final allReviews = await db.select(db.flashcardReviews).get();

  final dueCount = allCards
      .where((c) => c.nextReviewAt.isBefore(now) || c.nextReviewAt == now)
      .length;

  final todayReviews = allReviews
      .where((r) => r.reviewedAt.isAfter(today))
      .toList();

  final streak = _calculateStreak(allReviews);

  final hardest = allCards
      .where((c) => c.reviewCount > 0)
      .toList()
    ..sort((a, b) => a.easeFactor.compareTo(b.easeFactor));
  final hardest5 = hardest.take(5).toList();

  final last7Days = List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    final nextDay = day.add(const Duration(days: 1));
    return allReviews
        .where((r) =>
            r.reviewedAt.isAfter(day) && r.reviewedAt.isBefore(nextDay))
        .length;
  });

  return _FlashcardStats(
    totalCards: allCards.length,
    dueCards: dueCount,
    todayReviews: todayReviews.length,
    streak: streak,
    hardestCards: hardest5,
    last7Days: last7Days,
  );
});

int _calculateStreak(List<FlashcardReview> reviews) {
  if (reviews.isEmpty) return 0;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final days = reviews
      .map((r) => DateTime(r.reviewedAt.year, r.reviewedAt.month, r.reviewedAt.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  if (days.isEmpty) return 0;
  if (days.first != today) return 0;

  int streak = 1;
  for (int i = 1; i < days.length; i++) {
    if (days[i - 1].difference(days[i]).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

class _FlashcardStats {
  final int totalCards;
  final int dueCards;
  final int todayReviews;
  final int streak;
  final List<Flashcard> hardestCards;
  final List<int> last7Days;

  const _FlashcardStats({
    required this.totalCards,
    required this.dueCards,
    required this.todayReviews,
    required this.streak,
    required this.hardestCards,
    required this.last7Days,
  });
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('复习统计')),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PlatformColors.error),
              const SizedBox(height: PlatformSpacing.md),
              Text('加载失败', style: PlatformTextStyles.body),
              const SizedBox(height: PlatformSpacing.sm),
              ElevatedButton(
                onPressed: () => ref.invalidate(_statsProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
        data: (stats) => _buildContent(context, stats),
      ),
    );
  }

  Widget _buildContent(BuildContext context, _FlashcardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(context, stats),
          const SizedBox(height: PlatformSpacing.lg),
          _buildChartSection(context, stats),
          const SizedBox(height: PlatformSpacing.lg),
          _buildHardestCards(context, stats),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, _FlashcardStats stats) {
    return Row(
      children: [
        _buildStatCard(
          context,
          icon: Icons.auto_stories,
          label: '总卡片',
          value: '${stats.totalCards}',
          color: PlatformColors.primary,
        ),
        const SizedBox(width: PlatformSpacing.sm),
        _buildStatCard(
          context,
          icon: Icons.alarm,
          label: '待复习',
          value: '${stats.dueCards}',
          color: PlatformColors.amber,
        ),
        const SizedBox(width: PlatformSpacing.sm),
        _buildStatCard(
          context,
          icon: Icons.today,
          label: '今日复习',
          value: '${stats.todayReviews}',
          color: PlatformColors.green,
        ),
        const SizedBox(width: PlatformSpacing.sm),
        _buildStatCard(
          context,
          icon: Icons.local_fire_department,
          label: '连续打卡',
          value: '${stats.streak}天',
          color: PlatformColors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(PlatformSpacing.sm),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: PlatformSpacing.xs),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(label,
                style: PlatformTextStyles.caption
                    .copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, _FlashcardStats stats) {
    final maxCount = stats.last7Days.isEmpty
        ? 1
        : stats.last7Days.reduce((a, b) => a > b ? a : b);
    final today = DateTime.now();
    final dayLabels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.of(context).outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('近7天复习', style: PlatformTextStyles.title),
          const SizedBox(height: PlatformSpacing.md),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = today.subtract(Duration(days: 6 - i));
                final count = stats.last7Days[i];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$count',
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Container(
                          height: maxCount > 0
                              ? (count / maxCount) * 80
                              : 2,
                          decoration: BoxDecoration(
                            color: count > 0
                                ? PlatformColors.primary
                                : PlatformColors.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(dayLabels[day.weekday - 1],
                            style: const TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardestCards(BuildContext context, _FlashcardStats stats) {
    if (stats.hardestCards.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.of(context).outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, size: 18, color: PlatformColors.amber),
              const SizedBox(width: PlatformSpacing.xs),
              Text('需要加强的卡片', style: PlatformTextStyles.title),
            ],
          ),
          const SizedBox(height: PlatformSpacing.sm),
          for (final card in stats.hardestCards)
            Padding(
              padding: const EdgeInsets.only(bottom: PlatformSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${card.backAnswer}  ${card.backMeaning ?? ''}',
                      style: PlatformTextStyles.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '易度 ${card.easeFactor.toStringAsFixed(1)}',
                    style: PlatformTextStyles.caption.copyWith(
                      color: card.easeFactor < 2.0
                          ? PlatformColors.red
                          : PlatformColors.amber,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}