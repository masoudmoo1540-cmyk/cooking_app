import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'database_service.dart';

class MealSuggestionService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  static const String _enabledKey = 'meal_suggestion_enabled';
  static const String _hour1Key = 'meal_suggestion_hour1';
  static const String _minute1Key = 'meal_suggestion_minute1';
  static const String _hour2Key = 'meal_suggestion_hour2';
  static const String _minute2Key = 'meal_suggestion_minute2';
  
  static const int _notifId1 = 1001;
  static const int _notifId2 = 1002;

  // ========== مقداردهی اولیه ==========
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

  // ========== چک کردن وضعیت فعال بودن (پیش‌فرض: غیرفعال) ==========
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  // ========== دریافت ساعت‌های ذخیره شده ==========
  static Future<Map<String, TimeOfDay?>> getSavedTimes() async {
    final prefs = await SharedPreferences.getInstance();
    
    TimeOfDay? time1;
    TimeOfDay? time2;
    
    final h1 = prefs.getInt(_hour1Key);
    final m1 = prefs.getInt(_minute1Key);
    if (h1 != null && m1 != null) {
      time1 = TimeOfDay(hour: h1, minute: m1);
    }
    
    final h2 = prefs.getInt(_hour2Key);
    final m2 = prefs.getInt(_minute2Key);
    if (h2 != null && m2 != null) {
      time2 = TimeOfDay(hour: h2, minute: m2);
    }
    
    return {'time1': time1, 'time2': time2};
  }

  // ========== فعال‌سازی پیشنهاد غذا ==========
  // خروجی: true اگر موفق، false اگر غذا نداشت
  static Future<bool> enableSuggestions({
    required TimeOfDay time1,
    required TimeOfDay time2,
  }) async {
    await init();
    
    // گرفتن لیست غذاها
    final db = DatabaseService();
    final recipes = await db.getAllRecipes();
    
    if (recipes.isEmpty) {
      return false;
    }
    
    // ذخیره در SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_hour1Key, time1.hour);
    await prefs.setInt(_minute1Key, time1.minute);
    await prefs.setInt(_hour2Key, time2.hour);
    await prefs.setInt(_minute2Key, time2.minute);
    
    // لغو نوتیفیکیشن‌های قدیمی
    await _notifications.cancel(_notifId1);
    await _notifications.cancel(_notifId2);
    
    final recipeNames = recipes.map((r) => r['name'] as String).toList();
    
    await _scheduleNotification(
      id: _notifId1,
      time: time1,
      recipeNames: recipeNames,
    );
    
    await _scheduleNotification(
      id: _notifId2,
      time: time2,
      recipeNames: recipeNames,
    );
    
    return true;
  }

  // ========== غیرفعال‌سازی ==========
  static Future<void> disableSuggestions() async {
    await _notifications.cancel(_notifId1);
    await _notifications.cancel(_notifId2);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  // ========== زمان‌بندی یک نوتیفیکیشن ==========
  static Future<void> _scheduleNotification({
    required int id,
    required TimeOfDay time,
    required List<String> recipeNames,
  }) async {
    final recipe = recipeNames[DateTime.now().microsecond % recipeNames.length];
    final mealName = time.hour < 15 ? 'ناهار' : 'شام';
    
    final title = '🍳 وقت آشپزیه!';
    final body = 'برای $mealName به نظرت «$recipe» درست کنیم؟';
    
    const androidDetails = AndroidNotificationDetails(
      'meal_suggestion_channel',
      'پیشنهاد غذا',
      channelDescription: 'پیشنهاد غذاهای روزانه',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.reminder,
    );
    
    const notificationDetails = NotificationDetails(android: androidDetails);
    
    final scheduledTime = _nextInstanceOfTime(time.hour, time.minute);
    
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'meal_suggestion',
    );
  }

  // ========== محاسبه‌ی زمان بعدی ==========
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }

  // ========== تست دستی ==========
  static Future<void> sendTestNotification() async {
    await init();
    
    final db = DatabaseService();
    final recipes = await db.getAllRecipes();
    
    if (recipes.isEmpty) return;
    
    final recipe = recipes[DateTime.now().millisecond % recipes.length];
    final name = recipe['name'] as String;
    
    const androidDetails = AndroidNotificationDetails(
      'meal_suggestion_channel',
      'پیشنهاد غذا',
      channelDescription: 'پیشنهاد غذاهای روزانه',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    
    await _notifications.show(
      9999,
      '🍳 تست پیشنهاد غذا',
      'برای ناهار به نظرت «$name» درست کنیم؟',
      const NotificationDetails(android: androidDetails),
    );
  }
}