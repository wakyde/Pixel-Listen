import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'screens/review_screen.dart';
import 'screens/flashcard_list_screen.dart';
import 'screens/stats_screen.dart';
import 'services/notification_service.dart';

class FlashcardsPlugin extends PlatformPlugin {
  @override
  String get id => 'flashcards';

  @override
  String get name => '闪卡复习';

  @override
  String get description => 'SRS 间隔复习、搭配闪卡、AI 生成';

  @override
  IconData get icon => Icons.auto_stories;

  @override
  String get routePath => '/flashcards';

  @override
  WidgetBuilder get pageBuilder => (context) => const FlashcardsHomeScreen();

  @override
  int get sortOrder => 2;
}

class FlashcardsHomeScreen extends StatefulWidget {
  const FlashcardsHomeScreen({super.key});

  @override
  State<FlashcardsHomeScreen> createState() => _FlashcardsHomeScreenState();
}

class _FlashcardsHomeScreenState extends State<FlashcardsHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    ReviewNotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ReviewScreen(),
          FlashcardListScreen(),
          StatsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.school),
            label: '复习',
          ),
          NavigationDestination(
            icon: Icon(Icons.style),
            label: '管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: '统计',
          ),
        ],
      ),
    );
  }
}