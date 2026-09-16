import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/background_image.dart';
import '../widgets/timer_picker.dart';

class AddRecipeView extends StatefulWidget {
  const AddRecipeView({super.key});

  @override
  State<AddRecipeView> createState() => _AddRecipeViewState();
}

class _AddRecipeViewState extends State<AddRecipeView> {
  final _formKey = GlobalKey<FormState>();
  
  // فیلدهای اصلی
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  
  // مواد اولیه (داینامیک)
  List<TextEditingController> _ingredientControllers = [];
  List<Widget> _ingredientRows = [];
  
  // مراحل پخت (داینامیک)
  List<TextEditingController> _stepControllers = [];
  List<bool> _noTimerFlags = [];
  List<TimerPickerController> _timerControllers = [];
  List<Widget> _stepRows = [];
  
  @override
  void initState() {
    super.initState();
    _addIngredientRow();
    _addStepRow();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    for (var c in _ingredientControllers) c.dispose();
    for (var c in _stepControllers) c.dispose();
    super.dispose();
  }
  
  void _addIngredientRow() {
    final controller = TextEditingController();
    _ingredientControllers.add(controller);
    
    final index = _ingredientControllers.length - 1;
    
    _ingredientRows.add(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'مثال: برنج',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                textAlign: TextAlign.right,
                validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً ماده اولیه را وارد کنید' : null,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeIngredientRow(index),
              tooltip: 'حذف',
            ),
          ],
        ),
      ),
    );
    
    setState(() {});
  }
  
  void _removeIngredientRow(int index) {
    if (index < _ingredientControllers.length) {
      _ingredientControllers[index].dispose();
      _ingredientControllers.removeAt(index);
      _ingredientRows.removeAt(index);
      setState(() {});
    }
  }
  
  void _addStepRow() {
    final stepController = TextEditingController();
    final timerController = TimerPickerController();
    _stepControllers.add(stepController);
    _timerControllers.add(timerController);
    _noTimerFlags.add(false);
    
    final index = _stepControllers.length - 1;
    
    _stepRows.add(
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: stepController,
                      decoration: InputDecoration(
                        hintText: 'مثال: برنج را خیس کن',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً توضیحات مرحله را وارد کنید' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeStepRow(index),
                    tooltip: 'حذف این مرحله',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _noTimerFlags[index],
                    onChanged: (value) {
                      setState(() {
                        _noTimerFlags[index] = value ?? false;
                        if (_noTimerFlags[index]) {
                          _timerControllers[index].reset();
                        }
                      });
                    },
                  ),
                  const Text('بدون تایمر', style: TextStyle(fontSize: 14)),
                ],
              ),
              if (!_noTimerFlags[index])
                TimerPicker(controller: _timerControllers[index]),
            ],
          ),
        ),
      ),
    );
    
    setState(() {});
  }
  
  void _removeStepRow(int index) {
    if (index < _stepControllers.length) {
      _stepControllers[index].dispose();
      _stepControllers.removeAt(index);
      _timerControllers.removeAt(index);
      _noTimerFlags.removeAt(index);
      _stepRows.removeAt(index);
      setState(() {});
    }
  }
  
  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    
    if (name.isEmpty || category.isEmpty) {
      _showSnackbar('لطفاً نام و دسته غذا را وارد کن');
      return;
    }
    
    final ingredientsList = _ingredientControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    
    if (ingredientsList.isEmpty) {
      _showSnackbar('حداقل یک ماده اولیه اضافه کن');
      return;
    }
    final ingredientsText = ingredientsList.join(', ');
    
    final steps = <String>[];
    final timers = <int>[];
    
    for (int i = 0; i < _stepControllers.length; i++) {
      final stepText = _stepControllers[i].text.trim();
      if (stepText.isEmpty) {
        _showSnackbar('لطفاً توضیحات مرحله ${i + 1} را وارد کن');
        return;
      }
      steps.add(stepText);
      
      if (_noTimerFlags[i]) {
        timers.add(0);
      } else {
        timers.add(_timerControllers[i].getTotalSeconds());
      }
    }
    
    if (steps.isEmpty) {
      _showSnackbar('حداقل یک مرحله پخت اضافه کن');
      return;
    }
    
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    await recipeProvider.addRecipe(
      name: name,
      category: category,
      ingredients: ingredientsText,
      stepsList: steps,
      timersList: timers,
    );
    
    _showSnackbar('غذا "$name" با موفقیت اضافه شد');
    
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pop(context);
    });
  }
  
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green[700]),
    );
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
        appBar: AppBar(
          title: const Text('افزودن غذای جدید'),
          centerTitle: true,
          backgroundColor: primaryColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // اطلاعات پایه
                Card(
                  elevation: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'اسم غذا',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً اسم غذا را وارد کنید' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _categoryController,
                          decoration: InputDecoration(
                            labelText: 'دسته‌بندی (ناهار، شام، ...)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          textAlign: TextAlign.right,
                          validator: (value) => value == null || value.trim().isEmpty ? 'لطفاً دسته‌بندی را وارد کنید' : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // مواد اولیه
                Row(
                  children: [
                    const Text('🥕 مواد اولیه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addIngredientRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('افزودن ماده اولیه'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: _ingredientRows),
                  ),
                ),
                const SizedBox(height: 16),
                
                // مراحل پخت
                Row(
                  children: [
                    const Text('👩‍🍳 مراحل پخت', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _addStepRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('افزودن مرحله جدید'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'برای هر مرحله می‌توانی زمان تعیین کنی یا گزینه «بدون تایمر» را بزنی',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Column(children: _stepRows),
                const SizedBox(height: 20),
                
                // دکمه ذخیره
                ElevatedButton(
                  onPressed: _saveRecipe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: const Text('💾 ذخیره غذا', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}