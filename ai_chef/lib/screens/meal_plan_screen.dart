import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/firebase_service.dart';
import 'package:ai_chef/services/gemini_service.dart';
import 'package:ai_chef/services/localization_service.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/screens/recipe_detail_screen.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  final _gemini = GeminiService();
  Map<String, List<Recipe>> _mealPlan = {};
  bool _loading = false;
  bool _generating = false;
  String _selectedDiet = 'Balanced';
  int _calories = 2000;

  final List<String> _dietTypes = [
    'Balanced',
    'Vegetarian',
    'Vegan',
    'Low-carb',
    'High-protein',
    'Mediterranean',
  ];

  final List<String> _days = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  @override
  void initState() {
    super.initState();
    _loadMealPlan();
  }

  Future<void> _loadMealPlan() async {
    setState(() => _loading = true);
    final plan = await FirebaseService.getMealPlan();
    if (mounted) {
      setState(() {
        _mealPlan = plan;
        _loading = false;
      });
    }
  }

  Future<void> _generateMealPlan() async {
    setState(() => _generating = true);
    try {
      final plan = await _gemini.generateMealPlan(
        dietType: _selectedDiet,
        caloriesPerDay: _calories,
      );
      setState(() => _mealPlan = plan);
      await FirebaseService.saveMealPlan(plan);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${Provider.of<LocalizationService>(context, listen: false).t('meal_plan_generated')}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<LocalizationService>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(loc.t('meal_planner')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildSettings(),
                  _buildGenerateButton(),
                  if (_mealPlan.isNotEmpty) _buildPlan(),
                  if (_mealPlan.isEmpty && !_generating) _buildEmptyState(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSettings() {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(Provider.of<LocalizationService>(context).t('plan_settings'), style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 16),
          Text(Provider.of<LocalizationService>(context).t('diet_type'), style: AppTextStyles.body.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _dietTypes.map((diet) {
              final isSelected = _selectedDiet == diet;
              return GestureDetector(
                onTap: () => setState(() => _selectedDiet = diet),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    diet,
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Provider.of<LocalizationService>(context).t('daily_calories'), style: AppTextStyles.body.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
              Text(
                '$_calories ${Provider.of<LocalizationService>(context).t('kcal')}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            value: _calories.toDouble(),
            min: 1200,
            max: 3500,
            divisions: 23,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _calories = v.round()),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: ElevatedButton.icon(
        onPressed: _generating ? null : _generateMealPlan,
        icon: _generating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(
          _generating
              ? Provider.of<LocalizationService>(context).t('generating_meal_plan')
              : '${Provider.of<LocalizationService>(context).t('generate_meal_plan')} ✨',
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 40),
          const Text('📅', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(Provider.of<LocalizationService>(context).t('no_meal_plan_yet'), style: AppTextStyles.title.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text(
            Provider.of<LocalizationService>(context).t('generate_meal_plan_hint'),
            style: AppTextStyles.body.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlan() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${Provider.of<LocalizationService>(context).t('your_week')} 📅', style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          ..._days.map((day) {
            final recipes = _mealPlan[day] ?? [];
            if (recipes.isEmpty) return const SizedBox();
            return _buildDayCard(day, recipes);
          }),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day, List<Recipe> recipes) {
    const mealEmojis = ['🌅', '☀️', '🌙'];
    final loc = Provider.of<LocalizationService>(context);
    final mealNames = [loc.t('breakfast'), loc.t('lunch'), loc.t('dinner')];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(255, 107, 53, 0.1),
                  Color.fromRGBO(255, 140, 90, 0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Text(
                  loc.t(day),
                  style: AppTextStyles.subtitle.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
                const Spacer(),
                Text(
                  '${recipes.fold(0, (sum, r) => sum + r.nutrition.calories)} ${loc.t('kcal')}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...recipes.asMap().entries.map((entry) {
            final index = entry.key;
            final recipe = entry.value;
            final isLast = index == recipes.length - 1;
            return Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Text(
                          mealEmojis[index % mealEmojis.length],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mealNames[index % mealNames.length],
                                style: AppTextStyles.caption.copyWith(
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                              Text(
                                recipe.title,
                                style: AppTextStyles.body.copyWith(
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '⏱ ${recipe.cookTime}m',
                          style: AppTextStyles.caption.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}
