import 'package:flutter/material.dart';

class ThemeModel {
  final String name;
  final Color bgColor;
  final Color cardBg;
  final Color textColor;
  final Color primary;
  final Color secondary;
  final Color gradientStart;
  final Color gradientEnd;
  final Color progressColor;
  final Color snackbarBg;
  
  ThemeModel({
    required this.name,
    required this.bgColor,
    required this.cardBg,
    required this.textColor,
    required this.primary,
    required this.secondary,
    required this.gradientStart,
    required this.gradientEnd,
    required this.progressColor,
    required this.snackbarBg,
  });
  
  // لیست تمام تم‌ها (مطابق با theme_manager.py)
  static List<ThemeModel> get themes => [
    ThemeModel(
      name: 'روشن (پیش‌فرض)',
      bgColor: const Color(0xFFFff9F5),
      cardBg: Colors.white,
      textColor: const Color(0xFF2B2D42),
      primary: const Color(0xFFFF7B00),
      secondary: const Color(0xFFFF9F4A),
      gradientStart: const Color(0xFFFF9F4A),
      gradientEnd: const Color(0xFFFF7B00),
      progressColor: Colors.orange.shade600,
      snackbarBg: Colors.green,
    ),
    ThemeModel(
      name: 'تاریک (شب)',
      bgColor: const Color(0xFF1A1A2E),
      cardBg: const Color(0xFF16213E),
      textColor: const Color(0xFFEEEEEE),
      primary: const Color(0xFFE94560),
      secondary: const Color(0xFF533483),
      gradientStart: const Color(0xFFE94560),
      gradientEnd: const Color(0xFF533483),
      progressColor: Colors.pink.shade400,
      snackbarBg: Colors.green.shade700,
    ),
    ThemeModel(
      name: 'طبیعت (سبز)',
      bgColor: const Color(0xFFF0F7E6),
      cardBg: Colors.white,
      textColor: const Color(0xFF2D4A22),
      primary: const Color(0xFF4CAF50),
      secondary: const Color(0xFF81C784),
      gradientStart: const Color(0xFF66BB6A),
      gradientEnd: const Color(0xFF4CAF50),
      progressColor: Colors.green.shade600,
      snackbarBg: Colors.green,
    ),
    ThemeModel(
      name: 'صورتی (شیرین)',
      bgColor: const Color(0xFFFFF0F5),
      cardBg: Colors.white,
      textColor: const Color(0xFF6B2D5C),
      primary: const Color(0xFFFF69B4),
      secondary: const Color(0xFFFFB6C1),
      gradientStart: const Color(0xFFFF85C1),
      gradientEnd: const Color(0xFFFF69B4),
      progressColor: Colors.pink.shade400,
      snackbarBg: Colors.pink.shade700,
    ),
    ThemeModel(
      name: 'آبی (دریایی)',
      bgColor: const Color(0xFFE8F4FD),
      cardBg: Colors.white,
      textColor: const Color(0xFF0D3B66),
      primary: const Color(0xFF2196F3),
      secondary: const Color(0xFF64B5F6),
      gradientStart: const Color(0xFF42A5F5),
      gradientEnd: const Color(0xFF2196F3),
      progressColor: Colors.blue.shade600,
      snackbarBg: Colors.blue.shade700,
    ),
    ThemeModel(
      name: 'بنفش (شاهانه)',
      bgColor: const Color(0xFFF3E8FF),
      cardBg: Colors.white,
      textColor: const Color(0xFF4A148C),
      primary: const Color(0xFF9C27B0),
      secondary: const Color(0xFFCE93D8),
      gradientStart: const Color(0xFFAB47BC),
      gradientEnd: const Color(0xFF9C27B0),
      progressColor: Colors.purple.shade600,
      snackbarBg: Colors.purple.shade700,
    ),
    ThemeModel(
      name: 'طلایی (لوکس)',
      bgColor: const Color(0xFFFFF8E1),
      cardBg: Colors.white,
      textColor: const Color(0xFF5D4037),
      primary: const Color(0xFFFFC107),
      secondary: const Color(0xFFFFD54F),
      gradientStart: const Color(0xFFFFD54F),
      gradientEnd: const Color(0xFFFFC107),
      progressColor: Colors.amber.shade600,
      snackbarBg: Colors.amber.shade700,
    ),
    ThemeModel(
      name: 'نعناع (تازه)',
      bgColor: const Color(0xFFE0F2F1),
      cardBg: Colors.white,
      textColor: const Color(0xFF004D40),
      primary: const Color(0xFF009688),
      secondary: const Color(0xFF4DB6AC),
      gradientStart: const Color(0xFF26A69A),
      gradientEnd: const Color(0xFF009688),
      progressColor: Colors.teal.shade600,
      snackbarBg: Colors.teal.shade700,
    ),
  ];
  
  // گرفتن گرادینت برای هدر
  LinearGradient get gradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientEnd],
  );
  
  // گرفتن ButtonStyle بر اساس تم
  ButtonStyle get buttonStyle => ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: textColor == const Color(0xFF2B2D42) ? Colors.white : textColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  );
}