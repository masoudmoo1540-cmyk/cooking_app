import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimerService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  static int _currentNotificationId = 0;

  static Future<void> init() async {
    if (_initialized) return;
    
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
    
    _initialized = true;
  }

  static Future<bool> setTimer({
    required int stepId,
    required int seconds,
    required String recipeName,
    required String stepDescription,
    VoidCallback? onAlarmRing,
  }) async {
    if (seconds <= 0) return false;
    
    await init();
    await stopTimer();
    
    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    _currentNotificationId = stepId;
    
    // ⭐ صدا از raw resource پخش می‌شه + لوپ می‌شه
    // ⚠️ const حذف شد چون additionalFlags قابل const نیست
    final androidDetails = AndroidNotificationDetails(
      'cooking_timer_channel',
      'تایمر پخت',
      channelDescription: 'آلارم تایمر پخت غذا',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      additionalFlags: Int32List.fromList([4]),
      ongoing: false,
      autoCancel: true,
    );
    
    final notificationDetails = NotificationDetails(android: androidDetails);
    
    try {
      await _notifications.zonedSchedule(
        _currentNotificationId,
        '⏰ زمان مرحله تموم شد!',
        '$recipeName - $stepDescription',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'timer_done',
      );
      
      debugPrint('تایمر $seconds ثانیه تنظیم شد');
      return true;
    } catch (e) {
      debugPrint('خطا در تنظیم تایمر: $e');
      return false;
    }
  }

  static Future<void> stopTimer() async {
    if (_currentNotificationId != 0) {
      await _notifications.cancel(_currentNotificationId);
      _currentNotificationId = 0;
      debugPrint('تایمر متوقف شد');
    }
  }

  static Future<void> cancelAllTimers() async {
    await _notifications.cancelAll();
    _currentNotificationId = 0;
    debugPrint('همه تایمرها لغو شدند');
  }

  static bool isTimerActive() {
    return _currentNotificationId != 0;
  }

  static int? getCurrentAlarmId() {
    return _currentNotificationId != 0 ? _currentNotificationId : null;
  }
}