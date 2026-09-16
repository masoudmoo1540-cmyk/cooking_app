import 'package:flutter/material.dart';

class AppColors {
  // رنگ‌های اصلی (مشابه theme.py در Flet)
  static const Color primaryOrange = Color(0xFFFF7B00);
  static const Color secondaryOrange = Color(0xFFFF9F4A);
  static const Color successGreen = Color(0xFF06D6A0);
  static const Color errorRed = Color(0xFFEF476F);
  
  // رنگ‌های متن
  static const Color textDark = Color(0xFF2B2D42);
  static const Color textLight = Color(0xFF8D99AE);
}

class AppTheme {
  // هدر گرادینت (مثل gradient_header در Flet)
  static LinearGradient primaryGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF9F4A), Color(0xFFFF7B00)],
  );
  
  // استایل دکمه اصلی (مثل button_style در ThemeManager)
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primaryOrange,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    minimumSize: const Size(180, 45),
  );
  
  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey[200],
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );
  
  // استایل کارت (مثل card_style در theme.py)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        spreadRadius: 0.5,
        blurRadius: 12,
        color: Colors.grey.withOpacity(0.3),
      ),
    ],
  );
  
  // تم لایت پیش‌فرض
  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Vazirmatn',
    primaryColor: AppColors.primaryOrange,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryOrange,
      secondary: AppColors.secondaryOrange,
      error: AppColors.errorRed,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primaryOrange,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    cardTheme: CardThemeData(  // ✅
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.primaryOrange, width: 2),
      ),
    ),
  );
}

// ثابت‌های عمومی
class AppConstants {
  static const String dbName = 'recipes.db';
  static const String themeConfigFile = 'theme_config.json';
  static const String soundsConfigFile = 'sounds_config.json';
  static const String backgroundConfigFile = 'background_config.json';
}

// توابع کمکی فرمت زمان (مثل format_time در cooking_view)
String formatTime(int seconds) {
  if (seconds <= 0) return 'در حال اتمام';
  
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final secs = seconds % 60;
  
  final parts = <String>[];
  if (hours > 0) parts.add('$hours ساعت');
  if (minutes > 0) parts.add('$minutes دقیقه');
  if (secs > 0) parts.add('$secs ثانیه');
  
  return parts.isEmpty ? 'کمتر از یک ثانیه' : parts.join(' ');
}