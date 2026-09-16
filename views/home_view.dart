import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/recipe_provider.dart';
import '../providers/sound_provider.dart';
import '../services/database_service.dart';
import '../widgets/background_image.dart';
import '../utils/constants.dart';
import 'recipes_view.dart';
import 'detail_view.dart';
import 'settings/sound_settings_view.dart';
import 'settings/theme_settings_view.dart';
import 'help_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  Map<String, dynamic>? _suggestedMeal;
  int? _lastRecipeId;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadSuggestedMeal();
  }

  Future<void> _loadSuggestedMeal() async {
    final meal = await _dbService.suggestUniqueMeal();
    setState(() {
      _suggestedMeal = meal;
      _lastRecipeId = meal?['id'] as int?;
    });
  }

  Future<void> _resetAllCookedDates() async {
    await _dbService.resetAllCookedDates();
    await _loadSuggestedMeal();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ همه غذاها دوباره قابل پیشنهاد شدن!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _suggestedMeal = null;
        _lastRecipeId = null;
      });
    }
  }

  void _goToRecipes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<RecipeProvider>(context, listen: false),
          child: RecipesView(
            onRecipeClick: (id) => _goToDetail(id),
          ),
        ),
      ),
    ).then((_) => _loadSuggestedMeal());
  }

  void _goToDetail(int recipeId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<RecipeProvider>(context, listen: false),
          child: DetailView(
            recipeId: recipeId,
            onBack: () {},
          ),
        ),
      ),
    );
  }

  void _goToSoundSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<SoundProvider>(context, listen: false),
          child: const SoundSettingsView(),
        ),
      ),
    );
  }

  void _goToThemeSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<ThemeProvider>(context, listen: false),
          child: const ThemeSettingsView(),
        ),
      ),
    );
  }

  void _goToHelp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: Provider.of<ThemeProvider>(context, listen: false),
          child: const HelpView(),
        ),
      ),
    );
  }

  void _goToCookingFromSuggestion() {
    if (_lastRecipeId != null) {
      _goToDetail(_lastRecipeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;

    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // هدر گرادینت (مثل header در home_view.py)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: themeProvider.getGradient(),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(top: 50, bottom: 40, left: 20, right: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.restaurant, size: 50, color: Colors.white),
                      Expanded(
                        child: Text(
                          'آشپزخانه من',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.palette, color: Colors.white),
                            onPressed: _goToThemeSettings,
                            tooltip: 'تنظیمات تم',
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _resetAllCookedDates,
                            tooltip: 'بازنشانی همه غذاها',
                          ),
                          IconButton(
                            icon: const Icon(Icons.music_note, color: Colors.white),
                            onPressed: _goToSoundSettings,
                            tooltip: 'تنظیمات صدا',
                          ),
                          IconButton(
                            icon: const Icon(Icons.help_outline, color: Colors.white),
                            onPressed: _goToHelp,
                            tooltip: 'راهنما',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'هر روز یه پیشنهاد خوشمزه',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // کارت پیشنهاد لحظه‌ای
            GestureDetector(
              onTap: _loadSuggestedMeal,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 10,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(Icons.bolt, size: 42, color: primaryColor),
                    const SizedBox(height: 10),
                    Text(
                      'پیشنهاد لحظه‌ای',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'با یک کلیک، سورپرایز شو!',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // نتیجه پیشنهاد
            if (_suggestedMeal != null)
              GestureDetector(
                onTap: _goToCookingFromSuggestion,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    '🍽️ ${_suggestedMeal!['name']}\n\nآماده‌ای بپزی؟ (کلیک کن)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            if (_suggestedMeal == null && _lastRecipeId != null)
              GestureDetector(
                onTap: _goToCookingFromSuggestion,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Text(
                    'همه غذاها تکراری شدن!\nروی دکمه 🔄 بالا صفحه بزن تا ریست بشه',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 30),
            // دکمه لیست همه غذاها
            GestureDetector(
              onTap: _goToRecipes,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      'لیست همه غذاها',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}