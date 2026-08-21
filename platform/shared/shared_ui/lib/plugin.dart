import 'package:flutter/material.dart';

abstract class PlatformPlugin {
  String get id;

  String get name;

  String get description;

  IconData get icon;

  String get routePath;

  WidgetBuilder get pageBuilder;

  int get sortOrder;
}