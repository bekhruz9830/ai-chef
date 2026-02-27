import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:ai_chef/screens/recipe_detail_screen.dart';

class CompletionScreen extends StatefulWidget {
  final Recipe recipe;

  const CompletionScreen({super.key, required this.recipe});

  @override
  State<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends State<CompletionScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _scaleController;
  int _rating = 0;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _saveRecipe() async {
    if (_saved) return;
    await FirebaseService.saveRecipe(widget.recipe.copyWith(isFavorite: true));
    setState(() => _saved = true);
    HapticFeedback.mediumImpact();
    if (mounted) {
      final loc = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❤️ ${loc.t('saved_recipe_toast')}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _cookAgain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recipe: widget.recipe),
      ),
      (route) => false,
    );
  }

  void _goBack() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  static const _confettiEmojis = ['🎉', '✨', '🍽️', '👨‍🍳', '⭐', '🌟', '💫', '🥳'];

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context, listen: true);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35),
                  Color(0xFFFF8C5A),
                  Color(0xFFFFB74D),
                  Color(0xFFFFF176),
                ],
              ),
            ),
          ),
          ...List.generate(24, (i) {
            return AnimatedBuilder(
              animation: _confettiController,
              builder: (context, child) {
                final progress = (_confettiController.value + i / 24) % 1.0;
                final left = (i * 17) % MediaQuery.of(context).size.width;
                final top = (progress * (MediaQuery.of(context).size.height + 80)) - 40;
                final emoji = _confettiEmojis[i % _confettiEmojis.length];
                final scale = 0.6 + (i % 3) * 0.2;
                return Positioned(
                  left: left.toDouble(),
                  top: top,
                  child: Transform.scale(
                    scale: scale,
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              },
            );
          }),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _scaleController,
                      curve: Curves.elasticOut,
                    ),
                    child: const Text(
                      '👨‍🍳',
                      style: TextStyle(fontSize: 100),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '${loc.t('bon_appetit')} 🎉',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Your meal is ready! Enjoy your delicious ${widget.recipe.title}!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.95),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).dividerColor,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          loc.t('rate_recipe'),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ?? AppTextStyles.subtitle.copyWith(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (i) {
                            final filled = i < _rating;
                            return Flexible(
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _rating = i + 1);
                                  HapticFeedback.selectionClick();
                                },
                                icon: Icon(
                                  filled ? Icons.star : Icons.star_border,
                                  size: 36,
                                  color: filled
                                      ? const Color(0xFFFFB74D)
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saved ? null : _saveRecipe,
                            icon: Icon(_saved ? Icons.check : Icons.favorite_outline),
                            label: Text(_saved ? loc.t('saved_exclamation') : loc.t('save_recipe')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _cookAgain,
                            icon: const Icon(Icons.restart_alt),
                            label: Text(loc.t('cook_again')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _goBack,
                          child: Text(
                            loc.t('back_home'),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
