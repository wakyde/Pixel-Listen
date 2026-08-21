import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/plugin.dart';

void main() {
  test('plugin id should be unique', () {
    final plugin = EnglishListeningPlugin();
    expect(plugin.id, 'english_listening');
  });

  test('route path should start with /', () {
    final plugin = EnglishListeningPlugin();
    expect(plugin.routePath.startsWith('/'), isTrue);
  });

  test('plugin sort order should be positive', () {
    final plugin = EnglishListeningPlugin();
    expect(plugin.sortOrder, greaterThan(0));
  });
}