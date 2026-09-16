import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/sound_provider.dart';
import '../services/database_service.dart';
import '../services/timer_service.dart';
import '../services/sound_service.dart';
import '../widgets/background_image.dart';
import '../utils/constants.dart';

class CookingView extends StatefulWidget {
  final int recipeId;
  
  const CookingView({
    super.key,
    required this.recipeId,
  });

  @override
  State<CookingView> createState() => _CookingViewState();
}

class _CookingViewState extends State<CookingView> {
  final DatabaseService _dbService = DatabaseService();
  
  int _currentStep = 0;
  List<String> _steps = [];
  List<int> _timers = [];
  String _recipeName = '';
  
  bool _timerRunning = false;
  int _remainingSeconds = 0;
  Timer? _countdownTimer;
  bool _timerShouldStop = false;
  
  // ← جدید: برای حفظ تایمر در هنگام خروج
  bool _keepTimerOnExit = false;
  
  @override
  void initState() {
    super.initState();
    _loadRecipeDetails();
  }
  
  @override
  void dispose() {
    // ← تغییر: اگه کاربر خواسته تایمر حفظ بشه، پاکش نکن
    if (!_keepTimerOnExit) {
      _stopTimer();
      TimerService.cancelAllTimers();
      SoundService.stopAlarm();
    } else {
      // فقط تایمر UI رو متوقف کن، ولی تایمر پس‌زمینه (TimerService) بمونه
      _countdownTimer?.cancel();
      _timerShouldStop = true;
    }
    super.dispose();
  }
  
  Future<void> _loadRecipeDetails() async {
    // ← جدید: چک کن آیا قبلاً یه پخت در جریان بوده
    final prefs = await SharedPreferences.getInstance();
    final savedRecipeId = prefs.getInt('active_cooking_recipe_id');
    final savedStep = prefs.getInt('active_cooking_step');
    final savedRemaining = prefs.getInt('active_cooking_remaining');
    final savedTimestamp = prefs.getInt('active_cooking_timestamp');
    
    final data = await _dbService.getRecipeDetails(widget.recipeId);
    final recipe = data['recipe'];
    
    if (recipe != null) {
      setState(() {
        _recipeName = recipe['name'] as String;
        final stepsData = data['steps'] as List;
        _steps = stepsData.map((s) => s['description'] as String).toList();
        _timers = stepsData.map((s) => s['timer_minutes'] as int? ?? 0).toList();
        
        // ← جدید: اگه همین غذا و همون پخت قبلی بوده، بازیابی کن
        if (savedRecipeId == widget.recipeId && savedStep != null) {
          _currentStep = savedStep;
          
          // محاسبه زمان سپری شده از وقتی که خارج شدی
          if (savedRemaining != null && savedTimestamp != null) {
            final elapsed = (DateTime.now().millisecondsSinceEpoch - savedTimestamp) ~/ 1000;
            final newRemaining = savedRemaining - elapsed;
            if (newRemaining > 0) {
              _remainingSeconds = newRemaining;
            }
          }
        }
      });
      
      _updateStepDisplay();
    }
  }
  
