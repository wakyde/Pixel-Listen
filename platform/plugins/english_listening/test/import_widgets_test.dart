import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/screens/import_widgets.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('renders title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SectionHeader(
              title: 'Test Title',
              icon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders with different title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SectionHeader(
              title: 'Another Title',
              icon: Icons.folder,
            ),
          ),
        ),
      );

      expect(find.text('Another Title'), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('supports long title text', (tester) async {
      const longTitle = 'This is a very long section header title that should still render';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SectionHeader(
              title: longTitle,
              icon: Icons.info,
            ),
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
    });
  });
}