import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../constants.dart';
import '../providers/media_category_provider.dart';
import 'import_utils.dart';

void showCategoryManageDialog(
  BuildContext context,
  WidgetRef ref,
  List<MediaCategory> categories,
  void Function(String? categoryId) onCategoryDeleted,
) {
  final nameController = TextEditingController();
  String selectedType = CategoryType.online;
  String? selectedPlatform;
  const iconNames = defaultIconNames;
  String selectedIcon = IconName.folder;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: PlatformSpacing.lg,
              right: PlatformSpacing.lg,
              top: PlatformSpacing.lg,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + PlatformSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ThemeColors.of(context).onSurfaceVariant.withAlpha(60),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: PlatformSpacing.lg),
                Text(
                  '管理分类',
                  style: PlatformTextStyles.title.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: PlatformSpacing.xs),
                Text(
                  '长按分类可删除，或添加新分类',
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PlatformSpacing.lg),
                Text(
                  '现有分类',
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: PlatformSpacing.sm),
                ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(bottom: PlatformSpacing.xs),
                      child: Material(
                        color: ThemeColors.of(context).surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: ThemeColors.of(context).outline),
                        ),
                        child: ListTile(
                          leading: Icon(
                            categoryIcon(cat.iconName),
                            color: PlatformColors.primary,
                            size: 22,
                          ),
                          title: Text(
                            cat.name,
                            style: PlatformTextStyles.body.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            cat.type == CategoryType.local ? '本地' : '在线 · ${cat.platform ?? '通用'}',
                            style: PlatformTextStyles.caption.copyWith(
                              color: ThemeColors.of(context).onSurfaceVariant,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            color: PlatformColors.red,
                            onPressed: () {
                              ref
                                  .read(mediaCategoryNotifierProvider.notifier)
                                  .deleteCategory(cat.id);
                              ref.invalidate(mediaCategoryProvider);
                              onCategoryDeleted(cat.id);
                              Navigator.pop(ctx);
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    )),
                const Divider(height: PlatformSpacing.lg),
                Text(
                  '添加新分类',
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: PlatformSpacing.sm),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: '分类名称',
                    prefixIcon: const Icon(Icons.label),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: PlatformSpacing.md,
                      vertical: PlatformSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: PlatformSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: '类型',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: PlatformSpacing.md,
                            vertical: PlatformSpacing.sm,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: CategoryType.local, child: Text('本地')),
                          DropdownMenuItem(value: CategoryType.online, child: Text('在线')),
                        ],
                        onChanged: (v) {
                          setSheetState(() {
                            selectedType = v!;
                            if (selectedType == CategoryType.local) {
                              selectedPlatform = null;
                            }
                          });
                        },
                      ),
                    ),
                    if (selectedType == CategoryType.online) ...[
                      const SizedBox(width: PlatformSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedPlatform,
                          decoration: InputDecoration(
                            labelText: '平台',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: PlatformSpacing.md,
                              vertical: PlatformSpacing.sm,
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(value: PlatformName.youtube, child: Text('YouTube')),
                            DropdownMenuItem(value: PlatformName.bilibili, child: Text('Bilibili')),
                            DropdownMenuItem(value: PlatformName.douyin, child: Text('抖音')),
                            DropdownMenuItem(value: PlatformName.other, child: Text('其他')),
                          ],
                          onChanged: (v) {
                            setSheetState(() => selectedPlatform = v);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: PlatformSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedIcon,
                  decoration: InputDecoration(
                    labelText: '图标',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: PlatformSpacing.md,
                      vertical: PlatformSpacing.sm,
                    ),
                  ),
                  items: iconNames.map((name) {
                    return DropdownMenuItem(
                      value: name,
                      child: Row(
                        children: [
                          Icon(categoryIcon(name), size: 20),
                          const SizedBox(width: PlatformSpacing.sm),
                          Text(name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setSheetState(() => selectedIcon = v!);
                  },
                ),
                const SizedBox(height: PlatformSpacing.lg),
                ElevatedButton.icon(
                  onPressed: nameController.text.trim().isEmpty
                      ? null
                      : () {
                          ref
                              .read(mediaCategoryNotifierProvider.notifier)
                              .addCategory(
                                name: nameController.text.trim(),
                                type: selectedType,
                                platform: selectedPlatform,
                                iconName: selectedIcon,
                                sortOrder: categories.length,
                              );
                          ref.invalidate(mediaCategoryProvider);
                          Navigator.pop(ctx);
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('添加分类'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PlatformColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: PlatformSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}