import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AiChefApp());
}

class AiChefApp extends StatelessWidget {
  const AiChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chef',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
