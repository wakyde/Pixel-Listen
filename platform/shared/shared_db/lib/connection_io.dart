import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

Future<QueryExecutor> openConnection() async {
  final dbDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dbDir.path, 'shared.db');
  return NativeDatabase.createInBackground(File(dbPath));
}