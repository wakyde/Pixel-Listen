import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:flashcards/screens/anki_import_screen.dart';
import 'package:english_listening/screens/import_screen.dart';
import 'package:english_listening/screens/player_screen.dart';
import 'package:english_listening/screens/settings_screen.dart';
import 'package:english_listening/screens/favorites_screen.dart';
import 'package:english_listening/screens/typing_screen.dart';
import 'package:english_listening/models/subtitle.dart';
import 'package:english_songs/screens/player_screen.dart' as songs;
import 'package:english_songs/models/song_models.dart';

import 'providers/theme_provider.dart';
import 'registry.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/import',
        builder: (context, state) => const ImportScreen(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final params = state.extra;
          if (params is Map<String, dynamic>) {
            return PlayerScreen(
              mediaPath: params['mediaPath'] as String?,
              subtitlePath: params['subtitlePath'] as String?,
              subtitleContent: params['subtitleContent'] as String?,
              subtitleExtension: params['subtitleExtension'] as String?,
              mediaName: params['mediaName'] as String?,
            );
          }
          return const PlayerScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/typing',
        builder: (context, state) {
          final params = state.extra;
          if (params is Map<String, dynamic>) {
            final cues = params['cues'];
            return TypingScreen(
              cues: cues is List<SubtitleCue> ? cues : null,
              mediaPath: params['mediaPath'] as String?,
              mediaName: params['mediaName'] as String?,
            );
          }
          return const TypingScreen();
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/anki-import',
        builder: (context, state) => const AnkiImportScreen(),
      ),
      GoRoute(
        path: '/song-player',
        builder: (context, state) {
          final params = state.extra;
          if (params is Map<String, dynamic>) {
            final lines = params['lines'];
            if (lines is List<SongLyricLine>) {
              return songs.SongPlayerScreen(
                songId: params['songId'] as String?,
                lines: lines,
                songTitle: params['songTitle'] as String? ?? 'Unknown',
                artist: params['artist'] as String?,
                format: params['format'] as String? ?? 'lrc',
                hasTimestamps: params['hasTimestamps'] as bool? ?? true,
                audioFilePath: params['audioFilePath'] as String?,
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
      for (final plugin in pluginRegistry)
        GoRoute(
          path: plugin.routePath,
          builder: (context, state) {
            return plugin.pageBuilder(context);
          },
        ),
    ],
  );
});

class ShellApp extends ConsumerWidget {
  const ShellApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Personal Platform',
      theme: PlatformTheme.light,
      darkTheme: PlatformTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}