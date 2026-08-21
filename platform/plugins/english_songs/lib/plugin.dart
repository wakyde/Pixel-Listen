import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'screens/song_list_screen.dart';

class SongLearningPlugin extends PlatformPlugin {
  @override
  String get id => 'english_songs';

  @override
  String get name => '英文歌学习';

  @override
  String get description => '歌词导入、连读检测、跟唱评分';

  @override
  IconData get icon => Icons.music_note;

  @override
  String get routePath => '/english-songs';

  @override
  WidgetBuilder get pageBuilder => (context) => const SongListScreen();

  @override
  int get sortOrder => 3;
}