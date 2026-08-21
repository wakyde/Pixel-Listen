import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_db/shared_db.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class ReviewNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _notificationId = 1001;
  static const _channelId = 'flashcard_review';
  static const _channelName = '闪卡复习提醒';
  static const _channelDescription = '每日闪卡复习提醒';

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final hasPermission = await _requestPermission();
    if (hasPermission) {
      await scheduleDailyReview();
    }
  }

  static Future<bool> _requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();

    if (android != null) {
      await android.requestNotificationsPermission();
      return true;
    }
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  static Future<void> scheduleDailyReview({int hour = 9, int minute = 0}) async {
    try {
      final db = getAppDatabase();
      final now = DateTime.now();
      final cards = await db.select(db.flashcards).get();
      final dueCount = cards
          .where((c) => c.nextReviewAt.isBefore(now) || c.nextReviewAt == now)
          .length;

      await _plugin.cancel(id: _notificationId);

      if (dueCount == 0) return;

      final scheduledTime = _nextInstanceOf(hour, minute);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );
      const iosDetails = DarwinNotificationDetails();

      await _plugin.zonedSchedule(
        id: _notificationId,
        title: '闪卡复习提醒',
        body: '你有 $dueCount 张闪卡等待复习',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
          macOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      debugPrint('[ReviewNotification] Scheduled daily review at $hour:$minute, $dueCount cards due');
    } catch (e, st) {
      debugPrint('[ReviewNotification] Schedule failed: $e\n$st');
    }
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final local = tz.TZDateTime.local(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      hour,
      minute,
    );
    if (local.isBefore(DateTime.now())) {
      return local.add(const Duration(days: 1));
    }
    return local;
  }

  static void _onNotificationTap(NotificationResponse response) {
    debugPrint('[ReviewNotification] Tapped: ${response.payload}');
  }
}