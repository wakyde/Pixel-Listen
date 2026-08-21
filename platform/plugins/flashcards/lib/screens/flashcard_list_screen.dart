import 'dart:convert';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_db/shared_db.dart';
import 'package:shared_ui/shared_ui.dart';

class FlashcardListScreen extends ConsumerStatefulWidget {
  const FlashcardListScreen({super.key});

  @override
  ConsumerState<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends ConsumerState<FlashcardListScreen> {
  String _sortBy = 'created_at';
  String? _filterTags;
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardsAsync = ref.watch(flashcardListProvider(_sortBy));

    return Scaffold(
      appBar: AppBar(
        title: const Text('闪卡管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.import_export),
            tooltip: '导入',
            onPressed: () => _showImportDialog(context),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sortBy = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'created_at', child: Text('按创建时间')),
              const PopupMenuItem(value: 'next_review', child: Text('按下次复习')),
              const PopupMenuItem(value: 'source', child: Text('按来源')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: cardsAsync.when(
              data: (cards) => cards.isEmpty
                  ? _buildEmptyState()
                  : _buildCardList(cards),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        border: Border(bottom: BorderSide(color: ThemeColors.of(context).outline)),
      ),
      child: Row(
        children: [
          Icon(Icons.label, size: 18, color: ThemeColors.of(context).onSurfaceVariant),
          const SizedBox(width: PlatformSpacing.sm),
          Expanded(
            child: TextField(
              controller: _tagController,
              decoration: const InputDecoration(
                hintText: '按标签筛选...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (v) {
                setState(() => _filterTags = v.isEmpty ? null : v);
              },
            ),
          ),
          if (_filterTags != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _tagController.clear();
                setState(() => _filterTags = null);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style, size: 64, color: ThemeColors.of(context).onSurfaceVariant.withAlpha(80)),
          const SizedBox(height: PlatformSpacing.md),
          Text('暂无闪卡', style: PlatformTextStyles.title.copyWith(
            color: ThemeColors.of(context).onSurfaceVariant,
          )),
          const SizedBox(height: PlatformSpacing.sm),
          Text('从视频中收藏单词短语，或导入 Anki 牌组', style: PlatformTextStyles.caption.copyWith(
            color: ThemeColors.of(context).onSurfaceVariant,
          )),
        ],
      ),
    );
  }

  Widget _buildCardList(List<Flashcard> cards) {
    final filtered = _filterTags != null
        ? cards.where((c) => (c.tags ?? '').contains(_filterTags!)).toList()
        : cards;

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final card = filtered[index];
        return _buildCardTile(card);
      },
    );
  }

  Widget _buildCardTile(Flashcard card) {
    final isDue = card.nextReviewAt.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.xs,
      ),
      child: ListTile(
        leading: Icon(
          isDue ? Icons.alarm : Icons.check_circle,
          color: isDue ? PlatformColors.amber : PlatformColors.green,
        ),
        title: Text(card.frontText, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.backAnswer, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(
              children: [
                if (card.tags != null && card.tags!.isNotEmpty)
                  _buildTagChip(card.tags!),
                const SizedBox(width: PlatformSpacing.xs),
                _buildReviewInfo(card),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _deleteCard(card.id),
        ),
        onTap: () => _showCardDetail(card),
      ),
    );
  }

