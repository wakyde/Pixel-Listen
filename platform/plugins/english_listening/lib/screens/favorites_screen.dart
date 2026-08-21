import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../providers/favorites_store.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  FavoriteType? _typeFilter;
  String? _levelFilter;
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};

  static const _levelOrder = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final allFavorites = ref.watch(favoritesStoreProvider);
    final favorites = _applyFilters(allFavorites);

    return Scaffold(
      appBar: AppBar(
        title: const Text('收藏'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
              tooltip: _selectionMode ? '取消选择' : '批量选择',
              onPressed: () {
                setState(() {
                  _selectionMode = !_selectionMode;
                  _selectedIds.clear();
                });
              },
            ),
          if (_selectionMode && _selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: PlatformColors.red),
              tooltip: '删除所选',
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: favorites.isEmpty
                ? _buildEmptyState()
                : _buildFavoritesList(favorites),
          ),
        ],
      ),
    );
  }

  List<FavoriteEntry> _applyFilters(List<FavoriteEntry> entries) {
    var result = entries;
    if (_typeFilter != null) {
      result = result.where((e) => e.type == _typeFilter).toList();
    }
    if (_levelFilter != null) {
      result = result.where((e) => e.cefrLevel == _levelFilter).toList();
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: PlatformSpacing.md, vertical: PlatformSpacing.sm),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        border: Border(
          bottom: BorderSide(color: ThemeColors.of(context).outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部', _typeFilter == null,
                    onTap: () => setState(() => _typeFilter = null)),
                const SizedBox(width: PlatformSpacing.xs),
                _buildFilterChip('单词', _typeFilter == FavoriteType.word,
                    onTap: () =>
                        setState(() => _typeFilter = FavoriteType.word)),
                const SizedBox(width: PlatformSpacing.xs),
                _buildFilterChip('短语', _typeFilter == FavoriteType.phrase,
                    onTap: () =>
                        setState(() => _typeFilter = FavoriteType.phrase)),
                const SizedBox(width: PlatformSpacing.xs),
                _buildFilterChip('句子', _typeFilter == FavoriteType.sentence,
                    onTap: () =>
                        setState(() => _typeFilter = FavoriteType.sentence)),
              ],
            ),
          ),
          const SizedBox(height: PlatformSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('全部等级', _levelFilter == null,
                    onTap: () => setState(() => _levelFilter = null)),
                for (final level in _levelOrder) ...[
                  const SizedBox(width: PlatformSpacing.xs),
                  _buildFilterChip(
                      level, _levelFilter == level,
                      onTap: () => setState(() => _levelFilter = level)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? PlatformColors.primary.withAlpha(30)
              : ThemeColors.of(context).surface,
          border: Border.all(
            color: isSelected ? PlatformColors.primary : ThemeColors.of(context).outline,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: PlatformTextStyles.caption.copyWith(
            color: isSelected
                ? PlatformColors.primary
                : ThemeColors.of(context).onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 64, color: PlatformColors.gray),
          const SizedBox(height: PlatformSpacing.md),
          Text('暂无收藏',
              style: PlatformTextStyles.title
                  .copyWith(color: ThemeColors.of(context).onSurfaceVariant)),
          const SizedBox(height: PlatformSpacing.sm),
          Text('在字幕或词汇面板中点击星标添加收藏',
              style: PlatformTextStyles.body
                  .copyWith(color: PlatformColors.gray)),
        ],
      ),
    );
  }

  Widget _buildFavoritesList(List<FavoriteEntry> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final entry = favorites[index];
        final isSelected = _selectedIds.contains(entry.id);
        return _buildFavoriteItem(entry, isSelected);
      },
    );
  }

  Widget _buildFavoriteItem(FavoriteEntry entry, bool isSelected) {
    return Card(
      color: isSelected
          ? PlatformColors.primary.withAlpha(15)
          : ThemeColors.of(context).surface,
      child: InkWell(
        onTap: _selectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(entry.id);
                  } else {
                    _selectedIds.add(entry.id);
                  }
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          child: Row(
            children: [
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: PlatformSpacing.sm),
                  child: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? PlatformColors.primary
                        : PlatformColors.gray,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildTypeBadge(entry.type),
                        if (entry.cefrLevel != null) ...[
                          const SizedBox(width: PlatformSpacing.xs),
                          _buildLevelBadge(entry.cefrLevel!),
                        ],
                      ],
                    ),
                    const SizedBox(height: PlatformSpacing.xs),
                    Text(
                      entry.text,
                      style: PlatformTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (entry.context != null) ...[
                      const SizedBox(height: PlatformSpacing.xs),
                      Text(
                        entry.context!,
                        style: PlatformTextStyles.caption.copyWith(
                          color: ThemeColors.of(context).onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (!_selectionMode)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteSingle(entry),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge(FavoriteType type) {
    final labels = {
      FavoriteType.word: '单词',
      FavoriteType.phrase: '短语',
      FavoriteType.sentence: '句子',
    };
    final colors = {
      FavoriteType.word: PlatformColors.primary,
      FavoriteType.phrase: const Color(0xFFF59E0B),
      FavoriteType.sentence: const Color(0xFF14B8A6),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (colors[type] ?? PlatformColors.gray).withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        labels[type] ?? '未知',
        style: PlatformTextStyles.caption.copyWith(
          color: colors[type] ?? PlatformColors.gray,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level,
        style: PlatformTextStyles.caption.copyWith(
          color: PlatformColors.primary,
          fontSize: 10,
        ),
      ),
    );
  }

  void _deleteSingle(FavoriteEntry entry) {
    ref.read(favoritesStoreProvider.notifier).removeFavorite(entry.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除「${entry.text}」'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteSelected() {
    final count = _selectedIds.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 $count 条收藏吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(favoritesStoreProvider.notifier)
                  .removeFavorites(_selectedIds.toList());
              setState(() {
                _selectedIds.clear();
                _selectionMode = false;
              });
              Navigator.pop(ctx);
            },
            child: const Text('删除',
                style: TextStyle(color: PlatformColors.red)),
          ),
        ],
      ),
    );
  }
}