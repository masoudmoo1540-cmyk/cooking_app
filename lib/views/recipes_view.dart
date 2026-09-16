import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/background_image.dart';
import 'add_recipe_view.dart';

class RecipesView extends StatefulWidget {
  final Function(int) onRecipeClick;
  
  const RecipesView({
    super.key,
    required this.onRecipeClick,
  });

  @override
  State<RecipesView> createState() => _RecipesViewState();
}

class _RecipesViewState extends State<RecipesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RecipeProvider>(context, listen: false).loadAllRecipes();
    });
  }

  void _goToAddRecipe() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRecipeView(),
      ),
    ).then((_) {
      Provider.of<RecipeProvider>(context, listen: false).loadAllRecipes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final recipeProvider = Provider.of<RecipeProvider>(context);
    final colors = themeProvider.getColors();
    final primaryColor = colors['primary'] as Color;
    final textColor = colors['text_color'] as Color;
    final cardBg = colors['card_bg'] as Color;

    return BackgroundImage(
      fallbackColor: colors['bgcolor'] as Color,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('لیست غذاها'),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: _goToAddRecipe,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        body: recipeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : recipeProvider.recipes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.restaurant_menu, size: 60, color: Colors.grey),
                        const SizedBox(height: 15),
                        Text(
                          'هیچ غذایی یافت نشد!',
                          style: TextStyle(fontSize: 18, color: Colors.grey[500]),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'از دکمه سبز رنگ بالا برای افزودن غذای جدید استفاده کن',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recipeProvider.recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipeProvider.recipes[index];
                      final recipeId = recipe['id'] as int;
                      final name = recipe['name'] as String;
                      final firstChar = name.isNotEmpty ? name[0] : '?';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                firstChar,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            'برای مشاهده جزئیات کلیک کن',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => widget.onRecipeClick(recipeId),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}