import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/screens/splash_screen.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:ai_chef/services/theme_service.dart';
import 'package:ai_chef/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  runApp(const AiChefApp());
}

class AiChefApp extends StatefulWidget {
  const AiChefApp({super.key});

  @override
  State<AiChefApp> createState() => _AiChefAppState();
}

class _AiChefAppState extends State<AiChefApp> {
  @override
  void initState() {
    super.initState();
    LocalizationService().load();
    ThemeService().load();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: LocalizationService()),
        ChangeNotifierProvider.value(value: ThemeService()),
        ChangeNotifierProvider.value(value: NotificationService()),
      ],
      child: Consumer2<ThemeService, LocalizationService>(
        builder: (context, themeService, loc, _) => MaterialApp(
          title: 'AI Chef',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFFFF6B35),
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFFF6B35),
              secondary: const Color(0xFFFF8C42),
              surface: AppColors.surface,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8F8F8),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.surface,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              iconTheme: IconThemeData(color: AppColors.textPrimary),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            cardTheme: CardThemeData(
              color: AppColors.card,
              elevation: 4,
              shadowColor: const Color.fromRGBO(0, 0, 0, 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFFFF6B35),
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFFFF6B35),
              secondary: const Color(0xFFFF8C42),
              surface: const Color(0xFF1E1E2E),
              background: const Color(0xFF0D0D1A),
              onBackground: Colors.white,
              onSurface: Colors.white,
              onPrimary: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFF0D0D1A),
            cardColor: const Color(0xFF1E1E2E),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E1E2E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E2E),
              foregroundColor: Colors.white,
              elevation: 0,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E2E),
              selectedItemColor: Color(0xFFFF6B35),
              unselectedItemColor: Colors.grey,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              fillColor: const Color(0xFF2A2A3E),
              filled: true,
              hintStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            chipTheme: ChipThemeData(
              backgroundColor: const Color(0xFF2A2A3E),
              labelStyle: const TextStyle(color: Colors.white70),
              side: BorderSide.none,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
              bodySmall: TextStyle(color: Colors.white60),
              titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              titleSmall: TextStyle(color: Colors.white70),
              headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            dividerColor: Colors.white12,
            iconTheme: const IconThemeData(color: Colors.white),
            listTileTheme: const ListTileThemeData(
              textColor: Colors.white,
              iconColor: Colors.white70,
            ),
          ),
          home: const SplashScreen(),
        ),
      ),
    );
  }
}
