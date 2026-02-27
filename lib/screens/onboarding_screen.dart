import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_chef/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  int _page = 0;
  final PageController _ctrl = PageController();
  late AnimationController _floatCtrl;
  late AnimationController _entryCtrl;
  late Animation<double> _float;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  final _pages = const [
    _OBData(
      colors: [Color(0xFFFF6B35), Color(0xFFE8431A)],
      mainEmoji: '📸',
      bg: ['🥦', '🥕', '🧅', '🍅', '🫑', '🥑'],
      title: 'Scan Your\nIngredients',
      body: 'Point your camera at any food or fridge.\nAI instantly identifies every ingredient\nand creates dishes just for you.',
      tag: 'SMART SCANNER',
    ),
    _OBData(
      colors: [Color(0xFF6C3483), Color(0xFF4A235A)],
      mainEmoji: '🌍',
      bg: ['🇮🇹', '🇯🇵', '🇺🇿', '🇫🇷', '🇮🇳', '🇲🇽'],
      title: '20+ World\nCuisines',
      body: 'From Italian Carbonara to Uzbek Plov.\nDiscover authentic recipes from every\ncorner of the world.',
      tag: 'GLOBAL RECIPES',
    ),
    _OBData(
      colors: [Color(0xFF1A6B3A), Color(0xFF0D4A27)],
      mainEmoji: '👨‍🍳',
      bg: ['⏱️', '🔥', '✅', '🍽️', '⭐', '🎯'],
      title: 'Cook Like\na Pro Chef',
      body: 'Step-by-step guidance with smart timers.\nExact amounts, temperatures and\ntechniques for perfect results.',
      tag: 'PRO COOKING',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _float = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _entryFade = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeIn);
    _entrySlide = Tween<Offset>(begin: const Offset(0.15, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _entryCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _next() async {
    if (_page < 2) {
      _entryCtrl.reset();
      _ctrl.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _pages[_page];
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient animated
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: d.colors,
              ),
            ),
          ),
          // Floating background emojis + content
          PageView(
            controller: _ctrl,
            onPageChanged: (i) {
              setState(() => _page = i);
              _entryCtrl.reset();
              _entryCtrl.forward();
            },
            children: _pages.map((data) => _buildPageContent(data)).toList(),
          ),
          // Bottom bar always on top
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottom(d),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(_OBData data) {
    final size = MediaQuery.of(context).size;
    final positions = [
      [0.08, 0.05], [0.75, 0.08], [0.02, 0.35],
      [0.82, 0.30], [0.45, 0.03], [0.6, 0.18],
    ];
    return Stack(
      children: [
        // Floating emojis
        ...List.generate(data.bg.length, (i) {
          return AnimatedBuilder(
            animation: _float,
            builder: (_, __) {
              final dy = (i % 2 == 0 ? 1 : -1) * 14.0 * _float.value;
              return Positioned(
                left: size.width * positions[i][0],
                top: size.height * positions[i][1] + dy,
                child: Opacity(
                  opacity: 0.25,
                  child: Text(data.bg[i], style: const TextStyle(fontSize: 42)),
                ),
              );
            },
          );
        }),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                // Tag
                FadeTransition(
                  opacity: _entryFade,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(data.tag,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 40),
                // Big emoji with glow
                SlideTransition(
                  position: _entrySlide,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
                          ],
                        ),
                        child: Center(
                          child: Text(data.mainEmoji, style: const TextStyle(fontSize: 80)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 44),
                // Title
                SlideTransition(
                  position: _entrySlide,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Text(data.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Body
                SlideTransition(
                  position: _entrySlide,
                  child: FadeTransition(
                    opacity: _entryFade,
                    child: Text(data.body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottom(_OBData d) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 50),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [d.colors.last.withOpacity(0), d.colors.last.withOpacity(0.95)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Dots
          Row(
            children: List.generate(3, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.only(right: 8),
              width: _page == i ? 32 : 10,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: _page == i ? Colors.white : Colors.white.withOpacity(0.35),
              ),
            )),
          ),
          // Next button
          GestureDetector(
            onTap: _next,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _page == 2 ? 'Get Started 🚀' : 'Next',
                    style: TextStyle(
                      color: d.colors.first,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (_page < 2) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, color: d.colors.first, size: 18),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OBData {
  final List<Color> colors;
  final String mainEmoji;
  final List<String> bg;
  final String title;
  final String body;
  final String tag;
  const _OBData({required this.colors, required this.mainEmoji, required this.bg, required this.title, required this.body, required this.tag});
}
