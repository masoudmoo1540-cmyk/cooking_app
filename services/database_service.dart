import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  
  DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  // این فقط برای سازگاری با کدهای قبلی
  Future get database async => null;

  Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  Future<void> _saveRecipes(List<Map<String, dynamic>> recipes) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(recipes);
    await prefs.setString('recipes', jsonString);
  }

  Future<List<Map<String, dynamic>>> _getRecipes() async {
    final prefs = await _getPrefs();
    final jsonString = prefs.getString('recipes');
    if (jsonString == null) {
      // دیتای نمونه (sample data)
      final sampleRecipes = [
        {
          'id': 1,
          'name': 'چلو مرغ',
          'category': 'ناهار',
          'ingredients': 'مرغ, برنج, زعفرون, پیاز, روغن',
          'last_cooked': null,
          'cook_count': 0,
          'image_path': null,
          'steps': {
            '0': {'step_number': 1, 'description': 'برنج رو خیس کن', 'timer_minutes': 900},
            '1': {'step_number': 2, 'description': 'مرغ رو با پیاز تفت بده', 'timer_minutes': 600},
            '2': {'step_number': 3, 'description': 'زعفرون رو آب کن اضافه کن', 'timer_minutes': 0},
            '3': {'step_number': 4, 'description': 'دم کن', 'timer_minutes': 2400},
          }
        },
        {
          'id': 2,
          'name': 'ماکارونی',
          'category': 'شام',
          'ingredients': 'ماکارونی, گوشت چرخ کرده, گوجه, پیاز, روغن',
          'last_cooked': null,
          'cook_count': 0,
          'image_path': null,
          'steps': {
            '0': {'step_number': 1, 'description': 'ماکارونی رو بذار بپزه', 'timer_minutes': 720},
            '1': {'step_number': 2, 'description': 'سس گوشت و گوجه آماده کن', 'timer_minutes': 1200},
            '2': {'step_number': 3, 'description': 'روی هم بریز و سرو کن', 'timer_minutes': 0},
          }
        },
        {
          'id': 3,
          'name': 'قرمه سبزی',
          'category': 'ناهار',
          'ingredients': 'سبزی, گوشت, لوبیا قرمز, پیاز, روغن',
          'last_cooked': null,
          'cook_count': 0,
          'image_path': null,
          'steps': {
            '0': {'step_number': 1, 'description': 'سبزی رو تفت بده', 'timer_minutes': 300},
            '1': {'step_number': 2, 'description': 'گوشت رو بپز', 'timer_minutes': 2700},
            '2': {'step_number': 3, 'description': 'با لوبیا قرمز بپز', 'timer_minutes': 1800},
          }
        },
      ];
      await _saveRecipes(sampleRecipes);
      return sampleRecipes;
    }
    return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
  }

  // ========== متدهای اصلی ==========

  Future<int> addRecipe({
    required String name,
    required String category,
    required String ingredients,
    required List<String> stepsList,
    required List<int> timersList,
  }) async {
    final recipes = await _getRecipes();
    final newId = recipes.isEmpty ? 1 : (recipes.last['id'] as int) + 1;
    
    final newRecipe = {
      'id': newId,
      'name': name,
      'category': category,
      'ingredients': ingredients,
      'last_cooked': null,
      'cook_count': 0,
      'image_path': null,
      'steps': stepsList.asMap().map((i, step) => MapEntry(i.toString(), {
        'step_number': i + 1,
        'description': step,
        'timer_minutes': timersList[i] ?? 0,
      })),
    };
    
    recipes.add(newRecipe);
    await _saveRecipes(recipes);
    return newId;
  }

  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    final recipes = await _getRecipes();
    return recipes.map((r) => {
      'id': r['id'],
      'name': r['name'],
    }).toList();
  }

  Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    final recipes = await _getRecipes();
    
    // ✅ اصلاح شده: استفاده از loop به جای firstWhere
    Map<String, dynamic>? recipe;
    for (var r in recipes) {
      if (r['id'] == recipeId) {
        recipe = r;
        break;
      }
    }
    
    if (recipe == null) {
      return {'recipe': null, 'steps': []};
    }
    
    final steps = recipe['steps'] != null 
        ? List<Map<String, dynamic>>.from((recipe['steps'] as Map).values)
        : [];
    
    return {
      'recipe': recipe,
      'steps': steps,
    };
  }

  Future<void> updateLastCooked(int recipeId) async {
    final recipes = await _getRecipes();
    final index = recipes.indexWhere((r) => r['id'] == recipeId);
    if (index != -1) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      recipes[index]['last_cooked'] = today;
      recipes[index]['cook_count'] = (recipes[index]['cook_count'] ?? 0) + 1;
      await _saveRecipes(recipes);
    }
  }

  Future<Map<String, dynamic>?> suggestUniqueMeal() async {
    final recipes = await _getRecipes();
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3)).toIso8601String().split('T')[0];
    
    final available = recipes.where((r) {
      final lastCooked = r['last_cooked'] as String?;
      return lastCooked == null || lastCooked.compareTo(threeDaysAgo) < 0;
    }).toList();
    
    if (available.isEmpty) return null;
    final random = available[DateTime.now().millisecondsSinceEpoch % available.length];
    return {'id': random['id'], 'name': random['name']};
  }

  Future<void> resetAllCookedDates() async {
    final recipes = await _getRecipes();
    for (var recipe in recipes) {
      recipe['last_cooked'] = null;
    }
    await _saveRecipes(recipes);
  }

  Future<void> deleteRecipe(int recipeId) async {
    final recipes = await _getRecipes();
    final filtered = recipes.where((r) => r['id'] != recipeId).toList();
    await _saveRecipes(filtered);
  }

  Future<void> updateRecipeImage(int recipeId, String? imagePath) async {
    final recipes = await _getRecipes();
    final index = recipes.indexWhere((r) => r['id'] == recipeId);
    if (index != -1) {
      recipes[index]['image_path'] = imagePath;
      await _saveRecipes(recipes);
    }
  }

  Future<String?> getRecipeImagePath(int recipeId) async {
    final recipes = await _getRecipes();
    
    // ✅ اصلاح شده: استفاده از loop به جای firstWhere
    for (var recipe in recipes) {
      if (recipe['id'] == recipeId) {
        return recipe['image_path'] as String?;
      }
    }
    return null;
  }
}