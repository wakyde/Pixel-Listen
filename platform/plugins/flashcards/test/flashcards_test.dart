import 'package:flutter_test/flutter_test.dart';
import 'package:flashcards/plugin.dart';

void main() {
  test('plugin id should be unique', () {
    final plugin = FlashcardsPlugin();
    expect(plugin.id, 'flashcards');
  });

  test('route path should start with /', () {
    final plugin = FlashcardsPlugin();
    expect(plugin.routePath.startsWith('/'), isTrue);
  });

  test('plugin sort order should be positive', () {
    final plugin = FlashcardsPlugin();
    expect(plugin.sortOrder, greaterThan(0));
  });
}