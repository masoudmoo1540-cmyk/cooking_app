import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SoundProvider extends ChangeNotifier {
  bool _isSoundEnabled = true;
  String? _selectedSound;
  
  bool get isSoundEnabled => _isSoundEnabled;
  String? get selectedSound => _selectedSound;
  
  SoundProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    await SoundService.init();
    _isSoundEnabled = SoundService.isSoundEnabled();
    _selectedSound = SoundService.getSelectedSound();
    notifyListeners();
  }
  
  Future<void> toggleSound() async {
    _isSoundEnabled = !_isSoundEnabled;
    await SoundService.setSoundEnabled(_isSoundEnabled);
    
    if (!_isSoundEnabled) {
      await SoundService.stopAlarm();
    }
    
    notifyListeners();
  }
  
  Future<void> selectSound(String soundPath) async {
    _selectedSound = soundPath;
    await SoundService.saveSelectedSound(soundPath);
    notifyListeners();
  }
  
  Future<void> playTestSound() async {
    await SoundService.playAlarmSound();
  }
  
  Future<void> stopSound() async {
    await SoundService.stopAlarm();
  }
}