import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chef/screens/onboarding_screen.dart';
import 'package:ai_chef/screens/home_screen.dart';
import 'package:ai_chef/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _chefController;
  late AnimationController _textController;
  late Animation<double> _chefScale;
  late Animation<double> _textFade;
  late Animation<double> _lineWidth;

  @override
  void initState() {
    super.initState();
    _chefController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _chefScale = CurvedAnimation(parent: _chefController, curve: Curves.elasticOut);
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _lineWidth = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _start();
  }

  Future<void> _start() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _chefController.forward();
    await Future.delayed(const Duration(milliseconds: 600));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    // Если пользователь уже залогинен — сразу на Home (пока не нажал Log out или не удалил приложение)
    if (user != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;
    if (!seen) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  void dispose() {
    _chefController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: Stack(
          children: [
            // Background food emojis
            Positioned(top: 60, left: 30, child: Opacity(opacity: 0.08, child: Text('🍝', style: TextStyle(fontSize: 80)))),
            Positioned(top: 120, right: 20, child: Opacity(opacity: 0.08, child: Text('🍜', style: TextStyle(fontSize: 60)))),
            Positioned(bottom: 140, left: 20, child: Opacity(opacity: 0.08, child: Text('🥘', style: TextStyle(fontSize: 70)))),
            Positioned(bottom: 80, right: 40, child: Opacity(opacity: 0.08, child: Text('🍱', style: TextStyle(fontSize: 65)))),
            Positioned(top: 300, left: 10, child: Opacity(opacity: 0.06, child: Text('🌮', style: TextStyle(fontSize: 55)))),
            Positioned(top: 250, right: 10, child: Opacity(opacity: 0.06, child: Text('🍣', style: TextStyle(fontSize: 55)))),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _chefScale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        ),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: const Center(child: Text('👨‍🍳', style: TextStyle(fontSize: 60))),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _textFade,
                    child: const Text('AI CHEF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedBuilder(
                    animation: _lineWidth,
                    builder: (_, __) => Container(
                      width: 220 * _lineWidth.value,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeTransition(
                    opacity: _textFade,
                    child: const Text('Your Smart Kitchen Assistant',
                      style: TextStyle(color: Color(0xFFFF6B35), fontSize: 14, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 70),
                  FadeTransition(
                    opacity: _textFade,
                    child: const SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B35)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
