import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

import '../models/song_models.dart';
import '../providers/song_providers.dart';
import '../services/lyrics_parser.dart';
import '../services/file_picker_factory.dart';
import '../services/file_picker_service.dart';
import '../screens/search_screen.dart';
import 'package:shared_auth/shared_auth.dart';

class SongImportScreen extends ConsumerStatefulWidget {
  const SongImportScreen({super.key});

  @override
  ConsumerState<SongImportScreen> createState() => _SongImportScreenState();
}

class _SongImportScreenState extends ConsumerState<SongImportScreen> {
  final FilePickerService _picker = createFilePickerService();
  LyricsParseResult? _parseResult;
  String? _audioFilePath;
  bool _isLoading = false;
  String? _errorMessage;

  final List<SongLyricLine> _sampleLyrics = [
    SongLyricLine(
      id: 's1',
      songId: '',
      lineIndex: 0,
      startTime: 1.5,
      endTime: 5.0,
      text: 'Yesterday, all my troubles seemed so far away',
      createdAt: DateTime.now(),
    ),
    SongLyricLine(
      id: 's2',
      songId: '',
      lineIndex: 1,
      startTime: 5.5,
      endTime: 9.0,
      text: 'Now it looks as though they\'re here to stay',
      createdAt: DateTime.now(),
    ),
    SongLyricLine(
      id: 's3',
      songId: '',
      lineIndex: 2,
      startTime: 9.5,
      endTime: 13.0,
      text: 'Oh, I believe in yesterday',
      createdAt: DateTime.now(),
    ),
    SongLyricLine(
      id: 's4',
      songId: '',
      lineIndex: 3,
      startTime: 14.0,
      endTime: 18.0,
      text: 'Suddenly, I\'m not half the man I used to be',
      createdAt: DateTime.now(),
    ),
    SongLyricLine(
      id: 's5',
      songId: '',
      lineIndex: 4,
      startTime: 18.5,
      endTime: 22.0,
      text: 'There\'s a shadow hanging over me',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Lyrics'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: PlatformColors.red),
            const SizedBox(height: PlatformSpacing.md),
            Text(_errorMessage!, style: PlatformTextStyles.body,
                textAlign: TextAlign.center),
            const SizedBox(height: PlatformSpacing.md),
            FilledButton(
              onPressed: () => setState(() => _errorMessage = null),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    if (_parseResult != null) {
      return _buildPreview();
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PlatformSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.music_note, size: 80, color: PlatformColors.primary),
            const SizedBox(height: PlatformSpacing.lg),
            Text(
              'Import Lyrics & Audio',
              style: PlatformTextStyles.headline,
            ),
            const SizedBox(height: PlatformSpacing.sm),
            Text(
              'Select a lyrics file (LRC, SRT, VTT, TXT)\nand optionally associate an audio file',
              style: PlatformTextStyles.body.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PlatformSpacing.xl),
            _buildImportButton(
              icon: Icons.text_snippet,
              label: 'Import Lyrics File',
              subtitle: 'LRC / SRT / VTT / TXT',
              onTap: _importLyricsFile,
            ),
            const SizedBox(height: PlatformSpacing.md),
            _buildImportButton(
              icon: Icons.audio_file,
              label: 'Associate Audio File',
              subtitle: _audioFilePath != null
                  ? 'Selected: ${_audioFilePath!.split('/').last}'
                  : 'MP3 / M4A / WAV / FLAC',
              onTap: _importAudioFile,
            ),
            if (_audioFilePath != null) ...[
              const SizedBox(height: PlatformSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: PlatformColors.green, size: 18),
                  const SizedBox(width: PlatformSpacing.xs),
                  Text(
                    'Audio file selected',
                    style: PlatformTextStyles.caption.copyWith(
                      color: PlatformColors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: PlatformSpacing.xl),
            OutlinedButton.icon(
              onPressed: _useSampleData,
              icon: const Icon(Icons.science),
              label: const Text('Use Sample Lyrics'),
            ),
            const SizedBox(height: PlatformSpacing.md),
            Divider(),
            const SizedBox(height: PlatformSpacing.md),
            _buildImportButton(
              icon: Icons.search,
              label: 'Search Online',
              subtitle: 'Search songs from iTunes & lyrics.ovh',
              onTap: () => _openSearchScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 32, color: PlatformColors.primary),
              const SizedBox(width: PlatformSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PlatformTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: ThemeColors.of(context).onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final result = _parseResult!;
    return Padding(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(PlatformSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: PlatformColors.green),
                      const SizedBox(width: PlatformSpacing.sm),
                      Text(
                        'Parsed Successfully',
                        style: PlatformTextStyles.title.copyWith(
                          color: PlatformColors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: PlatformSpacing.sm),
                  _buildInfoRow('Title', result.songTitle),
                  if (result.artist != null)
                    _buildInfoRow('Artist', result.artist!),
                  _buildInfoRow('Format', result.format),
                  _buildInfoRow('Lines', '${result.lines.length}'),
                  _buildInfoRow('Timestamps', result.hasTimestamps ? 'Yes' : 'No'),
                  if (_audioFilePath != null)
                    _buildInfoRow('Audio', _audioFilePath!.split('/').last),
                ],
              ),
            ),
          ),
          if (!result.hasTimestamps) ...[
            const SizedBox(height: PlatformSpacing.sm),
            Card(
              color: PlatformColors.amber.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(PlatformSpacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: PlatformColors.amber),
                    const SizedBox(width: PlatformSpacing.sm),
                    Expanded(
                      child: Text(
                        'This lyrics file has no timestamps. Sing-along mode is disabled.',
                        style: PlatformTextStyles.body.copyWith(
                          color: PlatformColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (result.parseErrors.isNotEmpty) ...[
            const SizedBox(height: PlatformSpacing.sm),
            Text(
              '${result.parseErrors.length} lines skipped due to format errors',
              style: PlatformTextStyles.caption.copyWith(
                color: PlatformColors.amber,
              ),
            ),
          ],
          const SizedBox(height: PlatformSpacing.md),
          Text(
            'Preview (first 5 lines):',
            style: PlatformTextStyles.title,
          ),
          const SizedBox(height: PlatformSpacing.sm),
          Expanded(
            child: ListView.builder(
              itemCount: result.lines.length > 5 ? 5 : result.lines.length,
              itemBuilder: (context, index) {
                final line = result.lines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Text(
                          line.startTime != null
                              ? _formatTime(line.startTime!)
                              : '--:--',
                          style: PlatformTextStyles.caption.copyWith(
                            color: ThemeColors.of(context).onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          line.text,
                          style: PlatformTextStyles.body,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: PlatformSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _startPlaying(result),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Learning'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: PlatformTextStyles.caption.copyWith(
                color: ThemeColors.of(context).onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: PlatformTextStyles.body),
          ),
        ],
      ),
    );
  }

  void _importLyricsFile() async {
    setState(() => _isLoading = true);

    try {
      final result = await _picker.pickLyrics();
      if (result == null || result.content == null) {
        setState(() => _isLoading = false);
        return;
      }

      final parseResult = LyricsParser.parse(result.content!, result.name);

      if (mounted) {
        setState(() {
          _parseResult = parseResult;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to parse lyrics file: $e';
        });
      }
    }
  }

  void _importAudioFile() async {
    try {
      final result = await _picker.pickAudio();
      if (result != null && mounted) {
        setState(() => _audioFilePath = result.path);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to select audio file: $e');
      }
    }
  }

  void _useSampleData() {
    setState(() {
      _parseResult = LyricsParseResult(
        lines: _sampleLyrics,
        format: 'lrc',
        hasTimestamps: true,
        parseErrors: [],
        songTitle: 'Yesterday (Sample)',
        artist: 'The Beatles',
      );
    });
  }

  void _openSearchScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const SongSearchScreen()),
    );

    if (result != null && mounted) {
      final lines = result['lines'];
      if (lines is List<SongLyricLine>) {
        context.go('/song-player', extra: {
          'songId': result['songId'] as String?,
          'lines': lines,
          'songTitle': result['songTitle'] as String? ?? 'Unknown',
          'artist': result['artist'] as String?,
          'format': result['format'] as String? ?? 'txt',
          'hasTimestamps': result['hasTimestamps'] as bool? ?? false,
          'audioFilePath': result['audioFilePath'] as String?,
        });
      }
    }
  }

  void _startPlaying(LyricsParseResult result) async {
    final service = ref.read(songServiceProvider);
    final user = ref.read(currentUserProvider);
    final userId = user?.id ?? 'anonymous';

    try {
      final songData = await service.createSong(
        userId: userId,
        title: result.songTitle,
        artist: result.artist,
        format: result.format,
        hasTimestamps: result.hasTimestamps,
        audioFilePath: _audioFilePath,
        lines: result.lines,
      );

      if (mounted) {
        context.go('/song-player', extra: {
          'songId': songData.id,
          'lines': result.lines,
          'songTitle': result.songTitle,
          'artist': result.artist,
          'format': result.format,
          'hasTimestamps': result.hasTimestamps,
          'audioFilePath': _audioFilePath,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Failed to save song: $e');
      }
    }
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}