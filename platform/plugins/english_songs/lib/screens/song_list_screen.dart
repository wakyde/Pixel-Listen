import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../providers/song_providers.dart';
import '../services/song_service.dart';
import 'favorites_screen.dart';
import 'import_screen.dart';

class SongListScreen extends ConsumerWidget {
  const SongListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(userSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Songs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_border),
            tooltip: 'Favorites',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Import Song',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SongImportScreen()),
            ),
          ),
        ],
      ),
      body: songsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PlatformSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: PlatformColors.error),
                const SizedBox(height: PlatformSpacing.md),
                Text('Failed to load songs: $err'),
              ],
            ),
          ),
        ),
        data: (songs) {
          if (songs.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildSongList(context, ref, songs);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              size: 64,
              color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: PlatformSpacing.md),
            Text(
              'No songs yet',
              style: PlatformTextStyles.title.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PlatformSpacing.sm),
            Text(
              'Import your first English song to start learning',
              style: PlatformTextStyles.body.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PlatformSpacing.xl),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SongImportScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Import Song'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongList(BuildContext context, WidgetRef ref, List<SongData> songs) {
    return ListView.builder(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      itemCount: songs.length,
      itemBuilder: (context, index) => _buildSongCard(context, ref, songs[index]),
    );
  }

  Widget _buildSongCard(BuildContext context, WidgetRef ref, SongData song) {
    return Card(
      margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
      child: InkWell(
        onTap: () => _onSongTap(context, ref, song),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PlatformColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: PlatformColors.primary,
                ),
              ),
              const SizedBox(width: PlatformSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: PlatformTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.artist != null)
                      Text(
                        song.artist!,
                        style: PlatformTextStyles.caption.copyWith(
                          color: ThemeColors.of(context).onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildTag(context, song.format.toUpperCase()),
                        const SizedBox(width: 8),
                        if (song.hasTimestamps)
                          _buildTag(context, 'Timed', color: PlatformColors.green),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, size: 36),
                    color: PlatformColors.primary,
                    onPressed: () => _onSongTap(context, ref, song),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (action) => _onSongAction(context, ref, song, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'play',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('Play'),
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: PlatformColors.error),
                          title: Text('Delete'),
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (color ?? ThemeColors.of(context).onSurfaceVariant).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: PlatformTextStyles.caption.copyWith(
          fontSize: 10,
          color: color ?? ThemeColors.of(context).onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _onSongTap(BuildContext context, WidgetRef ref, SongData song) async {
    final service = ref.read(songServiceProvider);
    final lines = await service.getSongLines(song.id);

    if (context.mounted) {
      context.go('/song-player', extra: {
        'songId': song.id,
        'lines': lines,
        'songTitle': song.title,
        'artist': song.artist,
        'format': song.format,
        'hasTimestamps': song.hasTimestamps,
        'audioFilePath': song.audioFilePath,
      });
    }
  }

  Future<void> _onSongAction(BuildContext context, WidgetRef ref, SongData song, String action) async {
    switch (action) {
      case 'play':
        _onSongTap(context, ref, song);
        break;
      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Song'),
            content: Text('Delete "${song.title}" and all recordings?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: PlatformColors.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          final service = ref.read(songServiceProvider);
          await service.deleteSong(song.id);
          ref.invalidate(userSongsProvider);
        }
        break;
    }
  }
}