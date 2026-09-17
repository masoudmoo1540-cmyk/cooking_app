import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// سرویس مدیریت مجوزهای لازم برای اجرای درست تایمر در پس‌زمینه
/// (حتی وقتی اپ کاملاً از Task Manager پاک بشه)
class PermissionService {
  static const _setupDoneKey = 'permission_setup_done';

  // ---------- وضعیت ویزارد اولیه ----------

  /// آیا ویزارد تنظیمات اولیه قبلاً به کاربر نشون داده شده؟
  static Future<bool> isSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_setupDoneKey) ?? false;
  }

  static Future<void> markSetupDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_setupDoneKey, true);
  }

  // ---------- بهینه‌سازی باتری ----------

  /// آیا اپ از بهینه‌سازی باتری معاف شده؟
  static Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted;
  }

  /// نمایش دیالوگ استاندارد اندروید برای معافیت از بهینه‌سازی باتری
  static Future<bool> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }

  // ---------- زنگ دقیق (Android 12+) ----------

  static Future<bool> isExactAlarmGranted() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.status;
    return status.isGranted;
  }

  static Future<bool> requestExactAlarm() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.scheduleExactAlarm.request();
    return status.isGranted;
  }

  // ---------- نوتیفیکیشن (Android 13+) ----------

  static Future<bool> requestNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ---------- Autostart شیائومی (MIUI) ----------

  /// باز کردن مستقیم صفحه‌ی Autostart توی امنیت شیائومی.
  /// روی گوشی‌های غیرشیائومی این اکتیویتی وجود نداره و بی‌سروصدا fail می‌شه —
  /// یعنی نشون دادن دکمه‌ش برای همه‌ی کاربرا مشکلی نداره.
  static Future<bool> openXiaomiAutoStartSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      const intent = AndroidIntent(
        action: 'action_main',
        category: 'android.intent.category.launcher',
        componentName:
            'com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity',
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
      return true;
    } on PlatformException {
      return false; // این گوشی شیائومی نیست یا این صفحه رو نداره
    } catch (_) {
      return false;
    }
  }

  /// یه چک کلی: همه‌ی مجوزهای اصلی گرفته شدن یا نه (برای نشون دادن/ندادن بنر یادآوری)
  static Future<bool> allCriticalPermissionsGranted() async {
    final battery = await isBatteryOptimizationIgnored();
    final alarm = await isExactAlarmGranted();
    return battery && alarm;
  }
}
