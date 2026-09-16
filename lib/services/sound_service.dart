import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isSoundEnabled = true;
  static String? _selectedSoundPath;
  
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _selectedSoundKey = 'selected_sound';
  
  // مقداردهی اولیه
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _selectedSoundPath = prefs.getString(_selectedSoundKey);
    
    // تنظیم پلیر برای پخش در پس‌زمینه
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
  }
  
  // فعال/غیرفعال کردن صدا
  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
    
    if (!enabled) {
      stopAlarm();
    }
    
    print('صدا ${enabled ? 'فعال' : 'غیرفعال'} شد');
  }
  
  // بررسی وضعیت صدا
  static bool isSoundEnabled() {
    return _isSoundEnabled;
  }
  
  // پخش صدای آلارم
  static Future<void> playAlarmSound({String? soundPath}) async {
    if (!_isSoundEnabled) {
      print('صدا غیرفعال است، پخش نمیشود');
      return;
    }
    
    final pathToPlay = soundPath ?? _selectedSoundPath;
    
    try {
      if (pathToPlay != null && File(pathToPlay).existsSync()) {
        // پخش فایل صوتی انتخاب شده
        await _audioPlayer.stop();
        await _audioPlayer.play(DeviceFileSource(pathToPlay));
        print('در حال پخش: $pathToPlay');
      } else {
        // پخش صدای پیش‌فرض (بوق سیستمی)
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('sounds/default_beep.mp3'));
        print('پخش صدای پیش‌فرض');
      }
    } catch (e) {
      print('خطا در پخش صدا: $e');
      // تلاش برای پخش صدای پیش‌فرض از assets
      try {
        await _audioPlayer.play(AssetSource('sounds/default_beep.mp3'));
      } catch (e2) {
        print('خطا در پخش صدای پیش‌فرض: $e2');
      }
    }
  }
  
  // قطع صدای آلارم
  static Future<void> stopAlarm() async {
    try {
      await _audioPlayer.stop();
      print('صدای آلارم قطع شد');
    } catch (e) {
      print('خطا در قطع صدا: $e');
    }
  }
  
  // ذخیره آهنگ انتخاب شده
  static Future<void> saveSelectedSound(String soundPath) async {
    _selectedSoundPath = soundPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSoundKey, soundPath);
  }
  
  // دریافت آهنگ انتخاب شده
  static String? getSelectedSound() {
    return _selectedSoundPath;
  }
}