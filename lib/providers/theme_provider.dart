import 'package:flutter/material.dart';
import '../models/theme_model.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService = ThemeService();
  ThemeModel _currentTheme = ThemeModel.themes[0]; // روشن (پیش‌فرض)
  
  ThemeModel get currentTheme => _currentTheme;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  Future<void> _loadTheme() async {
    final savedTheme = await _themeService.getSavedTheme();
    final theme = ThemeModel.themes.firstWhere(
      (t) => t.name == savedTheme,
      orElse: () => ThemeModel.themes[0],
    );
    _currentTheme = theme;
    notifyListeners();
  }
  
  Future<void> changeTheme(String themeName) async {
    final theme = ThemeModel.themes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => ThemeModel.themes[0],
    );
    
    _currentTheme = theme;
    await _themeService.saveTheme(themeName);
    notifyListeners();
  }
  
  // گرفتن رنگ‌های تم فعلی (مثل get_colors در ThemeManager)
  Map<String, dynamic> getColors() {
    return {
      'bgcolor': _currentTheme.bgColor,
      'card_bg': _currentTheme.cardBg,
      'text_color': _currentTheme.textColor,
      'primary': _currentTheme.primary,
      'secondary': _currentTheme.secondary,
      'gradient_start': _currentTheme.gradientStart,
      'gradient_end': _currentTheme.gradientEnd,
      'progress_color': _currentTheme.progressColor,
      'snackbar_bg': _currentTheme.snackbarBg,
    };
  }
  
  // گرفتن گرادینت (مثل get_gradient در ThemeManager)
  LinearGradient getGradient() {
    return _currentTheme.gradient;
  }
}