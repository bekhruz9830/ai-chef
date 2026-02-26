import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/gemini_service.dart';
import 'package:ai_chef/screens/cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Recipe _recipe;
  int _servings = 2;
  int _activeStep = -1;
  Timer? _timer;
  int _timerSeconds = 0;
  bool _timerRunning = false;
  final _gemini = GeminiService();
  String? _aiTips;
  bool _loadingTips = false;
  bool _loadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _servings = _recipe.servings;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final newValue = !_recipe.isFavorite;
    await FirebaseService.saveRecipe(_recipe.copyWith(isFavorite: newValue));
    setState(() => _recipe = _recipe.copyWith(isFavorite: newValue));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue
              ? '❤️ Saved to favorites!'
              : 'Removed from favorites'),
          backgroundColor:
              newValue ? AppColors.success : AppColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _timerSeconds = seconds;
      _timerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds <= 0) {
        timer.cancel();
        setState(() => _timerRunning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('⏰ Timer done!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        setState(() => _timerSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildInfo(),
                _buildNutrition(),
                _buildTabBar(),
                _buildTabContent(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _toggleFavorite,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _recipe.isFavorite ? Icons.favorite : Icons.favorite_outline,
              color: _recipe.isFavorite ? Colors.red : AppColors.textPrimary,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Image.network(
          Recipe.getImageUrl(_recipe.title),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.orange.shade100,
            child: Center(
              child: Text(
                Recipe.getCuisineEmoji(_recipe.cuisine),
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfo() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(_recipe.title, style: AppTextStyles.title),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _recipe.description,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                  '⏱', '${_recipe.prepTime + _recipe.cookTime}', 'min total'),
              _buildStatItem('🔪', '${_recipe.prepTime}', 'min prep'),
              _buildStatItem('🍳', '${_recipe.cookTime}', 'min cook'),
              _buildStatItem('📊', _recipe.difficulty, 'level'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Servings:', style: AppTextStyles.body),
              const Spacer(),
              IconButton(
                onPressed: _servings > 1
                    ? () => setState(() => _servings--)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
              ),
              Text(
                '$_servings',
                style: AppTextStyles.subtitle,
              ),
              IconButton(
                onPressed: () => setState(() => _servings++),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
          if (_recipe.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recipe.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 107, 53, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.subtitle),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildNutrition() {
    final n = _recipe.nutrition;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromRGBO(255, 107, 53, 0.05),
            Color.fromRGBO(255, 140, 90, 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color.fromRGBO(255, 107, 53, 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrition per serving', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem(
                  '🔥', '${n.calories}', 'kcal', AppColors.error),
              _buildNutritionItem('💪', '${n.protein}g', 'protein', Colors.blue),
              _buildNutritionItem(
                  '🌾', '${n.carbs}g', 'carbs', Colors.orange),
              _buildNutritionItem('🥑', '${n.fat}g', 'fat', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
      String emoji, String value, String label, Color color) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        tabs: const [
          Tab(text: 'Ingredients'),
          Tab(text: 'Steps'),
          Tab(text: 'Tips'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildIngredients(),
          _buildSteps(),
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _recipe.ingredients.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _recipe.ingredients[index],
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSteps() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _recipe.steps.length,
      itemBuilder: (context, index) {
        final step = _recipe.steps[index];
        final isActive = _activeStep == index;
        return GestureDetector(
          onTap: () => setState(() => _activeStep = isActive ? -1 : index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive
                  ? Color.fromRGBO(255, 107, 53, 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.border,
                width: isActive ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primary
                            : AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${step.stepNumber}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        step.instruction,
                        style: AppTextStyles.body,
                      ),
                    ),
                  ],
                ),
                if (step.timerSeconds != null && isActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _startTimer(step.timerSeconds!),
                          icon: const Icon(Icons.timer, size: 18),
                          label: Text(
                            _timerRunning
                                ? '⏱ ${_formatTime(_timerSeconds)}'
                                : 'Start ${_formatTime(step.timerSeconds!)} timer',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (step.tip != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromRGBO(255, 193, 7, 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text('💡', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            step.tip!,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadAiTips() async {
    if (_aiTips != null || _loadingTips) return;
    setState(() => _loadingTips = true);
    try {
      final tips = await _gemini.getCookingTips(_recipe);
      if (mounted) setState(() {
        _aiTips = tips;
        _loadingTips = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _aiTips = 'Taste as you cook. Prep ingredients first. Use fresh ingredients.';
        _loadingTips = false;
      });
    }
  }

  Widget _buildTips() {
    if (_aiTips == null && !_loadingTips) {
      _loadAiTips();
    }
    if (_loadingTips) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    final text = _aiTips ?? '';
    final lines = text
        .split(RegExp(r'\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      lines.add('Taste as you cook and adjust seasoning.');
      lines.add('Prep all ingredients before starting.');
      lines.add('Use fresh, quality ingredients.');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 193, 7, 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color.fromRGBO(255, 193, 7, 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(lines[index], style: AppTextStyles.body),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSimilarRecipes() async {
    if (_loadingSimilar) return;
    setState(() => _loadingSimilar = true);
    try {
      final list = await _gemini.generateSimilarRecipes(_recipe);
      if (!mounted) return;
      setState(() => _loadingSimilar = false);
      _showSimilarRecipesSheet(list);
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSimilar = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load similar recipes: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSimilarRecipesSheet(List<Recipe> recipes) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Similar Recipes', style: AppTextStyles.subtitle),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final r = recipes[index];
                  return ListTile(
                    leading: Text(Recipe.getCuisineEmoji(r.cuisine),
                        style: const TextStyle(fontSize: 28)),
                    title: Text(r.title),
                    subtitle: Text('${r.cookTime} min · ${r.difficulty}'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: r),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _loadingSimilar ? null : _loadSimilarRecipes,
              icon: _loadingSimilar
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restaurant_menu),
              label: Text(_loadingSimilar ? 'Loading...' : 'Similar Recipes'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CookingModeScreen(recipe: _recipe),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Start Cooking 👨‍🍳'),
            ),
          ],
        ),
      ),
    );
  }

}
