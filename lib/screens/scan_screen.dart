import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/models/recipe.dart';
import 'package:ai_chef/services/gemini_service.dart';
import 'package:ai_chef/screens/recipe_detail_screen.dart';

enum _ScanState {
  initial,
  imageSelected,
  analyzing,
  ingredientsFound,
  cuisineSelection,
  recipesFound,
}

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _gemini = GeminiService();
  _ScanState _state = _ScanState.initial;
  List<Recipe> _recipes = [];
  Uint8List? _imageBytes;
  String? _errorMessage;

  bool _isQuotaError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('quota') || lower.contains('exceeded');
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _recipes = [];
      _errorMessage = null;
      _state = _ScanState.imageSelected;
    });
  }

  Future<void> _runAnalysis() async {
    if (_imageBytes == null) return;
    setState(() {
      _errorMessage = null;
      _state = _ScanState.analyzing;
    });
    try {
      final recipes = await _gemini.analyzeIngredientsFromImage(_imageBytes!);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _state = _ScanState.ingredientsFound;
      });
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          _state = _ScanState.imageSelected;
          _errorMessage = _isQuotaError(msg)
              ? 'API quota exceeded. Please wait a moment.'
              : 'Could not analyze photo. Check connection and try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showCuisineSelection() {
    setState(() => _state = _ScanState.cuisineSelection);
  }

  Future<void> _runAnalysisForCuisine(String cuisine) async {
    if (_imageBytes == null) return;
    setState(() {
      _errorMessage = null;
      _state = _ScanState.analyzing;
    });
    try {
      final recipes = await _gemini.analyzeIngredientsFromImage(_imageBytes!, cuisine: cuisine);
      if (!mounted) return;
      setState(() {
        _recipes = recipes;
        _state = _ScanState.recipesFound;
      });
    } catch (e) {
      final msg = e.toString();
      if (mounted) {
        setState(() {
          _state = _ScanState.cuisineSelection;
          _errorMessage = _isQuotaError(msg)
              ? 'API quota exceeded. Please wait a moment.'
              : 'Could not load recipes. Try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      _state = _ScanState.initial;
      _imageBytes = null;
      _recipes = [];
      _errorMessage = null;
    });
  }

  List<String> _getDetectedIngredients() {
    final all = <String>{};
    for (final r in _recipes) {
      for (final ing in r.ingredients) {
        final normalized = ing.trim();
        if (normalized.isNotEmpty) all.add(normalized);
      }
    }
    return all.toList();
  }

  /// Extract short ingredient name: "400g spaghetti" -> "spaghetti", "1/2 cup butter" -> "butter".
  String _extractIngredientName(String full) {
    final parts = full.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return full;
    const measurements = {
      'g', 'kg', 'ml', 'l', 'cup', 'cups', 'tsp', 'tbsp', 'cloves', 'clove',
      'piece', 'pieces', 'slice', 'slices', 'fresh', 'dried', 'grated', 'chopped', 'diced',
    };
    for (int i = parts.length - 1; i >= 0; i--) {
      final w = parts[i].toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      if (w.isNotEmpty &&
          !measurements.contains(w) &&
          !RegExp(r'^\d').hasMatch(parts[i])) {
        final word = parts[i];
        if (word.length <= 1) return word.toUpperCase();
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
    }
    final last = parts.last;
    if (last.length <= 1) return last.toUpperCase();
    return last[0].toUpperCase() + last.substring(1).toLowerCase();
  }

  NutritionInfo _getAverageNutrition() {
    if (_recipes.isEmpty) {
      return NutritionInfo(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0);
    }
    final n = _recipes.length;
    int calories = 0;
    double protein = 0, carbs = 0, fat = 0, fiber = 0;
    for (final r in _recipes) {
      calories += r.nutrition.calories;
      protein += r.nutrition.protein;
      carbs += r.nutrition.carbs;
      fat += r.nutrition.fat;
      fiber += r.nutrition.fiber;
    }
    return NutritionInfo(
      calories: (calories / n).round(),
      protein: protein / n,
      carbs: carbs / n,
      fat: fat / n,
      fiber: fiber / n,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Ingredients'),
        backgroundColor: AppColors.surface,
        actions: [
          if (_state != _ScanState.initial)
            TextButton(
              onPressed: _reset,
              child: const Text('New scan'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_state == _ScanState.initial) _buildInitialState(),
            if (_state == _ScanState.imageSelected) _buildImageSelected(),
            if (_state == _ScanState.analyzing) _buildAnalyzing(),
            if (_state == _ScanState.ingredientsFound) _buildIngredientsScreen(),
            if (_state == _ScanState.cuisineSelection) _buildCuisineSelection(),
            if (_state == _ScanState.recipesFound) _buildRecipesScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromRGBO(255, 107, 53, 0.1),
                  Color.fromRGBO(255, 140, 90, 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Color.fromRGBO(255, 107, 53, 0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('📸', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                const Text(
                  'Point camera at ingredients',
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 8),
                Text(
                  'AI will detect ingredients and suggest recipes',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            icon: const Icon(Icons.photo_library),
            label: const Text('Choose from Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelected() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _imageBytes!,
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _runAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Analyze ingredients'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Retake'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Color.fromRGBO(230, 76, 60, 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.error),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _runAnalysis,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyzing() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradient1, AppColors.gradient2],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Detecting ingredients...',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Finding recipes from different cuisines',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsScreen() {
    final rawIngredients = _getDetectedIngredients();
    final nameSet = <String>{};
    for (final ing in rawIngredients) {
      final name = _extractIngredientName(ing);
      if (name.isNotEmpty) nameSet.add(name);
    }
    final ingredientNames = nameSet.take(10).toList();
    final nutrition = _getAverageNutrition();
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🥦 Detected ingredients',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: ingredientNames.map((name) {
              return Chip(
                label: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            '📊 Estimated nutrition (per serving)',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '🔥 ${nutrition.calories} cal',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '💪 ${nutrition.protein.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '🌾 ${nutrition.carbs.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '🥑 ${nutrition.fat.toStringAsFixed(0)}g',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showCuisineSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Find Recipes 🍽️'),
            ),
          ),
        ],
      ),
    );
  }

  static const List<MapEntry<String, String>> _worldCuisines = [
    MapEntry('🇮🇹', 'Italian'),
    MapEntry('🇯🇵', 'Japanese'),
    MapEntry('🇲🇽', 'Mexican'),
    MapEntry('🇮🇳', 'Indian'),
    MapEntry('🇫🇷', 'French'),
    MapEntry('🇨🇳', 'Chinese'),
    MapEntry('🇹🇷', 'Turkish'),
    MapEntry('🇺🇿', 'Uzbek'),
    MapEntry('🇬🇷', 'Greek'),
    MapEntry('🇹🇭', 'Thai'),
    MapEntry('🇪🇸', 'Spanish'),
    MapEntry('🇲🇦', 'Moroccan'),
    MapEntry('🇱🇧', 'Lebanese'),
    MapEntry('🇰🇷', 'Korean'),
    MapEntry('🇻🇳', 'Vietnamese'),
    MapEntry('🇧🇷', 'Brazilian'),
    MapEntry('🇵🇪', 'Peruvian'),
    MapEntry('🇦🇪', 'Arabic'),
    MapEntry('🇷🇺', 'Russian'),
    MapEntry('🇺🇸', 'American'),
    MapEntry('🌍', 'International'),
  ];

  Widget _buildCuisineSelection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a cuisine 🌍',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 6),
          Text(
            'We\'ll suggest 3–4 recipes using your ingredients',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: _worldCuisines.length,
            itemBuilder: (context, index) {
              final e = _worldCuisines[index];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _runAnalysisForCuisine(e.value),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(e.key, style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 6),
                        Text(
                          e.value,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipesScreen() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipes for your ingredients',
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 4),
          Text(
            '${_recipes.length} options from different cuisines',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ..._recipes.map((recipe) => _buildRecipeCard(recipe)),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: recipe),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: SizedBox(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  Recipe.getImageUrl(recipe.title),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.orange.shade100,
                    child: Center(
                      child: Text(
                        Recipe.getCuisineEmoji(recipe.cuisine),
                        style: const TextStyle(fontSize: 48),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getCuisineFlag(recipe.cuisine),
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          recipe.title,
                          style: AppTextStyles.subtitle,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(255, 107, 53, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.description,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip('⏱', '${recipe.cookTime} min'),
                      const SizedBox(width: 8),
                      _buildInfoChip('👤', '${recipe.servings}'),
                      const SizedBox(width: 8),
                      _buildInfoChip('🔥', '${recipe.nutrition.calories} cal'),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$emoji $value',
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getCuisineFlag(String cuisine) {
    const flags = {
      'Italian': '🇮🇹',
      'Japanese': '🇯🇵',
      'Mexican': '🇲🇽',
      'Indian': '🇮🇳',
      'French': '🇫🇷',
      'Chinese': '🇨🇳',
      'Turkish': '🇹🇷',
      'Uzbek': '🇺🇿',
      'Greek': '🇬🇷',
      'Thai': '🇹🇭',
      'Spanish': '🇪🇸',
      'Moroccan': '🇲🇦',
      'Lebanese': '🇱🇧',
      'Korean': '🇰🇷',
      'Vietnamese': '🇻🇳',
      'Brazilian': '🇧🇷',
      'Peruvian': '🇵🇪',
      'Arabic': '🇦🇪',
      'Russian': '🇷🇺',
      'American': '🇺🇸',
      'Asian': '🇯🇵',
      'Middle Eastern': '🌍',
      'International': '🌍',
    };
    return flags[cuisine] ?? '🌍';
  }
}