  // ← جدید: ذخیره وضعیت پخت قبل از خروج
  Future<void> _saveCookingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_cooking_recipe_id', widget.recipeId);
    await prefs.setInt('active_cooking_step', _currentStep);
    await prefs.setInt('active_cooking_remaining', _remainingSeconds);
    await prefs.setInt('active_cooking_timestamp', DateTime.now().millisecondsSinceEpoch);
  }
  
  // ← جدید: پاک کردن وضعیت پخت
  Future<void> _clearCookingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_cooking_recipe_id');
    await prefs.remove('active_cooking_step');
    await prefs.remove('active_cooking_remaining');
    await prefs.remove('active_cooking_timestamp');
  }
  
  void _showExitDialog() {
    SoundService.stopAlarm();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('از پخت غذا خارج می‌شی؟'),
        content: Text(
          'مرحله ${_currentStep + 1} از ${_steps.length}.\n'
          'زمان باقی مونده: ${formatTime(_remainingSeconds)}',
        ),
        actions: [
          // دکمه ۱: لغو کامل (تایمر پاک می‌شه)
          TextButton(
            onPressed: () {
              _keepTimerOnExit = false;
              _clearCookingState();
              _stopTimer();
              TimerService.cancelAllTimers();
              Navigator.pop(context); // بستن dialog
              Navigator.pop(context); // خروج از صفحه
            },
            child: const Text('❌ لغو کامل'),
          ),
          // دکمه ۲: ادامه پخت (بمون توی صفحه)
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔙 پخت ادامه پیدا میکنه...'), duration: Duration(seconds: 2)),
              );
            },
            child: const Text('🔙 ادامه بدم'),
          ),
          // ← دکمه ۳ (جدید): خروج ولی تایمر فعال بمونه
          TextButton(
            onPressed: () async {
              _keepTimerOnExit = true;
              await _saveCookingState();
              Navigator.pop(context); // بستن dialog
              Navigator.pop(context); // خروج از صفحه
            },
            child: const Text('⏱️ خروج با حفظ تایمر'),
          ),
        ],
      ),
    );
  }
  
  void _updateStepDisplay() {
    if (_currentStep < _steps.length) {
      final timerSeconds = _timers[_currentStep];
      
      if (timerSeconds > 0) {
        // ← تغییر: اگه _remainingSeconds قبلاً ست شده (از بازیابی)، ازش استفاده کن
        if (_remainingSeconds <= 0) {
          _remainingSeconds = timerSeconds;
        }
        setState(() {});
        _startTimer();
      } else {
        setState(() {
          _timerRunning = false;
          _remainingSeconds = 0;
        });
      }
    } else {
      _finishCooking();
    }
  }
  
  void _startTimer() {
    if (_timerRunning) return;
    
    if (_remainingSeconds > 0) {
      _timerRunning = true;
      _timerShouldStop = false;
      
      // تنظیم تایمر پس‌زمینه
      TimerService.setTimer(
        stepId: _currentStep,
        seconds: _remainingSeconds,
        recipeName: _recipeName,
        stepDescription: _steps[_currentStep],
        onAlarmRing: () {
          _onTimerComplete();
        },
      );
      
      // تایمر شمارش معکوس برای UI
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerShouldStop) {
          timer.cancel();
          return;
        }
        
        if (_remainingSeconds <= 1) {
          timer.cancel();
          _onTimerComplete();
        } else {
          setState(() {
            _remainingSeconds--;
          });
        }
      });
      
      setState(() {});
    }
  }
  
  void _stopTimer() {
    _timerShouldStop = true;
    _timerRunning = false;
    _countdownTimer?.cancel();
    TimerService.stopTimer();
  }
  
  void _onTimerComplete() {
    if (!_timerRunning && _remainingSeconds <= 0) return;
    
    _timerRunning = false;
    _countdownTimer?.cancel();
    
    setState(() {});
    
    SoundService.playAlarmSound();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔔 زمان این مرحله تموم شد!'), duration: Duration(seconds: 3)),
      );
    }
  }
  
  void _stopTimerEarly() {
    SoundService.stopAlarm();
    _stopTimer();
    
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏩ تایمر متوقف شد. برو مرحله بعد'), duration: Duration(seconds: 2)),
    );
  }
  
  void _nextStep() {
    SoundService.stopAlarm();
    
    if (_timerRunning && _remainingSeconds > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ اول صبر کن تا زمان این مرحله تموم بشه!'), duration: Duration(seconds: 2)),
      );
      return;
    }
    
    _stopTimer();
    _currentStep++;
    _remainingSeconds = 0;
    _updateStepDisplay();
  }
  
  void _finishCooking() async {
    SoundService.stopAlarm();
    await _clearCookingState(); // ← پاک کردن وضعیت پخت
    await _dbService.updateLastCooked(widget.recipeId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🎉 آفرین! $_recipeName با موفقیت پخته شد!'), duration: Duration(seconds: 3)),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    
    final progressValue = _steps.isEmpty ? 0 : _currentStep / _steps.length;
    final hasTimer = _timers.isNotEmpty && _timers[_currentStep] > 0;
    final timeText = _timerRunning && _remainingSeconds > 0
        ? formatTime(_remainingSeconds)
        : (hasTimer ? formatTime(_timers[_currentStep]) : 'بدون تایمر');
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, size: 24),
                      onPressed: _showExitDialog,
                    ),
                    Expanded(
                      child: Text(
                        _recipeName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              const Divider(height: 10, color: Colors.transparent),
              Icon(Icons.restaurant_menu, size: 40, color: primaryColor),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 10, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'مرحله ${_currentStep + 1} از ${_steps.length}',
                    style: TextStyle(fontSize: 13, color: textColor),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.circle, size: 10, color: primaryColor),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 280,
                child: LinearProgressIndicator(
                  value: progressValue.toDouble(),
                  color: primaryColor,
                  backgroundColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 15),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        'مرحله ${_currentStep + 1} از ${_steps.length}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const Divider(height: 5, color: Colors.transparent),
                      Text(
                        _steps.isNotEmpty ? _steps[_currentStep] : '',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(25),
                  child: Text(
                    '⏱️ $timeText',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
              ),
              if (hasTimer && _timerRunning)
                ElevatedButton.icon(
                  onPressed: _stopTimerEarly,
                  icon: const Icon(Icons.stop_circle, size: 18, color: Colors.white),
                  label: const Text('تموم شد (زودتر)', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[400],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _nextStep,
                icon: const Icon(Icons.navigate_next, size: 18, color: Colors.white),
                label: Text(
                  _currentStep < _steps.length - 1 ? 'مرحله بعد' : 'اتمام پخت',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(180, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}