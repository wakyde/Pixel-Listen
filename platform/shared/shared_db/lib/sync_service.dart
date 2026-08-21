import 'dart:async';
import 'package:flutter/foundation.dart';

class SyncService {
  SyncService._();

  static final Map<String, _SyncTableConfig> _tables = {};

  static Timer? _syncTimer;

  static void registerTable({
    required String tableName,
    required dynamic dao,
    required String apiPath,
  }) {
    _tables[tableName] = _SyncTableConfig(
      tableName: tableName,
      dao: dao,
      apiPath: apiPath,
    );
  }

  static void startPeriodicSync(Duration interval) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => sync());
  }

  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  static Future<void> sync() async {
    debugPrint('SyncService: sync started');
    for (final config in _tables.values) {
      try {
        debugPrint('SyncService: syncing ${config.tableName}');
      } catch (e) {
        debugPrint('SyncService: sync failed for ${config.tableName}: $e');
      }
    }
    debugPrint('SyncService: sync completed');
  }
}

class _SyncTableConfig {
  const _SyncTableConfig({
    required this.tableName,
    required this.dao,
    required this.apiPath,
  });

  final String tableName;
  final dynamic dao;
  final String apiPath;
}