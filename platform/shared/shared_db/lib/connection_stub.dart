import 'package:drift/drift.dart';

import 'connection_stub.dart'
    if (dart.library.io) 'connection_io.dart'
    if (dart.library.js) 'connection_web.dart' as impl;

Future<QueryExecutor> openConnection() => impl.openConnection();