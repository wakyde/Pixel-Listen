import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'AppDatabase must be initialized before use. '
    'Call AppDatabase.initialize() in main() first.',
  );
});

AppDatabase? _sharedInstance;

void setAppDatabase(AppDatabase db) {
  _sharedInstance = db;
}

AppDatabase getAppDatabase() {
  if (_sharedInstance == null) {
    throw StateError(
      'AppDatabase not initialized. '
      'Call AppDatabase.initialize() before accessing the database.',
    );
  }
  return _sharedInstance!;
}