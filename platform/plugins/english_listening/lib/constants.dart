class CategoryType {
  CategoryType._();
  static const String local = 'local';
  static const String online = 'online';
}

class PlatformName {
  PlatformName._();
  static const String youtube = 'youtube';
  static const String bilibili = 'bilibili';
  static const String douyin = 'douyin';
  static const String other = 'other';
}

class IconName {
  IconName._();
  static const String folder = 'folder';
  static const String smartDisplay = 'smart_display';
  static const String tv = 'tv';
  static const String musicNote = 'music_note';
  static const String language = 'language';
}

const List<String> defaultIconNames = [
  IconName.folder,
  IconName.smartDisplay,
  IconName.tv,
  IconName.musicNote,
  IconName.language,
];

const List<String> defaultPlatformNames = [
  PlatformName.youtube,
  PlatformName.bilibili,
  PlatformName.douyin,
  PlatformName.other,
];

class PlayerConstants {
  PlayerConstants._();

  static const double wideLayoutBreakpoint = 900;

  static const Duration seekStep = Duration(seconds: 5);

  static const Duration historySaveInterval = Duration(seconds: 10);

  static const Duration snackbarShort = Duration(seconds: 2);

  static const Duration snackbarLong = Duration(seconds: 3);
}