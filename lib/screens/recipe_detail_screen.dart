import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../models/recipe.dart';
import '../services/firebase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _servings = _recipe.servings;
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    final newValue = !_recipe.isFavorite;
    await FirebaseService.saveRecipe(_recipe.copyWith(isFavorite: newValue));
    setState(() => _recipe = _recipe.copyWith(isFavorite: newValue));
    if (mounted && newValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('❤️ Saved to favorites!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
            color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.9),
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
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.gradient1, AppColors.gradient2],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                _getCuisineEmoji(_recipe.cuisine),
                style: const TextStyle(fontSize: 80),
              ),
            ],
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
              _buildStatItem('⏱', '${_recipe.prepTime + _recipe.cookTime}', 'min total'),
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
              children: _recipe.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#$tag',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
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
            AppColors.primary.withOpacity(0.05),
            AppColors.gradient2.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrition per serving', style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('🔥', '${n.calories}', 'kcal', AppColors.error),
              _buildNutritionItem('💪', '${n.protein}g', 'protein', Colors.blue),
              _buildNutritionItem('🌾', '${n.carbs}g', 'carbs', Colors.orange),
              _buildNutritionItem('🥑', '${n.fat}g', 'fat', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String emoji, String value, String label, Color color) {
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
          _buildTips(),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    if (_recipe.ingredients.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text('No ingredients listed.', style: AppTextStyles.caption),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
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
                decoration: BoxDecoration(
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

  Widget _buildTips() {
    final tips = [
      'Taste as you cook and adjust seasoning',
      'Prep all ingredients before starting (mise en place)',
      'Keep your workspace clean and organized',
      'Read the full recipe before starting',
      'Use fresh, quality ingredients for best results',
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      itemCount: tips.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('💡', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(tips[index], style: AppTextStyles.body),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {
            _tabController.animateTo(1);
          },
          child: const Text('Start Cooking 👨‍🍳'),
        ),
      ),
    );
  }

  String _getCuisineEmoji(String cuisine) {
    final map = {
      'Italian': '🍝',
      'Asian': '🍜',
      'Mexican': '🌮',
      'American': '🍔',
      'French': '🥐',
      'Indian': '🍛',
      'Mediterranean': '🥗',
      'Japanese': '🍱',
    };
    return map[cuisine] ?? '🍳';
  }
}