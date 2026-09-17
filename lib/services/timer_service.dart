import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'native_bridge.dart';

class TimerService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static int _currentNotificationId = 0;

  // هر آهنگِ پیش‌فرض یه کانال جداگونه با صدای خودش داره.
  // اسم‌ها باید دقیقاً با اسم فایل صوتی توی android/app/src/main/res/raw/ یکی باشه (بدون پسوند).
  static const Map<String, String> _channelBySound = {
    'classic': 'cooking_timer_classic_v2',
    'gentle': 'cooking_timer_gentle_v2',
    'kitchen': 'cooking_timer_kitchen_v2',
  };

  // کانال‌های اختصاصیِ صدای دلخواه کاربر که توی همین اجرا ساخته شدن
  static final Set<String> _createdCustomChannels = {};

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onNotificationResponse,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _createDefaultChannels();

    _initialized = true;
  }

  // ساخت کانال‌های ۳ آهنگ پیش‌فرض (صداشون همیشه از قبل مشخصه)
  static Future<void> _createDefaultChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    for (final entry in _channelBySound.entries) {
      final soundName = entry.key;
      final channelId = entry.value;

      await androidPlugin.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          'تایمر پخت ($soundName)',
          description: 'آلارم تایمر پخت غذا',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          audioAttributesUsage: AudioAttributesUsage.alarm,
          enableVibration: true,
        ),
      );
    }
  }

  // یه هش ساده و پایدار (FNV-1a) برای ساختن آیدی یکتای کانال از روی مسیر فایل.
  // چون هر فایل دلخواه، مسیر یکتای خودش رو داره (به لطف timestamp توی اسم فایل)،
  // هر آپلود جدید یه کانال جدا و صدای درست خودش رو می‌گیره.
  static String _stableHash(String input) {
    int hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  // بر اساس آهنگی که کاربر انتخاب کرده، کانال درست رو برمی‌گردونه.
  // اگه یکی از ۳ آهنگ پیش‌فرضه → کانال از‌قبل‌ساخته‌شده.
  // اگه فایل دلخواه کاربره → کانال اختصاصی‌ش رو (در صورت نیاز) لحظه‌ای می‌سازه.
  static Future<String> _resolveChannelId() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getString('selected_sound') ?? '';

    final fileName = selected
        .split('/')
        .last
        .replaceAll(RegExp(r'\.(mp3|wav|ogg)$', caseSensitive: false), '');

    if (_channelBySound.containsKey(fileName)) {
      return _channelBySound[fileName]!;
    }

    if (selected.isNotEmpty && File(selected).existsSync()) {
      final channelId = 'cooking_timer_custom_${_stableHash(selected)}';

      if (!_createdCustomChannels.contains(channelId)) {
        final contentUri = await NativeBridge.getContentUriForFile(selected);

        if (contentUri != null) {
          final androidPlugin = _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          await androidPlugin?.createNotificationChannel(
            AndroidNotificationChannel(
              channelId,
              'تایمر پخت (صدای دلخواه)',
              description: 'آلارم تایمر پخت غذا با صدای انتخابی کاربر',
              importance: Importance.max,
              playSound: true,
              sound: UriAndroidNotificationSound(contentUri),
              audioAttributesUsage: AudioAttributesUsage.alarm,
              enableVibration: true,
            ),
          );
          _createdCustomChannels.add(channelId);
        } else {
          debugPrint('نشد content URI برای فایل دلخواه ساخته بشه، از classic استفاده می‌شه');
          return _channelBySound['classic']!;
        }
      }
      return channelId;
    }

    return _channelBySound['classic']!;
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

    final scheduledTime =
        tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    _currentNotificationId = stepId + 1; // چون ۰ یعنی «تایمر فعالی نیست»

    final channelId = await _resolveChannelId();

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'تایمر پخت',
      channelDescription: 'آلارم تایمر پخت غذا',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      fullScreenIntent: true,
      autoCancel: true,
      ongoing: false,
      actions: const [
        AndroidNotificationAction(
          'stop_alarm_action',
          '🔇 قطع کن',
          cancelNotification: true,
        ),
      ],
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

      debugPrint('تایمر $seconds ثانیه با کانال $channelId تنظیم شد');
      return true;
    } catch (e) {
      debugPrint('خطا در تنظیم تایمر: $e');
      return false;
    }
  }

  @pragma('vm:entry-point')
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_alarm_action') {
      debugPrint('کاربر آلارم رو مستقیم از روی نوتیفیکیشن قطع کرد');
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

  static bool isTimerActive() => _currentNotificationId != 0;

  static int? getCurrentAlarmId() =>
      _currentNotificationId != 0 ? _currentNotificationId : null;
}
