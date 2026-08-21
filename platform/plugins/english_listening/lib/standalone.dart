import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';
import 'package:shared_ui/shared_ui.dart';
import 'screens/player_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.initialize(mockMode: true);
  await AppDatabase.initialize(mode: DatabaseMode.isolated);

  runApp(
    ProviderScope(
      child: MaterialApp(
        title: '英语听力',
        theme: PlatformTheme.light,
        darkTheme: PlatformTheme.dark,
        home: const PlayerScreen(),
      ),
    ),
  );
}