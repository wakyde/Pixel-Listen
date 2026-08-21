import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/constants.dart';
import 'package:english_listening/providers/media_category_provider.dart';
import 'package:english_listening/screens/import/category_bar.dart';

final _testCategories = [
  const MediaCategory(
    id: 'local',
    name: '本地视频',
    type: CategoryType.local,
    iconName: IconName.folder,
    sortOrder: 0,
  ),
  const MediaCategory(
    id: 'youtube',
    name: 'YouTube',
    type: CategoryType.online,
    iconName: IconName.tv,
    sortOrder: 1,
    platform: PlatformName.youtube,
  ),
];

void main() {
  group('CategoryBar', () {
    testWidgets('renders category chips', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaCategoryProvider.overrideWith((ref) => Future.value(_testCategories)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: const CategoryBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('本地视频'), findsOneWidget);
      expect(find.text('YouTube'), findsOneWidget);
    });

    testWidgets('selects category on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mediaCategoryProvider.overrideWith((ref) => Future.value(_testCategories)),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: const CategoryBar(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
    });
  });
}