import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../providers/media_category_provider.dart';
import '../../providers/media_record_provider.dart';
import '../../services/media_file_cache.dart';
import '../import_utils.dart';
import '../import_widgets.dart';

class MediaRecordsList extends ConsumerWidget {
  const MediaRecordsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    if (selectedCategoryId == null) return const SizedBox.shrink();

    final categoriesAsync = ref.watch(mediaCategoryProvider);
    final selectedCategory = categoriesAsync.valueOrNull
        ?.where((c) => c.id == selectedCategoryId)
        .firstOrNull;
    if (selectedCategory == null) return const SizedBox.shrink();

    final recordsAsync = ref.watch(mediaRecordsProvider(selectedCategory.id));

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: '${selectedCategory.name} · 已保存 ${records.length} 个',
              icon: Icons.bookmark,
            ),
            const SizedBox(height: PlatformSpacing.sm),
            Material(
              color: ThemeColors.of(context).surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ThemeColors.of(context).outline),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: records.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    leading: Icon(
                      categoryIcon(selectedCategory.iconName),
                      color: PlatformColors.primary,
                      size: 24,
                    ),
                    title: Text(
                      record.name,
                      style: PlatformTextStyles.body.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      formatRelativeTime(record.createdAt),
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () {
                        ref
                            .read(mediaRecordNotifierProvider.notifier)
                            .deleteRecord(record.id);
                        ref.invalidate(mediaRecordsProvider(selectedCategory.id));
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                    onTap: () => _playFromRecord(context, record),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
    );
  }

  void _playFromRecord(BuildContext context, MediaRecord record) async {
    final mediaPath = await _resolveMediaPath(record.path);
    if (mediaPath == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该文件已失效，请重新导入')),
        );
      }
      return;
    }

    final params = <String, dynamic>{
      'mediaPath': mediaPath,
      'mediaName': record.name,
    };
    if (record.subtitleContent != null) {
      params['subtitleContent'] = record.subtitleContent!;
      params['subtitleExtension'] = '.srt';
    } else if (record.subtitlePath != null) {
      params['subtitlePath'] = record.subtitlePath!;
    }
    if (context.mounted) {
      context.push('/player', extra: params);
    }
  }

  Future<String?> _resolveMediaPath(String path) async {
    if (path.startsWith('blob:')) {
      if (MediaFileCache.instance.hasBytes(path)) {
        return MediaFileCache.instance.getBlobUrl(path);
      }
      final restored = await MediaFileCache.instance.loadFromIndexedDB(path);
      if (restored != null) return restored;
      return null;
    }
    return path;
  }
}