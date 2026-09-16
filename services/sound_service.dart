import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static bool _isSoundEnabled = true;
  static String? _selectedSoundPath;
  
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _selectedSoundKey = 'selected_sound';
  
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isSoundEnabled = prefs.getBool(_soundEnabledKey) ?? true;
    _selectedSoundPath = prefs.getString(_selectedSoundKey);
  }
  
  static Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
    if (!enabled) {
      await stopAlarm();
    }
  }
  
  static bool isSoundEnabled() => _isSoundEnabled;
  
  static Future<void> playAlarmSound({String? soundPath}) async {
    if (!_isSoundEnabled) return;
    
    final pathToPlay = soundPath ?? _selectedSoundPath;
    
    try {
      if (pathToPlay != null && File(pathToPlay).existsSync()) {
        await _audioPlayer.stop();
        await _audioPlayer.setFilePath(pathToPlay);
        await _audioPlayer.play();
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setAsset('assets/sounds/classic.mp3');
        await _audioPlayer.play();
      }
    } catch (e) {
      print('خطا در پخش صدا: $e');
    }
  }
  
  static Future<void> stopAlarm() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print('خطا در قطع صدا: $e');
    }
  }
  
  static Future<void> saveSelectedSound(String soundPath) async {
    _selectedSoundPath = soundPath;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedSoundKey, soundPath);
  }
  
  static String? getSelectedSound() => _selectedSoundPath;
}