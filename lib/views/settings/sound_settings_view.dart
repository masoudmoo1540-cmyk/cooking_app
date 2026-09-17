import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/sound_provider.dart';
import '../../services/sound_service.dart';
import '../../widgets/background_image.dart';

class SoundSettingsView extends StatefulWidget {
  const SoundSettingsView({super.key});

  @override
  State<SoundSettingsView> createState() => _SoundSettingsViewState();
}

class _SoundSettingsViewState extends State<SoundSettingsView> {
  String? _selectedSound;
  bool _soundEnabled = true;
  
  // مسیرهای پوشه‌های صدا
  final String _soundsDirDefault = 'assets/sounds/';
  final String _soundsDirUser = 'assets/sounds2/';
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _selectedSound = prefs.getString('selected_sound');
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', _soundEnabled);
    if (_selectedSound != null) {
      await prefs.setString('selected_sound', _selectedSound!);
    }
  }
  
  void _toggleMute() {
    setState(() {
      _soundEnabled = !_soundEnabled;
    });
    _saveSettings();
    SoundService.setSoundEnabled(_soundEnabled);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_soundEnabled ? '🔊 حالت بی صدا غیرفعال شد' : '🔇 حالت بی صدا فعال شد'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
  
  Future<void> _selectSound(String soundPath, String soundName) async {
    setState(() {
      _selectedSound = soundPath;
    });
    await _saveSettings();
    
    // پخش صدای تست
    await SoundService.playAlarmSound(soundPath: soundPath);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ آهنگ $soundName انتخاب شد'), backgroundColor: Colors.green),
      );
    }
  }
  
  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.audio,
    );
    
    if (result != null && result.files.single.path != null) {
      final sourcePath = result.files.single.path!;
      final originalName = result.files.single.name;
      
      // فایل رو واقعاً به یه مسیر دائمی داخل اپ کپی می‌کنیم (نه مسیر موقت پیکر)
      final appDir = await getApplicationDocumentsDirectory();
      final soundsDir = Directory('${appDir.path}/custom_sounds');
      if (!await soundsDir.exists()) {
        await soundsDir.create(recursive: true);
      }
      
      // اسم فایل با timestamp یکتا می‌شه: هر آپلود جدید = یه کانال نوتیفیکیشن
      // جدا با صدای درست خودش (چون صدای هر کانال بعد از ساخته شدن قفل می‌شه)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = originalName.contains('.') ? originalName.split('.').last : 'mp3';
      final destPath = '${soundsDir.path}/custom_$timestamp.$ext';
      
      await File(sourcePath).copy(destPath);
      
      setState(() {
        _selectedSound = destPath;
      });
      await _saveSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ فایل $originalName اضافه شد'), backgroundColor: Colors.green),
        );
      }
    }
  }
  
  Future<void> _deleteUserSound(String soundPath, String soundName) async {
    final file = File(soundPath);
    if (await file.exists()) {
      await file.delete();
      
      if (_selectedSound == soundPath) {
        setState(() {
          _selectedSound = null;
        });
        await _saveSettings();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ آهنگ $soundName حذف شد'), backgroundColor: Colors.green),
        );
        setState(() {});
      }
    }
  }
  
  Future<void> _testSound() async {
    if (_selectedSound != null && File(_selectedSound!).existsSync()) {
      await SoundService.playAlarmSound(soundPath: _selectedSound);
    } else {
      await SoundService.playAlarmSound();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔊 در حال پخش آهنگ...'), backgroundColor: Colors.blue),
    );
  }
  
  Future<void> _stopSound() async {
    await SoundService.stopAlarm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔇 صدای در حال پخش قطع شد'), backgroundColor: Colors.red),
    );
  }
  
  String _getDisplayName(String soundPath) {
    final name = soundPath.split('/').last;
    return name.replaceAll(RegExp(r'\.(mp3|wav|ogg|MP3|WAV|OGG)$'), '');
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    
    // لیست آهنگ‌های پیش‌فرض (از assets)
    final defaultSounds = [
      {'name': 'classic', 'path': '${_soundsDirDefault}classic.mp3'},
      {'name': 'gentle', 'path': '${_soundsDirDefault}gentle.mp3'},
      {'name': 'kitchen', 'path': '${_soundsDirDefault}kitchen.mp3'},
    ];
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('تنظیمات صدا'),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              SoundService.stopAlarm();
              Navigator.pop(context);
            },
          ),
          actions: [
            IconButton(
              icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: _soundEnabled ? Colors.white : Colors.red),
              onPressed: _toggleMute,
              tooltip: 'فعال/غیرفعال کردن صدا',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // آهنگ‌های پیش‌فرض
              Align(
                alignment: Alignment.centerRight,
                child: Text('🎵 آهنگ‌های پیش‌فرض',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 8),
              ...defaultSounds.map((sound) => _buildSoundItem(
                    sound['name']!,
                    sound['path']!,
                    false,
                    primaryColor,
                    textColor,
                    cardBg,
                  )),
              
              const SizedBox(height: 20),
              
              // دکمه افزودن آهنگ جدید
              ElevatedButton.icon(
                onPressed: _pickAudioFile,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('افزودن آهنگ جدید'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // دکمه‌های تست و قطع
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: _testSound,
                    icon: const Icon(Icons.volume_up, size: 18),
                    label: const Text('تست صدا'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  ElevatedButton.icon(
                    onPressed: _stopSound,
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('قطع صدا'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // کارت وضعیت صدا
              Card(
                elevation: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off,
                          color: _soundEnabled ? Colors.green : Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        _soundEnabled ? '🔊 صدا فعال است' : '🔇 حالت بی صدا فعال است',
                        style: TextStyle(color: textColor),
                      ),
                      const Spacer(),
                      Switch(
                        value: _soundEnabled,
                        onChanged: (_) => _toggleMute(),
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // آهنگ فعلی
              Card(
                elevation: 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.music_note, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '🎵 آهنگ فعلی: ${_selectedSound != null ? _getDisplayName(_selectedSound!) : 'پیش‌فرض (زنگ سیستمی)'}',
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSoundItem(String name, String path, bool isUser, Color primaryColor, Color textColor, Color cardBg) {
    final isSelected = _selectedSound == path;
    
    return GestureDetector(
      onTap: () => _selectSound(path, name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : cardBg,
          border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.music_note, size: 24, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: TextStyle(fontSize: 16, color: textColor)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 22),
            if (isUser)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteUserSound(path, name),
                tooltip: 'حذف آهنگ',
              ),
          ],
        ),
      ),
    );
  }
}