  Widget _buildTagChip(String tags) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tags, style: const TextStyle(fontSize: 10, color: PlatformColors.primary)),
    );
  }

  Widget _buildReviewInfo(Flashcard card) {
    return Text(
      '复习 ${card.reviewCount} 次 · 间隔 ${card.interval.toStringAsFixed(1)}天',
      style: PlatformTextStyles.caption.copyWith(
        color: ThemeColors.of(context).onSurfaceVariant,
      ),
    );
  }

  Future<void> _deleteCard(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除闪卡'),
        content: const Text('确定要删除这张闪卡吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: PlatformColors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = getAppDatabase();
      await db.managers.flashcards.filter((f) => f.id.equals(id)).delete();
      ref.invalidate(flashcardListProvider);
    }
  }

  void _showCardDetail(Flashcard card) {
    final examples = _parseExamples(card.examples);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('闪卡详情')),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              tooltip: '编辑',
              onPressed: () {
                Navigator.pop(ctx);
                _showEditDialog(card);
              },
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('正面', card.frontText),
              const SizedBox(height: PlatformSpacing.sm),
              if (card.frontHint != null) ...[
                _detailRow('提示', card.frontHint!),
                const SizedBox(height: PlatformSpacing.sm),
              ],
              _detailRow('答案', card.backAnswer),
              const SizedBox(height: PlatformSpacing.sm),
              if (card.backMeaning != null) ...[
                _detailRow('释义', card.backMeaning!),
                const SizedBox(height: PlatformSpacing.sm),
              ],
              if (card.backOriginal != null) ...[
                _detailRow('原文', card.backOriginal!),
                const SizedBox(height: PlatformSpacing.sm),
              ],
              if (card.sourceTitle != null)
                _detailRow('来源', card.sourceTitle!),
              if (examples.isNotEmpty) ...[
                const SizedBox(height: PlatformSpacing.sm),
                Text('例句', style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                )),
                for (final ex in examples) ...[
                  const SizedBox(height: 2),
                  Text(ex['en'] ?? '', style: PlatformTextStyles.caption),
                  Text(ex['zh'] ?? '',
                      style: PlatformTextStyles.caption.copyWith(
                          color: ThemeColors.of(context).onSurfaceVariant)),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭')),
        ],
      ),
    );
  }

  List<Map<String, String>> _parseExamples(String? examplesJson) {
    if (examplesJson == null || examplesJson.isEmpty) return [];
    try {
      final list = jsonDecode(examplesJson) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return {
          'en': (m['sentence_en'] ?? '') as String,
          'zh': (m['sentence_zh'] ?? '') as String,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  void _showEditDialog(Flashcard card) {
    final frontCtrl = TextEditingController(text: card.frontText);
    final answerCtrl = TextEditingController(text: card.backAnswer);
    final meaningCtrl = TextEditingController(text: card.backMeaning ?? '');
    final hintCtrl = TextEditingController(text: card.frontHint ?? '');
    final originalCtrl = TextEditingController(text: card.backOriginal ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑闪卡'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontCtrl,
                decoration: const InputDecoration(labelText: '正面（填空句）', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: PlatformSpacing.sm),
              TextField(
                controller: answerCtrl,
                decoration: const InputDecoration(labelText: '答案', border: OutlineInputBorder()),
              ),
              const SizedBox(height: PlatformSpacing.sm),
              TextField(
                controller: meaningCtrl,
                decoration: const InputDecoration(labelText: '释义', border: OutlineInputBorder()),
              ),
              const SizedBox(height: PlatformSpacing.sm),
              TextField(
                controller: hintCtrl,
                decoration: const InputDecoration(labelText: '提示', border: OutlineInputBorder()),
              ),
              const SizedBox(height: PlatformSpacing.sm),
              TextField(
                controller: originalCtrl,
                decoration: const InputDecoration(labelText: '原文', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              await _updateCard(card.id, {
                'frontText': frontCtrl.text.trim(),
                'backAnswer': answerCtrl.text.trim(),
                'backMeaning': meaningCtrl.text.trim(),
                'frontHint': hintCtrl.text.trim(),
                'backOriginal': originalCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCard(String id, Map<String, String> fields) async {
    try {
      final db = getAppDatabase();
      await (db.update(db.flashcards)..where((f) => f.id.equals(id))).write(
        FlashcardsCompanion(
          frontText: fields['frontText']?.isNotEmpty == true
              ? Value(fields['frontText']!)
              : const Value.absent(),
          backAnswer: fields['backAnswer']?.isNotEmpty == true
              ? Value(fields['backAnswer']!)
              : const Value.absent(),
          backMeaning: Value(fields['backMeaning']?.isNotEmpty == true
              ? fields['backMeaning']
              : null),
          frontHint: Value(fields['frontHint']?.isNotEmpty == true
              ? fields['frontHint']
              : null),
          backOriginal: Value(fields['backOriginal']?.isNotEmpty == true
              ? fields['backOriginal']
              : null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      ref.invalidate(flashcardListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('闪卡已更新')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新失败: $e')),
        );
      }
    }
  }

  Widget _detailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PlatformTextStyles.caption.copyWith(
          color: ThemeColors.of(context).onSurfaceVariant,
        )),
        const SizedBox(height: 2),
        Text(value, style: PlatformTextStyles.body),
      ],
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入闪卡'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _importOption(
              icon: Icons.upload_file,
              title: 'Anki 牌组 (.apkg)',
              onTap: () {
                Navigator.pop(ctx);
                _showAnkiImportLater();
              },
            ),
            const SizedBox(height: PlatformSpacing.sm),
            _importOption(
              icon: Icons.table_chart,
              title: 'CSV 文件',
              onTap: () {
                Navigator.pop(ctx);
                _showCsvImportLater();
              },
            ),
            const SizedBox(height: PlatformSpacing.sm),
            _importOption(
              icon: Icons.favorite,
              title: '从收藏生成',
              onTap: () {
                Navigator.pop(ctx);
                _showFavoritesToCards();
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ],
      ),
    );
  }

  Widget _importOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PlatformSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: PlatformColors.primary),
            const SizedBox(width: PlatformSpacing.md),
            Text(title, style: PlatformTextStyles.body),
          ],
        ),
      ),
    );
  }

  void _showAnkiImportLater() {
    Navigator.pop(context);
    context.go('/anki-import');
  }

  void _showCsvImportLater() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV 导入功能开发中')),
    );
  }

  void _showFavoritesToCards() async {
    Navigator.pop(context);
    try {
      final db = getAppDatabase();
      final favorites = await db.select(db.favorites).get();

      if (favorites.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('没有收藏内容，先去听听力吧')),
          );
        }
        return;
      }

      int created = 0;
      int skipped = 0;

      for (final fav in favorites) {
        final word = fav.contentText.toLowerCase().trim();
        if (word.isEmpty) continue;

        final existing = await (db.select(db.flashcards)
              ..where((f) => f.backAnswer.lower().equals(word)))
            .get();
        if (existing.isNotEmpty) {
          skipped++;
          continue;
        }

        final frontText = fav.context != null && fav.context!.isNotEmpty
            ? _buildClozeFront(fav.context!, word)
            : word;

        final now = DateTime.now();
        await db.into(db.flashcards).insert(FlashcardsCompanion(
          id: Value(_uuid()),
          userId: const Value('mock-user-001'),
          frontText: Value(frontText),
          frontHint: Value.absentIfNull(fav.cefrLevel),
          backAnswer: Value(word),
          backMeaning: const Value.absent(),
          backOriginal: Value.absentIfNull(fav.context),
          cueId: Value.absentIfNull(fav.cueId),
          mediaTime: Value.absentIfNull(fav.mediaTime),
          sourceTitle: const Value('收藏'),
          nextReviewAt: Value(now.add(const Duration(days: 1))),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
        created++;
      }

      ref.invalidate(flashcardListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已生成 $created 张闪卡${skipped > 0 ? "，跳过 $skipped 个重复" : ""}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }

  String _buildClozeFront(String sentence, String word) {
    final lower = sentence.toLowerCase();
    final lowerWord = word.toLowerCase();
    final idx = lower.indexOf(lowerWord);
    if (idx >= 0) {
      return '${sentence.substring(0, idx)}____${sentence.substring(idx + word.length)}';
    }
    return '____ ($word)';
  }

  String _uuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '${now.toRadixString(36)}-${Object.hash(now, DateTime.now().microsecond).toRadixString(36)}';
  }
}

final flashcardListProvider = FutureProvider.autoDispose.family<List<Flashcard>, String>(
  (ref, sortBy) async {
    final db = getAppDatabase();
    final rows = await db.managers.flashcards.get();

    switch (sortBy) {
      case 'next_review':
        rows.sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
        return rows;
      case 'source':
        rows.sort((a, b) => (a.sourceTitle ?? '').compareTo(b.sourceTitle ?? ''));
        return rows;
      default:
        rows.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return rows;
    }
  },
);