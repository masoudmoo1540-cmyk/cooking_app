import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final Color? fallbackColor;
  
  const BackgroundImage({
    super.key,
    required this.child,
    this.fallbackColor,
  });
  
  Future<String?> _getSavedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    final bgPath = prefs.getString('selected_background');
    if (bgPath != null && File(bgPath).existsSync()) {
      return bgPath;
    }
    return null;
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getSavedBackground(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // اگر عکس بک‌گراند وجود داره
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: FileImage(File(snapshot.data!)),
                fit: BoxFit.cover,
              ),
            ),
            child: child,
          );
        } else {
          // حالت پیش‌فرض: فقط رنگ
          return Container(
            color: fallbackColor ?? Colors.white,
            child: child,
          );
        }
      },
    );
  }
}