import 'package:shared_ui/shared_ui.dart';
import 'package:english_listening/plugin.dart';
import 'package:flashcards/plugin.dart';
import 'package:english_songs/plugin.dart';

final List<PlatformPlugin> pluginRegistry = [
  EnglishListeningPlugin(),
  FlashcardsPlugin(),
  SongLearningPlugin(),
];