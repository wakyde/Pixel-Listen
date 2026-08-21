import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ABLoopEntry {
  final String id;
  final String label;
  final Duration pointA;
  final Duration pointB;
  final DateTime createdAt;

  const ABLoopEntry({
    required this.id,
    required this.label,
    required this.pointA,
    required this.pointB,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'pointA': pointA.inMilliseconds,
    'pointB': pointB.inMilliseconds,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ABLoopEntry.fromJson(Map<String, dynamic> json) => ABLoopEntry(
    id: json['id'] as String,
    label: json['label'] as String,
    pointA: Duration(milliseconds: json['pointA'] as int),
    pointB: Duration(milliseconds: json['pointB'] as int),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class ABLoopHistoryNotifier extends StateNotifier<List<ABLoopEntry>> {
  ABLoopHistoryNotifier() : super([]) {
    Future.microtask(() => _loadFromPrefs());
  }

  static const int maxEntries = 8;
  static const String _prefsKey = 'ab_loop_history';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final list = (json.decode(raw) as List<dynamic>)
            .map((e) => ABLoopEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        state = list;
      }
    } catch (e, st) {
      debugPrint('[ABLoopHistory] _loadFromPrefs failed: $e\n$st');
      state = [];
    }
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = json.encode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }

  void saveEntry({
    required String label,
    required Duration pointA,
    required Duration pointB,
  }) {
    final entry = ABLoopEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: label,
      pointA: pointA,
      pointB: pointB,
      createdAt: DateTime.now(),
    );

    state = [entry, ...state];
    if (state.length > maxEntries) {
      state = state.sublist(0, maxEntries);
    }
    _saveToPrefs();
  }

  void removeEntry(String id) {
    state = state.where((e) => e.id != id).toList();
    _saveToPrefs();
  }

  void clearAll() {
    state = [];
    _saveToPrefs();
  }
}

final abLoopHistoryProvider =
    StateNotifierProvider<ABLoopHistoryNotifier, List<ABLoopEntry>>(
  (ref) => ABLoopHistoryNotifier(),
);