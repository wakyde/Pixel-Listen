import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../providers/song_providers.dart';
import '../services/song_service.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  static const _typeColors = {
    'consonantVowel': Color(0xFF10B981),
    'sameConsonant': Color(0xFF3B82F6),
    'tPlusJ': Color(0xFFF97316),
    'dPlusJ': Color(0xFFEF4444),
    'weakForm': Color(0xFF6B7280),
    'linkingR': Color(0xFF8B5CF6),
    'intrusiveR': Color(0xFFEC4899),
    'elision': Color(0xFF14B8A6),
    'other': Color(0xFF6B7280),
  };

  static const _typeLabels = {
    'consonantVowel': 'Consonant-Vowel',
    'sameConsonant': 'Same Consonant',
    'tPlusJ': 't + j',
    'dPlusJ': 'd + j',
    'weakForm': 'Weak Form',
    'linkingR': 'Linking R',
    'intrusiveR': 'Intrusive R',
    'elision': 'Elision',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(userFavoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
      ),
      body: favoritesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: PlatformColors.red),
              const SizedBox(height: 16),
              Text('Failed to load favorites', style: PlatformTextStyles.body),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(userFavoritesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: PlatformColors.gray),
                  const SizedBox(height: 16),
                  Text(
                    'No favorites yet',
                    style: PlatformTextStyles.title.copyWith(
                      color: ThemeColors.of(context).onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the star icon on liaison marks to save them here',
                    style: PlatformTextStyles.caption.copyWith(
                      color: ThemeColors.of(context).onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(PlatformSpacing.md),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final fav = favorites[index];
              return _buildFavoriteCard(fav);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(SongFavoriteData fav) {
    final color = _typeColors[fav.type] ?? PlatformColors.gray;
    final label = _typeLabels[fav.type] ?? fav.type;

    return Card(
      margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  fav.text,
                  style: PlatformTextStyles.title.copyWith(
                    color: color,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteFavorite(fav),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.record_voice_over, size: 16, color: PlatformColors.gray),
                const SizedBox(width: 4),
                Text(
                  fav.pronunciation,
                  style: PlatformTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildChip(label, color),
                const SizedBox(width: 8),
                Text(
                  _formatDate(fav.createdAt),
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: PlatformTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _deleteFavorite(SongFavoriteData fav) async {
    final service = ref.read(songServiceProvider);
    await service.removeFavorite(fav.id);
    ref.invalidate(userFavoritesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}