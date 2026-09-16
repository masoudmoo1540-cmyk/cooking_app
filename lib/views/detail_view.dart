import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/theme_provider.dart';
import '../providers/recipe_provider.dart';
import '../services/database_service.dart';
import '../widgets/background_image.dart';
import 'cooking_view.dart';
import '../utils/constants.dart';

class DetailView extends StatefulWidget {
  final int recipeId;
  final VoidCallback onBack;
  
  const DetailView({
    super.key,
    required this.recipeId,
    required this.onBack,
  });

  @override
  State<DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends State<DetailView> {
  final DatabaseService _dbService = DatabaseService();
  final ImagePicker _imagePicker = ImagePicker();
  
  Map<String, dynamic>? _recipe;
  List<Map<String, dynamic>> _steps = [];
  String? _imagePath;
  
  @override
  void initState() {
    super.initState();
    _loadDetails();
  }
  
  Future<void> _loadDetails() async {
    final data = await _dbService.getRecipeDetails(widget.recipeId);
    setState(() {
      _recipe = data['recipe'];
      _steps = List<Map<String, dynamic>>.from(data['steps']);
      _imagePath = _recipe?['image_path'] as String?;
    });
  }
  
  Future<void> _pickImage() async {
    final result = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (result != null) {
      // کپی عکس به پوشه assets/images
      // (در نسخه واقعی باید از path_provider استفاده کنی)
      setState(() {
        _imagePath = result.path;
      });
      await _dbService.updateRecipeImage(widget.recipeId, result.path);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ عکس غذا اضافه شد'), backgroundColor: Colors.green),
        );
      }
    }
  }
  
  Future<void> _deleteRecipe() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف غذا'),
        content: Text('آیا از حذف "${_recipe?['name']}" مطمئنی؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('خیر')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('بله', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _dbService.deleteRecipe(widget.recipeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ ${_recipe?['name']} حذف شد'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }
  
  void _goToCooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookingView(recipeId: widget.recipeId),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;
    
    if (_recipe == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final name = _recipe!['name'] as String;
    final category = _recipe!['category'] as String;
    final ingredients = (_recipe!['ingredients'] as String).split(',');
    
    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(name),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _deleteRecipe,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // عکس غذا
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(blurRadius: 10, color: Colors.grey.withOpacity(0.3))],
                  ),
                  child: _imagePath != null && File(_imagePath!).existsSync()
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                        )
                      : Icon(Icons.image_outlined, size: 60, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(height: 10),
              // دسته‌بندی
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: primaryColor),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(category, style: TextStyle(fontSize: 12, color: primaryColor)),
              ),
              const SizedBox(height: 20),
              // مواد اولیه
              Align(
                alignment: Alignment.centerRight,
                child: Text('🥕 مواد اولیه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: ingredients.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.circle, size: 8, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(item.trim(), style: TextStyle(fontSize: 15, color: textColor)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // طرز تهیه
              Align(
                alignment: Alignment.centerRight,
                child: Text('👩‍🍳 طرز تهیه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                child: Container(
                  padding: const EdgeInsets.all(15),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _steps.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final step = entry.value;
                      final description = step['description'] as String;
                      final timer = step['timer_minutes'] as int;
                      final timerText = timer > 0 ? ' ⏱️ ${formatTime(timer)}' : '';
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$index',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '$description$timerText',
                                style: TextStyle(fontSize: 15, color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // دکمه شروع پخت
              ElevatedButton.icon(
                onPressed: _goToCooking,
                icon: const Icon(Icons.kitchen, color: Colors.white),
                label: const Text('شروع پخت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 45),
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