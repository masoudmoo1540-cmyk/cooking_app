import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/background_image.dart';

class BackgroundSettingsView extends StatefulWidget {
  const BackgroundSettingsView({super.key});

  @override
  State<BackgroundSettingsView> createState() => _BackgroundSettingsViewState();
}

class _BackgroundSettingsViewState extends State<BackgroundSettingsView> {
  String? _selectedBackground;
  final ImagePicker _imagePicker = ImagePicker();
  
  // لیست عکس‌ها (ذخیره در SharedPreferences)
  List<Map<String, dynamic>> _images = [];
  
  // عکس‌های پیش‌فرض (به صورت硬کد)
  final List<Map<String, dynamic>> _defaultImages = [
    {'name': 'غذا 1', 'path': 'assets/backgrounds/default/food1.jpg', 'isDefault': true},
    {'name': 'غذا 2', 'path': 'assets/backgrounds/default/food2.jpg', 'isDefault': true},
    {'name': 'غذا 3', 'path': 'assets/backgrounds/default/food3.jpg', 'isDefault': true},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadSelectedBackground();
    _loadImages();
  }
  
  Future<void> _loadSelectedBackground() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedBackground = prefs.getString('selected_background');
    });
  }
  
  Future<void> _saveSelectedBackground(String? bgPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (bgPath != null) {
      await prefs.setString('selected_background', bgPath);
    } else {
      await prefs.remove('selected_background');
    }
    setState(() {
      _selectedBackground = bgPath;
    });
  }
  
  Future<void> _loadImages() async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getString('background_images');
    
    List<Map<String, dynamic>> allImages = [];
    
    // اضافه کردن عکس‌های پیش‌فرض
    allImages.addAll(_defaultImages);
    
    // اضافه کردن عکس‌های کاربر
    if (imagesJson != null) {
      try {
        final userImages = List<Map<String, dynamic>>.from(jsonDecode(imagesJson));
        allImages.addAll(userImages);
      } catch (e) {
        print('Error loading images: $e');
      }
    }
    
    setState(() {
      _images = allImages;
    });
  }
  
  Future<void> _saveUserImages(List<Map<String, dynamic>> userImages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_images', jsonEncode(userImages));
  }
  
  Future<void> _pickImage() async {
    final XFile? result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      // برای وب، فقط مسیر رو ذخیره میکنیم
      // برای موبایل، میتونیم فایل رو کپی کنیم
      final newImage = {
        'name': result.name,
        'path': result.path,
        'isDefault': false,
      };
      
      // گرفتن لیست عکس‌های کاربر
      final prefs = await SharedPreferences.getInstance();
      final imagesJson = prefs.getString('background_images');
      List<Map<String, dynamic>> userImages = [];
      if (imagesJson != null) {
        try {
          userImages = List<Map<String, dynamic>>.from(jsonDecode(imagesJson));
        } catch (e) {
          print('Error loading images: $e');
        }
      }
      
      userImages.add(newImage);
      await _saveUserImages(userImages);
      await _loadImages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ عکس ${result.name} اضافه شد'), backgroundColor: Colors.green),
        );
      }
    }
  }
  
  Future<void> _deleteImage(String path, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final imagesJson = prefs.getString('background_images');
    
    if (imagesJson != null) {
      try {
        List<Map<String, dynamic>> userImages = List<Map<String, dynamic>>.from(jsonDecode(imagesJson));
        userImages.removeWhere((img) => img['path'] == path);
        await _saveUserImages(userImages);
        
        if (_selectedBackground == path) {
          await _saveSelectedBackground(null);
        }
        
        await _loadImages();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ عکس $name حذف شد'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }
  
  void _selectBackground(String path) {
    _saveSelectedBackground(path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ بک‌گراند تغییر کرد'), duration: Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }
  
  void _resetBackground() {
    _saveSelectedBackground(null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ بازگشت به بک‌گراند پیش‌فرض (رنگ)'), duration: Duration(seconds: 1)),
    );
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    
    // فیلتر کردن عکس‌ها برای نمایش
    final displayImages = _images;
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('بک‌گراند عکس'),
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
                child: Text('انتخاب عکس بک‌گراند:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 16),
              
              // لیست عکس‌ها
              if (displayImages.isNotEmpty)
                ...displayImages.map((img) => _buildImageItem(
                      img['name']!,
                      img['path']!,
                      img['isDefault'] as bool? ?? false,
                      primaryColor,
                      textColor,
                      cardBg,
                    ))
              else
                Center(
                  child: Text('هیچ عکسی یافت نشد. برای افزودن عکس از دکمه زیر استفاده کن.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                      textAlign: TextAlign.center),
                ),
              
              const SizedBox(height: 20),
              
              // دکمه افزودن عکس
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('➕ افزودن عکس جدید از گالری'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(300, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // دکمه ریست
              ElevatedButton.icon(
                onPressed: _resetBackground,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('♻️ بازگشت به بک‌گراند پیش‌فرض (رنگ)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[400],
                  foregroundColor: textColor,
                  minimumSize: const Size(300, 45),
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
  
  Widget _buildImageItem(String name, String path, bool isDefault, Color primaryColor, Color textColor, Color cardBg) {
    final isSelected = _selectedBackground == path;
    
    return GestureDetector(
      onTap: () => _selectBackground(path),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : cardBg,
          border: Border.all(color: isSelected ? primaryColor : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            // نمایش تصویر
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: path.startsWith('assets/')
                    ? Image.asset(
                        path,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 30, color: Colors.grey[600]);
                        },
                      )
                    : Image.network(
                        path,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.image, size: 30, color: Colors.grey[600]);
                        },
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: TextStyle(fontSize: 14, color: textColor)),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor, size: 20),
            if (!isDefault)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                onPressed: () => _deleteImage(path, name),
                tooltip: 'حذف',
              ),
          ],
        ),
      ),
    );
  }
}