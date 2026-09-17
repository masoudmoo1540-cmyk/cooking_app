import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/theme_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/sound_provider.dart';
import 'services/database_service.dart';
import 'services/sound_service.dart';
import 'services/timer_service.dart';
import 'services/meal_suggestion_service.dart';
import 'services/permission_service.dart';
import 'views/home_view.dart';
import 'views/permission_setup_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await SoundService.init();
  await TimerService.init();
  await MealSuggestionService.init();
  
  final dbService = DatabaseService();
  await dbService.getAllRecipes();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => SoundProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final colors = themeProvider.getColors();
          final primaryColor = colors['primary'] as Color;
          final bgColor = colors['bgcolor'] as Color;
          final textColor = colors['text_color'] as Color;
          
          return MaterialApp(
            title: 'آشپزخانه من',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              fontFamily: 'Vazirmatn',
              useMaterial3: true,
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                secondary: colors['secondary'] as Color,
                surface: colors['card_bg'] as Color,
                background: bgColor,
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onSurface: textColor,
                onBackground: textColor,
              ),
              scaffoldBackgroundColor: bgColor,
              appBarTheme: AppBarTheme(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                centerTitle: true,
                elevation: 0,
                titleTextStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              cardTheme: CardThemeData(
                color: colors['card_bg'] as Color,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                labelStyle: TextStyle(color: textColor),
                hintStyle: TextStyle(color: Colors.grey[400]),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              textTheme: TextTheme(
                bodyLarge: TextStyle(color: textColor, fontSize: 16),
                bodyMedium: TextStyle(color: textColor, fontSize: 14),
                titleLarge: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                titleMedium: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child ?? Container(),
              );
            },
            home: const _AppEntryPoint(),
          );
        },
      ),
    );
  }
}

class _AppEntryPoint extends StatefulWidget {
  const _AppEntryPoint();

  @override
  State<_AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<_AppEntryPoint> {
  bool _loading = true;
  bool _setupDone = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final done = await PermissionService.isSetupDone();
    if (!mounted) return;
    setState(() {
      _setupDone = done;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!_setupDone) {
      return PermissionSetupView(
        onFinished: () {
          setState(() {
            _setupDone = true;
          });
        },
      );
    }
    
    return const HomeView();
  }
}