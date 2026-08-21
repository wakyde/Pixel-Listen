import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/models/subtitle.dart';
import 'package:english_listening/widgets/player/memo_card_template_panel.dart';

Widget wrapWithMaterial(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

void main() {
  final sampleCue = SubtitleCue(
    id: '1',
    start: const Duration(seconds: 1),
    end: const Duration(seconds: 3),
    text: 'I ran into my old friend at the grocery store.',
  );

  final sampleMeta = MemorizationMeta(
    score: 8.0,
    reason: '包含常用口语搭配',
    highlights: ['ran into', 'grocery store'],
    scenario: '描述偶遇场景',
    isAiEnhanced: true,
  );

  group('MemoCardTemplatePanel', () {
    testWidgets('shows loading indicator when loading', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
          isLoading: true,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
          memorizationMeta: sampleMeta,
        ),
      ));

      expect(find.text(sampleCue.text), findsAtLeastNWidgets(1));
    });

    testWidgets('shows score badge', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
          memorizationMeta: sampleMeta,
        ),
      ));

      expect(find.text('8.0'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
    });

    testWidgets('shows template content when provided', (tester) async {
      final template = MemoCardTemplate(
        clozeText: 'I ______ my old friend at the grocery store.',
        hint: '碰见',
        keyPhrases: [
          KeyPhrase(phrase: 'ran into', meaning: '偶遇'),
        ],
        usageNote: '用于描述意外碰见某人',
      );

      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
          memorizationMeta: sampleMeta,
          template: template,
        ),
      ));

      expect(find.text('点击翻转查看答案'), findsOneWidget);
      expect(find.text('I ______ my old friend at the grocery store.'), findsOneWidget);
      expect(find.text('提示：碰见'), findsOneWidget);
      expect(find.text('固定搭配'), findsNothing);
    });

    testWidgets('has action buttons', (tester) async {
      bool favoritesTapped = false;
      bool ankiTapped = false;

      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
          memorizationMeta: sampleMeta,
          onAddToFavorites: () => favoritesTapped = true,
          onAddToAnki: () => ankiTapped = true,
        ),
      ));

      expect(find.text('加入收藏'), findsOneWidget);
      expect(find.text('记忆模板'), findsOneWidget);

      await tester.tap(find.text('加入收藏'));
      expect(favoritesTapped, isTrue);

      await tester.tap(find.text('记忆模板'));
      expect(ankiTapped, isTrue);
    });

    testWidgets('shows empty state without template or loading', (tester) async {
      await tester.pumpWidget(wrapWithMaterial(
        MemoCardTemplatePanel(
          cue: sampleCue,
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('加入收藏'), findsOneWidget);
      expect(find.text('记忆模板'), findsOneWidget);
    });
  });
}