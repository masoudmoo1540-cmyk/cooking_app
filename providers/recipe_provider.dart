import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/recipe_model.dart';
import '../models/step_model.dart';

class RecipeProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  
  List<Map<String, dynamic>> _recipes = [];
  Map<String, dynamic>? _currentRecipeDetails;
  List<StepModel> _currentSteps = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get recipes => _recipes;
  Map<String, dynamic>? get currentRecipeDetails => _currentRecipeDetails;
  List<StepModel> get currentSteps => _currentSteps;
  bool get isLoading => _isLoading;

  // بارگذاری همه غذاها
  Future<void> loadAllRecipes() async {
    _isLoading = true;
    notifyListeners();
    
    _recipes = await _dbService.getAllRecipes();
    
    _isLoading = false;
    notifyListeners();
  }

  // بارگذاری جزئیات یک غذا
  Future<void> loadRecipeDetails(int recipeId) async {
    _isLoading = true;
    notifyListeners();
    
    final data = await _dbService.getRecipeDetails(recipeId);
    _currentRecipeDetails = data['recipe'];
    _currentSteps = (data['steps'] as List).map((s) => StepModel.fromMap(s)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  // اضافه کردن غذای جدید
  Future<int> addRecipe({
    required String name,
    required String category,
    required String ingredients,
    required List<String> stepsList,
    required List<int> timersList,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    final id = await _dbService.addRecipe(
      name: name,
      category: category,
      ingredients: ingredients,
      stepsList: stepsList,
      timersList: timersList,
    );
    
    await loadAllRecipes();
    
    _isLoading = false;
    notifyListeners();
    
    return id;
  }

  // حذف غذا
  Future<void> deleteRecipe(int recipeId) async {
    _isLoading = true;
    notifyListeners();
    
    await _dbService.deleteRecipe(recipeId);
    await loadAllRecipes();
    
    _isLoading = false;
    notifyListeners();
  }

  // بروزرسانی تاریخ پخت
  Future<void> updateLastCooked(int recipeId) async {
    await _dbService.updateLastCooked(recipeId);
  }

  // پیشنهاد غذا
  Future<Map<String, dynamic>?> suggestUniqueMeal() async {
    return await _dbService.suggestUniqueMeal();
  }

  // بازنشانی تاریخ پخت همه غذاها
  Future<void> resetAllCookedDates() async {
    await _dbService.resetAllCookedDates();
  }

  // بروزرسانی عکس غذا
  Future<void> updateRecipeImage(int recipeId, String? imagePath) async {
    await _dbService.updateRecipeImage(recipeId, imagePath);
    if (_currentRecipeDetails != null && _currentRecipeDetails!['id'] == recipeId) {
      _currentRecipeDetails!['image_path'] = imagePath;
      notifyListeners();
    }
  }

  // گرفتن مسیر عکس
  Future<String?> getRecipeImagePath(int recipeId) async {
    return await _dbService.getRecipeImagePath(recipeId);
  }
}