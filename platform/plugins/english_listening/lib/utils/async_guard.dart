import 'package:flutter/material.dart';

typedef AsyncCallback<T> = Future<T> Function();

Future<T?> asyncGuard<T>({
  required AsyncCallback<T> action,
  String? errorMessage,
  void Function(String error)? onError,
  bool showSnackBar = false,
  GlobalKey<ScaffoldMessengerState>? messengerKey,
}) async {
  try {
    return await action();
  } catch (e, st) {
    debugPrint('AsyncGuard error: $e\n$st');

    final message = errorMessage ?? '操作失败，请重试';

    if (showSnackBar && messengerKey?.currentState != null) {
      messengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '确定',
            onPressed: () => messengerKey.currentState?.hideCurrentSnackBar(),
          ),
        ),
      );
    }

    onError?.call(message);
    return null;
  }
}

Future<void> asyncGuardVoid({
  required Future<void> Function() action,
  String? errorMessage,
  void Function(String error)? onError,
  bool showSnackBar = false,
  GlobalKey<ScaffoldMessengerState>? messengerKey,
}) async {
  try {
    await action();
  } catch (e, st) {
    debugPrint('AsyncGuard error: $e\n$st');

    final message = errorMessage ?? '操作失败，请重试';

    if (showSnackBar && messengerKey?.currentState != null) {
      messengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: '确定',
            onPressed: () => messengerKey.currentState?.hideCurrentSnackBar(),
          ),
        ),
      );
    }

    onError?.call(message);
  }
}