import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../widgets/background_image.dart';

class HelpView extends StatefulWidget {
  const HelpView({super.key});

  @override
  State<HelpView> createState() => _HelpViewState();
}

class _HelpViewState extends State<HelpView> {
  Map<String, dynamic> _helpData = {'sections': []};
  
  @override
  void initState() {
    super.initState();
    _loadHelpData();
  }
  
  Future<void> _loadHelpData() async {
    // در نسخه واقعی از assets/json/help_content.json بخون
    // اینجا یک دیتای نمونه میذاریم
    
    final sampleData = {
      'sections': [
        {
          'title': 'شروع سریع',
          'icon': 'rocket',
          'items': [
            {
              'title': 'چطور از برنامه استفاده کنم؟',
              'description': 'در صفحه اصلی روی کارت "پیشنهاد لحظه‌ای" کلیک کن تا یک غذای جدید بهت پیشنهاد بشه. میتونی از لیست غذاها هم غذای مورد علاقه‌ات رو انتخاب کنی.',
            },
            {
              'title': 'اضافه کردن غذای جدید',
              'description': 'به صفحه لیست غذاها برو و روی دکمه سبز رنگ پایین سمت راست کلیک کن. اسم غذا، دسته‌بندی، مواد اولیه و مراحل پخت رو وارد کن.',
            },
          ],
        },
        {
          'title': 'تنظیمات',
          'icon': 'settings',
          'items': [
            {
              'title': 'تغییر تم برنامه',
              'description': 'از صفحه اصلی روی آیکون پالت (🎨) کلیک کن و تم مورد علاقه‌ات رو انتخاب کن.',
            },
            {
              'title': 'تنظیم صدای آلارم',
              'description': 'از صفحه اصلی روی آیکون نت (🎵) کلیک کن. میتونی صدا رو خاموش یا روشن کنی و آهنگ آلارم رو تغییر بدی.',
            },
            {
              'title': 'تغییر عکس بک‌گراند',
              'description': 'به تنظیمات تم برو و روی دکمه "تنظیمات بک‌گراند عکس" کلیک کن. میتونی از گالری عکس انتخاب کنی.',
            },
          ],
        },
        {
          'title': 'صفحه پخت',
          'icon': 'kitchen',
          'items': [
            {
              'title': 'تایمر پس‌زمینه',
              'description': 'وقتی در صفحه پخت هستی، تایمرها حتی اگر برنامه رو ببندی هم کار میکنند و موقع تموم شدن زنگ میزنن.',
            },
            {
              'title': 'توقف زودتر تایمر',
              'description': 'اگه زودتر از موعد یه مرحله رو تموم کردی، میتونی دکمه "تموم شد (زودتر)" رو بزنی و بری مرحله بعد.',
            },
          ],
        },
      ],
    };
    
    setState(() {
      _helpData = sampleData;
    });
  }
  
  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'rocket':
        return Icons.rocket;
      case 'settings':
        return Icons.settings;
      case 'kitchen':
        return Icons.kitchen;
      default:
        return Icons.help_outline;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    
    final sections = _helpData['sections'] as List;
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('راهنمای برنامه'),
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
              ...sections.map((section) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(_getIcon(section['icon']), size: 28, color: primaryColor),
                          const SizedBox(width: 10),
                          Text(section['title'],
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 15),
                      ...(section['items'] as List).map((item) => Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['title'],
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                                  const SizedBox(height: 8),
                                  Text(item['description'],
                                      style: TextStyle(fontSize: 14, color: textColor)),
                                ],
                              ),
                            ),
                          )),
                      const SizedBox(height: 20),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}