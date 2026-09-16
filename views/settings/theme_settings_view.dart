import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/theme_model.dart';
import '../../widgets/background_image.dart';
import 'background_settings_view.dart';

class ThemeSettingsView extends StatefulWidget {
  const ThemeSettingsView({super.key});

  @override
  State<ThemeSettingsView> createState() => _ThemeSettingsViewState();
}

class _ThemeSettingsViewState extends State<ThemeSettingsView> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    final currentThemeName = themeProvider.currentTheme.name;
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('تنظیمات تم'),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Text('انتخاب تم:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 16),
              
              // لیست تم‌ها
              ...ThemeModel.themes.map((theme) => GestureDetector(
                    onTap: () {
                      themeProvider.changeTheme(theme.name);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('✅ تم ${theme.name} اعمال شد'), duration: const Duration(seconds: 1)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: currentThemeName == theme.name ? theme.primary.withOpacity(0.1) : cardBg,
                        border: Border.all(color: currentThemeName == theme.name ? theme.primary : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: theme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(theme.name,
                                style: TextStyle(fontSize: 16, color: textColor)),
                          ),
                          if (currentThemeName == theme.name)
                            Icon(Icons.check_circle, color: theme.primary, size: 20),
                        ],
                      ),
                    ),
                  )),
              
              const SizedBox(height: 20),
              
              // دکمه تنظیمات بک‌گراند عکس
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackgroundSettingsView()),
                  );
                },
                icon: const Icon(Icons.image, size: 18),
                label: const Text('🖼️ تنظیمات بک‌گراند عکس'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(250, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // نمایش رنگ‌های تم فعلی
              Align(
                alignment: Alignment.centerRight,
                child: Text('🎨 رنگ‌های تم فعلی:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildColorBox(themeProvider.currentTheme.primary, 'رنگ اصلی'),
                  _buildColorBox(themeProvider.currentTheme.secondary, 'رنگ ثانویه'),
                  _buildColorBox(themeProvider.currentTheme.cardBg, 'رنگ کارت',
                      hasBorder: true, borderColor: Colors.grey),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildColorBox(Color color, String tooltip, {bool hasBorder = false, Color? borderColor}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: hasBorder ? Border.all(color: borderColor ?? Colors.grey, width: 1) : null,
          ),
        ),
      ),
    );
  }
}