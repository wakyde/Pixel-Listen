import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'screens/import_screen.dart';

class EnglishListeningPlugin extends PlatformPlugin {
  @override
  String get id => 'english_listening';

  @override
  String get name => '英语听力';

  @override
  String get description => '视频字幕同步、AB 循环、词汇检测';

  @override
  IconData get icon => Icons.headphones;

  @override
  String get routePath => '/english-listening';

  @override
  WidgetBuilder get pageBuilder => (context) => const ImportScreen();

  @override
  int get sortOrder => 1;
}