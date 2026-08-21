import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../providers/favorites_store.dart';
import '../../providers/flashcard_store.dart';

class FlashcardBadge extends ConsumerWidget {
  const FlashcardBadge({
    super.key,
    required this.onNavigate,
  });

  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(flashcardCountProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.style),
          tooltip: count > 0 ? '闪卡 ($count)' : '闪卡',
          onPressed: onNavigate,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: PlatformColors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class FavoritesBadge extends ConsumerWidget {
  const FavoritesBadge({
    super.key,
    required this.onNavigate,
  });

  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      favoritesStoreProvider.select((list) => list.length),
    );

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.star),
          tooltip: count > 0 ? '收藏 ($count)' : '收藏',
          onPressed: onNavigate,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFF59E0B),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class PlayerPopupMenu extends StatelessWidget {
  const PlayerPopupMenu({
    super.key,
    required this.onVocabulary,
    required this.onCollocation,
    required this.onTyping,
    required this.onTranslate,
    required this.onAICollocation,
    required this.onTutorChat,
  });

  final VoidCallback onVocabulary;
  final VoidCallback onCollocation;
  final VoidCallback onTyping;
  final VoidCallback onTranslate;
  final VoidCallback onAICollocation;
  final VoidCallback onTutorChat;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      tooltip: '更多功能',
      onSelected: (value) {
        switch (value) {
          case 'vocabulary':
            onVocabulary();
            break;
          case 'collocation':
            onCollocation();
            break;
          case 'typing':
            onTyping();
            break;
          case 'translate':
            onTranslate();
            break;
          case 'ai_collocation':
            onAICollocation();
            break;
          case 'tutor_chat':
            onTutorChat();
            break;
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'tutor_chat',
          child: ListTile(
            leading: Icon(Icons.school),
            title: Text('AI 英语同桌'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'vocabulary',
          child: ListTile(
            leading: Icon(Icons.menu_book),
            title: Text('词汇面板'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'collocation',
          child: ListTile(
            leading: Icon(Icons.link),
            title: Text('固定搭配'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'typing',
          child: ListTile(
            leading: Icon(Icons.keyboard),
            title: Text('打字练习'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'translate',
          child: ListTile(
            leading: Icon(Icons.translate),
            title: Text('AI 翻译当前句'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'ai_collocation',
          child: ListTile(
            leading: Icon(Icons.auto_awesome),
            title: Text('AI 检测搭配'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class PlayerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlayerAppBar({
    super.key,
    required this.onEpisodeSelect,
    required this.onNavigateToFavorites,
    required this.onNavigateToFlashcards,
    required this.onVocabulary,
    required this.onCollocation,
    required this.onTyping,
    required this.onTranslate,
    required this.onAICollocation,
    required this.onTutorChat,
    required this.onImportSubtitle,
    this.showEpisodeButton = false,
  });

  final VoidCallback? onEpisodeSelect;
  final VoidCallback onNavigateToFavorites;
  final VoidCallback onNavigateToFlashcards;
  final VoidCallback onVocabulary;
  final VoidCallback onCollocation;
  final VoidCallback onTyping;
  final VoidCallback onTranslate;
  final VoidCallback onAICollocation;
  final VoidCallback onTutorChat;
  final VoidCallback onImportSubtitle;
  final bool showEpisodeButton;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('英语听力'),
      actions: [
        if (showEpisodeButton)
          IconButton(
            icon: const Icon(Icons.playlist_play),
            tooltip: '选集',
            onPressed: onEpisodeSelect,
          ),
        IconButton(
          icon: const Icon(Icons.school),
          tooltip: 'AI 英语同桌',
          onPressed: onTutorChat,
        ),
        IconButton(
          icon: const Icon(Icons.subtitles),
          tooltip: '导入字幕',
          onPressed: onImportSubtitle,
        ),
        FavoritesBadge(onNavigate: onNavigateToFavorites),
        FlashcardBadge(onNavigate: onNavigateToFlashcards),
        PlayerPopupMenu(
          onVocabulary: onVocabulary,
          onCollocation: onCollocation,
          onTyping: onTyping,
          onTranslate: onTranslate,
          onAICollocation: onAICollocation,
          onTutorChat: onTutorChat,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}