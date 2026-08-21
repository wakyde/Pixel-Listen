import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_ui/shared_ui.dart';

import '../models/search_models.dart';
import '../providers/song_providers.dart';
import '../services/lyrics_parser.dart';
import '../services/song_search_service.dart';

class SongSearchScreen extends ConsumerStatefulWidget {
  const SongSearchScreen({super.key});

  @override
  ConsumerState<SongSearchScreen> createState() => _SongSearchScreenState();
}

class _SongSearchScreenState extends ConsumerState<SongSearchScreen> {
  final SongSearchService _searchService = SongSearchService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<SongSearchResult> _results = [];
  bool _isSearching = false;
  String? _errorMessage;
  String _lastQuery = '';
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _errorMessage = null;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(value);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query == _lastQuery) return;
    _lastQuery = query;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchSongs(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
          if (results.isEmpty) {
            _errorMessage = 'No songs found for "$query"';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Search failed: $e';
        });
      }
    }
  }

  Future<void> _importSong(SongSearchResult result) async {
    setState(() => _isSearching = true);

    try {
      var lyricsContent = '';
      try {
        final lyrics = await _searchService.fetchLyrics(
          result.artist,
          result.title,
        );
        lyricsContent = lyrics ?? '';
      } catch (_) {
        lyricsContent = '';
      }

      if (lyricsContent.trim().isEmpty) {
        lyricsContent = result.title;
      }

      final parseResult = LyricsParser.parse(
        lyricsContent,
        '${result.title}.txt',
      );

      String? songId;
      try {
        final service = ref.read(songServiceProvider);
        final user = ref.read(currentUserProvider);
        final userId = user?.id ?? 'anonymous';
        final songData = await service.createSong(
          userId: userId,
          title: parseResult.songTitle.isNotEmpty
              ? parseResult.songTitle
              : result.title,
          artist: result.artist,
          format: parseResult.format,
          hasTimestamps: parseResult.hasTimestamps,
          audioFilePath: result.previewUrl,
          lines: parseResult.lines,
        );
        songId = songData.id;
      } catch (_) {
        songId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      }

      if (mounted) {
        Navigator.of(context).pop({
          'songId': songId,
          'lines': parseResult.lines,
          'songTitle': result.title,
          'artist': result.artist,
          'format': parseResult.format,
          'hasTimestamps': parseResult.hasTimestamps,
          'audioFilePath': result.previewUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Import failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Songs Online'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_isSearching)
            const LinearProgressIndicator(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _onSearchChanged,
        onSubmitted: _performSearch,
        decoration: InputDecoration(
          hintText: 'Search by song name, artist, or lyrics...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: ThemeColors.of(context).surface,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null && _results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _errorMessage!.startsWith('No songs')
                    ? Icons.search_off
                    : Icons.error_outline,
                size: 64,
                color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: PlatformSpacing.md),
              Text(
                _errorMessage!,
                style: PlatformTextStyles.body,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_results.isEmpty && !_isSearching) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.music_note,
                size: 64,
                color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: PlatformSpacing.md),
              Text(
                'Search for English songs online',
                style: PlatformTextStyles.body.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PlatformSpacing.sm),
              Text(
                'Try searching for "Yesterday", "Let It Be",\nor "Shape of You"',
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.md),
      itemCount: _results.length,
      itemBuilder: (context, index) => _buildResultCard(_results[index]),
    );
  }

  Widget _buildResultCard(SongSearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: PlatformSpacing.sm),
      child: InkWell(
        onTap: () => _importSong(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: result.artworkUrl != null
                    ? Image.network(
                        result.artworkUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderArt(),
                      )
                    : _buildPlaceholderArt(),
              ),
              const SizedBox(width: PlatformSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.title,
                      style: PlatformTextStyles.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      result.artist,
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.collectionName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.collectionName!,
                        style: PlatformTextStyles.caption.copyWith(
                          color: ThemeColors.of(context).onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (result.audioUrl != null)
                          _buildTag('Full Audio', PlatformColors.green),
                        if (result.previewUrl != null && result.audioUrl == null)
                          _buildTag('Preview', PlatformColors.amber),
                        if (result.previewUrl != null || result.audioUrl != null)
                          const SizedBox(width: 6),
                        if (result.trackTimeMillis != null)
                          _buildTag(
                            _formatDuration(result.trackTimeMillis! ~/ 1000),
                            ThemeColors.of(context).onSurfaceVariant,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.download, color: PlatformColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: PlatformColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.music_note,
        color: PlatformColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: PlatformTextStyles.caption.copyWith(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}