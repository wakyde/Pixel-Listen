import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_auth/shared_auth.dart';
import 'package:shared_db/shared_db.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AuthService.initialize(mockMode: true);
  final db = await AppDatabase.initialize();
  setAppDatabase(db);

  runApp(
    const ProviderScope(
      child: ShellApp(),
    ),
  );
}