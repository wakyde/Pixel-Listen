import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../constants.dart';
import '../models/subtitle.dart';
import '../providers/listening_history_store.dart';
import '../providers/media_category_provider.dart';
import '../providers/media_record_provider.dart';
import '../services/file_picker_factory.dart';
import '../services/file_picker_service.dart';
import '../services/media_file_cache.dart';
import '../services/media_scanner.dart';
import '../services/subtitle_parser.dart';
import '../services/video_import_service.dart';
import 'import_utils.dart';
import 'import_widgets.dart';
import 'import/category_bar.dart';
import 'import/media_records_list.dart';

class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final FilePickerService _picker = createFilePickerService();
  final _urlController = TextEditingController();
  VideoImportService? _videoService;
  StreamSubscription<Map<String, dynamic>>? _progressSub;

  String? _mediaPath;
  String? _mediaName;
  MediaFolder? _mediaFolder;

  bool _isParsingUrl = false;
  String? _parseError;
  Map<String, dynamic>? _videoInfo;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String? _downloadStatus;
  String? _downloadError;

  Future<void> _pickMedia() async {
    final result = await _picker.pickMedia();
    if (result != null) {
      setState(() {
        _mediaPath = result.path;
        _mediaName = result.name;
      });
      _scanFolder();
      _startPlaybackAndSave();
    }
  }

  void _scanFolder() {
    if (_mediaPath == null) return;
    final folder = MediaScanner.scanFolder(_mediaPath!);
    if (folder != null) {
      setState(() => _mediaFolder = folder);
    }
  }

  Future<void> _startPlaybackAndSave() async {
    if (_mediaPath == null) return;
    if (!mounted) return;

    final localCategoryId = await _getLocalCategoryId();
    if (!mounted) return;
    if (localCategoryId != null) {
      try {
        await ref.read(mediaRecordNotifierProvider.notifier).saveRecord(
              categoryId: localCategoryId,
              name: _mediaName ?? 'Unknown',
              path: _mediaPath!,
            );
        if (!mounted) return;
        ref.invalidate(mediaRecordsProvider(localCategoryId));
      } catch (e, st) {
        debugPrint('[ImportScreen] saveRecord failed: $e\n$st');
      }
    } else {
      debugPrint('[ImportScreen] No local category found, skipping record save');
    }

    final params = <String, dynamic>{
      'mediaPath': _mediaPath!,
      'mediaName': _mediaName ?? 'Unknown',
    };

    if (!mounted) return;
    context.push('/player', extra: params);
  }

  Future<String?> _getLocalCategoryId() async {
    final categories = ref.read(mediaCategoryProvider).valueOrNull ?? [];
    for (final category in categories) {
      if (category.type == CategoryType.local) return category.id;
    }
    return null;
  }

  Future<void> _playFromHistory(ListeningHistoryEntry entry) async {
    final mediaPath = await _resolveMediaPath(entry.mediaPath, entry.mediaName);
    if (mediaPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该文件已失效，请重新导入')),
        );
      }
      return;
    }

    final params = <String, dynamic>{
      'mediaPath': mediaPath,
      'mediaName': entry.mediaName,
    };
    if (entry.subtitlePath != null) {
      params['subtitlePath'] = entry.subtitlePath!;
    }
    if (entry.subtitleContent != null) {
      params['subtitleContent'] = entry.subtitleContent!;
    }
    if (entry.subtitlePath != null || entry.subtitleContent != null) {
      params['subtitleExtension'] = entry.subtitlePath != null
          ? entry.subtitlePath!.split('.').last
          : '.srt';
    }
    if (mounted) {
      context.push('/player', extra: params);
    }
  }

  Future<String?> _resolveMediaPath(String path, String fileName) async {
    if (path.startsWith('blob:')) {
      if (MediaFileCache.instance.hasBytes(path)) {
        return MediaFileCache.instance.getBlobUrl(path);
      }
      final restored = await MediaFileCache.instance.getBlobUrlFromIndexedDB(fileName);
      if (restored != null) return restored;
      return null;
    }
    return path;
  }

  void _playEpisode(MediaEpisode episode) {
    final params = <String, dynamic>{
      'mediaPath': episode.path,
      'mediaName': episode.name,
    };
    if (episode.subtitlePath != null) {
      params['subtitlePath'] = episode.subtitlePath!;
    }
    context.push('/player', extra: params);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _parseUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isParsingUrl = true;
      _parseError = null;
      _videoInfo = null;
    });

    try {
      _videoService ??= VideoImportService(
        baseUrl: 'http://localhost:8000',
        getToken: () => 'mock-token',
      );
      final info = await _videoService!.parseUrl(url);
      setState(() {
        _videoInfo = info;
        _isParsingUrl = false;
      });

      _startDownload();
    } catch (e) {
      setState(() {
        _parseError = e.toString().replaceFirst('Exception: ', '');
        _isParsingUrl = false;
      });
    }
  }

  Future<void> _startDownload() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadStatus = '准备下载...';
      _downloadError = null;
    });

    _progressSub?.cancel();

    try {
      _videoService ??= VideoImportService(
        baseUrl: 'http://localhost:8000',
        getToken: () => 'mock-token',
      );
      final result = await _videoService!.download(url);
      final taskId = result['task_id'] as String;

      _progressSub = _videoService!.streamProgress(taskId).listen(
        (data) {
          final status = data['status'] as String?;
          if (status == 'done') {
            setState(() {
              _isDownloading = false;
              _downloadStatus = 'done';
              _downloadProgress = 1.0;
            });
            _onDownloadComplete(data);
          } else if (status == 'failed') {
            setState(() {
              _isDownloading = false;
              _downloadError = data['error'] as String? ?? '下载失败';
            });
          } else {
            setState(() {
              _downloadStatus = status;
              _downloadProgress = (data['progress'] as num?)?.toDouble() ?? 0;
            });
          }
        },
        onError: (e) {
          setState(() {
            _isDownloading = false;
            _downloadError = e.toString();
          });
        },
      );
    } catch (e) {
      setState(() {
        _isDownloading = false;
        _downloadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _cancelDownload() {
    _progressSub?.cancel();
    setState(() {
      _isDownloading = false;
      _downloadStatus = null;
    });
  }

  Future<void> _onDownloadComplete(Map<String, dynamic> data) async {
    final videoPath = data['video_path'] as String?;
    final fileId = data['file_id'] as String?;
    final subtitlePaths =
        (data['subtitle_paths'] as List?)?.cast<String>() ?? [];

    if (videoPath == null || fileId == null || !mounted) return;

    final streamUrl = 'http://localhost:8000/api/video/files/$fileId/stream';

    String? subtitleContent;
    String? subtitleExtension;

    if (subtitlePaths.isNotEmpty) {
      try {
        _videoService ??= VideoImportService(
          baseUrl: 'http://localhost:8000',
          getToken: () => 'mock-token',
        );

        if (subtitlePaths.length >= 2) {
          final allSubtitles = <Map<String, dynamic>>[];
          for (int i = 0; i < subtitlePaths.length; i++) {
            final sub = await _videoService!.getSubtitleContent(fileId, i);
            allSubtitles.add(sub);
          }

          final parsedGroups = <List<SubtitleCue>>[];
          for (final sub in allSubtitles) {
            final ext = sub['extension'] as String? ?? '.srt';
            final content = sub['content'] as String;
            parsedGroups.add(SubtitleParser.parseFromContent(content, ext));
          }

          final merged = mergeBilingualCues(parsedGroups);
          subtitleContent = encodeCuesToAss(merged);
          subtitleExtension = '.ass';
        } else {
          final sub = await _videoService!.getSubtitleContent(fileId, 0);
          subtitleContent = sub['content'] as String?;
          subtitleExtension = sub['extension'] as String?;
        }
      } catch (e, st) {
        debugPrint('[ImportScreen] subtitle download failed: $e\n$st');
      }
    }

    if (!mounted) return;

    final mediaName = _videoInfo?['title'] as String? ?? 'Online Video';
    final platform = _videoInfo?['platform'] as String?;

    final categoryId = await _getCategoryIdForPlatform(platform);
    if (categoryId != null) {
      ref.read(mediaRecordNotifierProvider.notifier).saveRecord(
            categoryId: categoryId,
            name: mediaName,
            path: streamUrl,
            subtitleContent: subtitleContent,
          );
      ref.invalidate(mediaRecordsProvider(categoryId));
    }

    final params = <String, dynamic>{
      'mediaPath': streamUrl,
      'mediaName': mediaName,
    };

    if (subtitleContent != null) {
      params['subtitleContent'] = subtitleContent;
      params['subtitleExtension'] = subtitleExtension ?? '.srt';
    }

    if (!mounted) return;
    context.push('/player', extra: params);
  }

  Future<String?> _getCategoryIdForPlatform(String? platform) async {
    if (platform == null) return null;
    final categories = ref.read(mediaCategoryProvider).valueOrNull ?? [];
    for (final cat in categories) {
      if (cat.platform == platform) return cat.id;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入媒体'),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        const CategoryBar(),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(PlatformSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const MediaRecordsList(),
                const SizedBox(height: PlatformSpacing.lg),
                _buildListeningHistory(),
                const SizedBox(height: PlatformSpacing.lg),
                _buildImportSection(),
                const SizedBox(height: PlatformSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: '导入视频', icon: Icons.video_library),
        const SizedBox(height: PlatformSpacing.sm),
        _buildLocalImportButton(),
        const SizedBox(height: PlatformSpacing.sm),
        _buildOnlineImport(),
        if (_mediaFolder != null && _mediaFolder!.hasMultipleEpisodes) ...[
          const SizedBox(height: PlatformSpacing.lg),
          _buildEpisodeList(),
        ],
      ],
    );
  }

  Widget _buildLocalImportButton() {
    return OutlinedButton.icon(
      onPressed: _pickMedia,
      icon: const Icon(Icons.folder_open, size: 22),
      label: const Text('选择本地视频文件'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: PlatformSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(
          color: PlatformColors.primary.withAlpha(80),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildOnlineImport() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _urlController,
          maxLines: 1,
          minLines: 1,
          decoration: InputDecoration(
            hintText: '粘贴 B站/YouTube/抖音 链接...',
            isDense: true,
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _urlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _urlController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: PlatformSpacing.md,
              vertical: PlatformSpacing.sm,
            ),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _parseUrl(),
        ),
        const SizedBox(height: PlatformSpacing.sm),
        ElevatedButton.icon(
          onPressed: (_urlController.text.isNotEmpty &&
                  !_isParsingUrl &&
                  !_isDownloading)
              ? _parseUrl
              : null,
          icon: _isParsingUrl || _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.download, size: 18),
          label: Text(_isParsingUrl
              ? '解析中...'
              : _isDownloading
                  ? '下载中 ${(_downloadProgress * 100).toInt()}%'
                  : '解析并下载'),
          style: ElevatedButton.styleFrom(
            backgroundColor: PlatformColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: PlatformSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        if (_parseError != null) ...[
          const SizedBox(height: PlatformSpacing.sm),
          _buildInfoCard(
            icon: Icons.error_outline,
            color: PlatformColors.red,
            title: _parseError!,
          ),
        ],
        if (_videoInfo != null) ...[
          const SizedBox(height: PlatformSpacing.sm),
          _buildVideoInfoCard(),
        ],
        if (_isDownloading) ...[
          const SizedBox(height: PlatformSpacing.sm),
          _buildDownloadProgress(),
        ],
        if (_downloadError != null) ...[
          const SizedBox(height: PlatformSpacing.sm),
          _buildInfoCard(
            icon: Icons.error_outline,
            color: PlatformColors.red,
            title: _downloadError!,
          ),
        ],
        if (_downloadStatus == 'done') ...[
          const SizedBox(height: PlatformSpacing.sm),
          _buildInfoCard(
            icon: Icons.check_circle,
            color: PlatformColors.green,
            title: '下载完成！',
            subtitle: '已保存到媒体库',
          ),
        ],
      ],
    );
  }

  Widget _buildVideoInfoCard() {
    final info = _videoInfo!;
    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PlatformColors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            info['title'] as String? ?? '未知标题',
            style: PlatformTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: PlatformSpacing.xs),
          Row(
            children: [
              _buildInfoChip(info['platform'] as String? ?? '未知'),
              const SizedBox(width: PlatformSpacing.sm),
              if (info['duration'] != null)
                _buildInfoChip(formatDuration(
                  Duration(seconds: (info['duration'] as num).toInt()),
                )),
              const SizedBox(width: PlatformSpacing.sm),
              Icon(
                info['has_subtitles'] == true
                    ? Icons.closed_caption
                    : Icons.closed_caption_disabled,
                size: 16,
                color: info['has_subtitles'] == true
                    ? PlatformColors.green
                    : ThemeColors.of(context).onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                info['has_subtitles'] == true ? '有字幕' : '无字幕',
                style: PlatformTextStyles.caption.copyWith(
                  color: info['has_subtitles'] == true
                      ? PlatformColors.green
                      : ThemeColors.of(context).onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: PlatformColors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: PlatformTextStyles.caption.copyWith(
          color: PlatformColors.primary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: PlatformSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PlatformTextStyles.caption.copyWith(color: color),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: PlatformTextStyles.caption.copyWith(
                      color: color.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _downloadStatus ?? '下载中...',
              style: PlatformTextStyles.caption,
            ),
            Text(
              '${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: PlatformTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: PlatformSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _downloadProgress,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: PlatformSpacing.sm),
        TextButton.icon(
          onPressed: _cancelDownload,
          icon: const Icon(Icons.cancel, size: 16),
          label: const Text('取消下载'),
          style: TextButton.styleFrom(
            foregroundColor: PlatformColors.red,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildEpisodeList() {
    final folder = _mediaFolder;
    if (folder == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '检测到 ${folder.episodes.length} 个视频文件', icon: Icons.playlist_play),
        const SizedBox(height: PlatformSpacing.sm),
        Material(
          color: ThemeColors.of(context).surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: PlatformColors.primary.withAlpha(60)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: folder.episodes.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final episode = folder.episodes[index];
              final isCurrent = episode.path == _mediaPath;
              return ListTile(
                selected: isCurrent,
                selectedTileColor: PlatformColors.primary.withAlpha(10),
                leading: Icon(
                  isCurrent
                      ? Icons.play_circle_filled
                      : Icons.play_circle_outline,
                  color: isCurrent
                      ? PlatformColors.primary
                      : ThemeColors.of(context).onSurfaceVariant,
                ),
                title: Text(
                  episode.name,
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                trailing: isCurrent
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PlatformColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '当前',
                          style: PlatformTextStyles.caption.copyWith(
                            color: PlatformColors.primary,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : null,
                onTap: () => _playEpisode(episode),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildListeningHistory() {
    final history = ref.watch(listeningHistoryProvider);

    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: '最近播放', icon: Icons.history),
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
            itemCount: history.length,
            separatorBuilder: (ctx, i) => const Divider(height: 1),
            itemBuilder: (_, index) {
              final entry = history[index];
              final progressText =
                  entry.duration != null && entry.duration! > 0
                      ? '${(entry.progress / entry.duration! * 100).toInt()}%'
                      : formatDurationSeconds(entry.progress.toInt());
              final hasProgress = entry.progress > 0;

              return ListTile(
                leading: const Icon(Icons.play_circle_outline,
                    color: PlatformColors.primary),
                title: Text(
                  entry.mediaName,
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Row(
                  children: [
                    if (hasProgress)
                      Flexible(
                        child: Text(
                          progressText,
                          style: PlatformTextStyles.caption.copyWith(
                            color: PlatformColors.primary,
                          ),
                        ),
                      ),
                    if (entry.episodeTitle != null) ...[
                      if (hasProgress)
                        Text(' · ',
                            style: TextStyle(
                                color: ThemeColors.of(context).onSurfaceVariant)),
                      Flexible(
                        child: Text(
                          entry.episodeTitle!,
                          style: PlatformTextStyles.caption.copyWith(
                            color: ThemeColors.of(context).onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Text(
                  formatRelativeTime(entry.lastPlayedAt),
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                onTap: () => _playFromHistory(entry),
              );
            },
          ),
        ),
        const SizedBox(height: PlatformSpacing.sm),
        TextButton.icon(
          onPressed: () {
            ref.read(listeningHistoryProvider.notifier).clearHistory();
          },
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('清空历史'),
          style: TextButton.styleFrom(
            foregroundColor: ThemeColors.of(context).onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}