import 'package:flutter_test/flutter_test.dart';
import 'package:english_listening/utils/async_guard.dart';

void main() {
  group('asyncGuard', () {
    test('returns result on success', () async {
      final result = await asyncGuard<int>(
        action: () async => 42,
      );
      expect(result, 42);
    });

    test('returns null on exception', () async {
      final result = await asyncGuard<int>(
        action: () async => throw Exception('test error'),
      );
      expect(result, isNull);
    });

    test('calls onError callback on exception', () async {
      String? capturedError;
      await asyncGuard<int>(
        action: () async => throw Exception('test error'),
        onError: (error) => capturedError = error,
      );
      expect(capturedError, isNotNull);
    });

    test('uses custom error message', () async {
      String? capturedError;
      await asyncGuard<int>(
        action: () async => throw Exception('original'),
        errorMessage: '自定义错误',
        onError: (error) => capturedError = error,
      );
      expect(capturedError, '自定义错误');
    });
  });

  group('asyncGuardVoid', () {
    test('completes on success', () async {
      var completed = false;
      await asyncGuardVoid(
        action: () async {
          completed = true;
        },
      );
      expect(completed, isTrue);
    });

    test('calls onError on exception', () async {
      String? capturedError;
      await asyncGuardVoid(
        action: () async => throw Exception('void error'),
        onError: (error) => capturedError = error,
      );
      expect(capturedError, isNotNull);
    });
  });
}