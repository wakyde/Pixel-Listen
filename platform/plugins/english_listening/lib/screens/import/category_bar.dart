import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../providers/media_category_provider.dart';
import '../category_manage_dialog.dart';
import '../import_utils.dart';

class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(mediaCategoryProvider);
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

    return switch (categoriesAsync) {
      AsyncLoading() => const SizedBox(
          height: 56,
          child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
      AsyncError() => const SizedBox(
          height: 56,
          child: Center(child: Text('加载失败', style: TextStyle(color: PlatformColors.error))),
        ),
      _ => _buildContent(context, ref, categoriesAsync.valueOrNull ?? [], selectedCategoryId),
    };
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<MediaCategory> categories,
    String? selectedCategoryId,
  ) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: PlatformSpacing.md,
                right: PlatformSpacing.xs,
                top: PlatformSpacing.sm,
                bottom: PlatformSpacing.sm,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: PlatformSpacing.xs),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category.id == selectedCategoryId;
                return ChoiceChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(categoryIcon(category.iconName),
                          size: 18,
                          color: isSelected ? Colors.white : ThemeColors.of(context).onSurface),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          category.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : ThemeColors.of(context).onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onSelected: (_) => ref.read(selectedCategoryIdProvider.notifier).state = category.id,
                  selectedColor: PlatformColors.primary,
                  backgroundColor: ThemeColors.of(context).background,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : ThemeColors.of(context).onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? PlatformColors.primary : ThemeColors.of(context).outline,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: PlatformSpacing.sm),
            child: IconButton(
              icon: const Icon(Icons.add, size: 20),
              onPressed: () => showCategoryManageDialog(
                    context, ref, categories,
                    (deletedId) {
                      if (ref.read(selectedCategoryIdProvider) == deletedId) {
                        final remaining = categories.where((c) => c.id != deletedId).toList();
                        ref.read(selectedCategoryIdProvider.notifier).state =
                            remaining.isNotEmpty ? remaining.first.id : null;
                      }
                    },
                  ),
              tooltip: '管理分类',
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: PlatformColors.primary.withAlpha(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}