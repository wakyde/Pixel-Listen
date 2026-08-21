import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';
import 'package:shared_ui/shared_ui.dart';

import 'database/songs_database.dart';
import 'models/song_models.dart';
import 'screens/import_screen.dart';
import 'screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.initialize(mockMode: true);
  await AppDatabase.initialize(mode: DatabaseMode.isolated);
  await SongsDatabase.initialize();

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SongImportScreen(),
      ),
      GoRoute(
        path: '/song-player',
        builder: (context, state) {
          final params = state.extra;
          if (params is Map<String, dynamic>) {
            final lines = params['lines'];
            if (lines is List<SongLyricLine>) {
              return SongPlayerScreen(
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
    ],
  );

  runApp(
    ProviderScope(
      child: MaterialApp.router(
        title: 'English Songs Learning',
        theme: PlatformTheme.light,
        darkTheme: PlatformTheme.dark,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}