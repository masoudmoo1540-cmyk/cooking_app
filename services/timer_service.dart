import 'package:alarm2/alarm2.dart';
import 'package:flutter/material.dart';

class TimerService {
  static int? _currentAlarmId;
  
  static Future<bool> setTimer({
    required int stepId,
    required int seconds,
    required String recipeName,
    required String stepDescription,
    VoidCallback? onAlarmRing,
  }) async {
    if (_currentAlarmId != null) {
      await stopTimer();
    }
    
    if (seconds <= 0) {
      print('زمان تایمر صفر است، تنظیم نمیشود');
      return false;
    }
    
    final scheduledTime = DateTime.now().add(Duration(seconds: seconds));
    
    // ✅ نسخه درست بر اساس توضیحات VSCode
    final alarmSettings = AlarmSettings(
      id: stepId,
      dateTime: scheduledTime,
      assetAudioPath: 'assets/sounds/default_beep.mp3',  // ← اینجا assetAudioPath هست
      notificationTitle: '⏰ زمان مرحله تموم شد!',
      notificationBody: '$recipeName - $stepDescription',
      loopAudio: true,
      vibrate: true,
      volume: 1.0,
      fadeDuration: 0.0,
      enableNotificationOnKill: true,  // ← اینجا enableNotificationOnKill هست
      androidFullScreenIntent: true,
    );
    
    _currentAlarmId = stepId;
    
    try {
      final isSet = await Alarm2.set(alarmSettings: alarmSettings);
      
      if (isSet) {
        print('تایمر $seconds ثانیه برای مرحله $stepId تنظیم شد');
      } else {
        print('خطا در تنظیم تایمر');
      }
      
      return isSet;
    } catch (e) {
      print('خطا در تنظیم تایمر: $e');
      return false;
    }
  }
  
  static Future<void> stopTimer() async {
    if (_currentAlarmId != null) {
      try {
        await Alarm2.stop(_currentAlarmId!);
        _currentAlarmId = null;
        print('تایمر متوقف شد');
      } catch (e) {
        print('خطا در توقف تایمر: $e');
      }
    }
  }
  
  static Future<void> cancelAllTimers() async {
    try {
      await Alarm2.stopAll();
      _currentAlarmId = null;
      print('همه تایمرها لغو شدند');
    } catch (e) {
      print('خطا در لغو تایمرها: $e');
    }
  }
  
  static bool isTimerActive() {
    return _currentAlarmId != null;
  }
  
  static int? getCurrentAlarmId() {
    return _currentAlarmId;
  }
}