import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe.dart';

class FirebaseRecipeService {
  static final _db = FirebaseFirestore.instance;

  /// Ищет рецепты по ингредиентам. Вызывается после Groq Vision.
  static Future<List<Recipe>> findByIngredients(List<String> ingredients) async {
    if (ingredients.isEmpty) return [];

    // Нормализуем ключевые слова
    final keywords = _extractKeywords(ingredients);

    // Firebase не поддерживает полнотекстовый поиск —
    // ищем по keyIngredients через array-contains-any (max 10 значений)
    final searchTerms = keywords.take(10).toList();

    try {
      final snapshot = await _db
          .collection('recipes')
          .where('keyIngredients', arrayContainsAny: searchTerms)
          .limit(20)
          .get();

      var recipes = snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .where((r) => r.ingredients.isNotEmpty)
          .toList();

      // Показывать только блюда с тем белком, который отсканирован: курица → курица, говядина → говядина, баранина → баранина
      recipes = _filterByMainProtein(recipes, ingredients);

      // Досортировать локально по количеству совпадений
      recipes.sort((a, b) {
        final scoreA = _scoreRecipe(a, keywords);
        final scoreB = _scoreRecipe(b, keywords);
        return scoreB.compareTo(scoreA);
      });

      return recipes.take(8).toList();
    } catch (e) {
      // Fallback — поиск по тегам
      return _fallbackSearch(searchTerms, ingredients);
    }
  }

  static Future<List<Recipe>> _fallbackSearch(List<String> terms, List<String> ingredients) async {
    try {
      final snapshot = await _db
          .collection('recipes')
          .where('tags', arrayContainsAny: terms.take(10).toList())
          .limit(20)
          .get();

      var recipes = snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .where((r) => r.ingredients.isNotEmpty)
          .toList();

      recipes = _filterByMainProtein(recipes, ingredients);
      final keywords = _extractKeywords(ingredients);
      recipes.sort((a, b) {
        final scoreA = _scoreRecipe(a, keywords);
        final scoreB = _scoreRecipe(b, keywords);
        return scoreB.compareTo(scoreA);
      });
      return recipes.take(8).toList();
    } catch (e) {
      return [];
    }
  }

  static List<Recipe> _filterByMainProtein(List<Recipe> recipes, List<String> ingredients) {
    final lower = ingredients.map((e) => e.toLowerCase()).toList();
    // Распознаём курица/chicken, говядина/beef, баранина/lamb (в т.ч. по-русски)
    final hasChicken = lower.any((x) => x.contains('chicken') || x.contains('куриц'));
    final hasBeef = lower.any((x) => x.contains('beef') || x.contains('meat') || x.contains('говядин'));
    final hasLamb = lower.any((x) => x.contains('lamb') || x.contains('баранин') || x.contains('ягнен') || x.contains('mutton'));
    final hasRedMeat = hasBeef || hasLamb;

    return recipes.where((r) {
      final t = '${r.title} ${r.ingredients.join(' ')}'.toLowerCase();
      final recipeHasChicken = t.contains('chicken');
      final recipeHasBeef = t.contains('beef');
      final recipeHasLamb = t.contains('lamb');
      final recipeHasRedMeat = recipeHasBeef || recipeHasLamb;

      if (hasChicken && !hasRedMeat) {
        if (!recipeHasChicken) return false;
        if (recipeHasRedMeat && !recipeHasChicken) return false;
        return true;
      }
      if (hasBeef && !hasChicken && !hasLamb) {
        if (!recipeHasBeef) return false;
        if (recipeHasChicken && !recipeHasBeef) return false;
        return true;
      }
      if (hasLamb && !hasChicken && !hasBeef) {
        if (!recipeHasLamb) return false;
        if (recipeHasChicken && !recipeHasLamb) return false;
        return true;
      }
      if (hasRedMeat && !hasChicken) {
        if (recipeHasChicken && !recipeHasRedMeat) return false;
        return true;
      }
      return true;
    }).toList();
  }

  /// Получить рецепт по ID
  static Future<Recipe?> getById(String id) async {
    final doc = await _db.collection('recipes').doc(id).get();
    if (!doc.exists) return null;
    final recipe = _fromFirestore(doc.id, doc.data()!);
    if (recipe.ingredients.isEmpty) return null;
    return recipe;
  }

  /// Получить рецепты по кухне
  static Future<List<Recipe>> getByCuisine(String cuisine) async {
    final snapshot = await _db
        .collection('recipes')
        .where('cuisine', isEqualTo: cuisine)
        .limit(20)
        .get();

    return snapshot.docs
        .map((doc) => _fromFirestore(doc.id, doc.data()))
        .where((r) => r.ingredients.isNotEmpty)
        .toList();
  }

  // ─── HELPERS ─────────────────────────────────────────────────

  static List<String> _extractKeywords(List<String> ingredients) {
    final keywords = <String>{};
    for (final ing in ingredients) {
      final lower = ing.toLowerCase().trim();
      keywords.add(lower);
      // Отдельные слова
      for (final word in lower.split(RegExp(r'[\s,]+'))) {
        if (word.length >= 3) keywords.add(word);
      }
      // Синонимы и русские названия → английские для поиска в Firebase
      if (lower.contains('noodle') || lower.contains('pasta') || lower.contains('spaghetti')) {
        keywords.addAll(['noodles', 'pasta', 'spaghetti']);
      }
      if (lower.contains('beef') || lower.contains('говядин')) keywords.addAll(['beef', 'meat']);
      if (lower.contains('lamb') || lower.contains('баранин') || lower.contains('ягнен') || lower.contains('mutton')) {
        keywords.add('lamb');
      }
      if (lower.contains('meat') && !lower.contains('lamb') && !lower.contains('баранин')) keywords.add('meat');
      if (lower.contains('chicken') || lower.contains('куриц')) keywords.add('chicken');
      if (lower.contains('rice') || lower.contains('рис')) keywords.add('rice');
      if (lower.contains('potato') || lower.contains('картош')) keywords.addAll(['potato', 'potatoes']);
      if (lower.contains('tomato') || lower.contains('помидор')) keywords.add('tomato');
      if (lower.contains('egg') || lower.contains('яйц')) keywords.add('eggs');
    }
    return keywords.toList();
  }

  static int _scoreRecipe(Recipe recipe, List<String> keywords) {
    final text = '${recipe.title} ${recipe.ingredients.join(' ')} ${recipe.tags.join(' ')}'.toLowerCase();
    return keywords.where((kw) => text.contains(kw)).length;
  }

  static Recipe _fromFirestore(String id, Map<String, dynamic> data) {
    final stepsRaw = data['steps'] ?? data['directions'];
    final stepsList = (stepsRaw is List ? stepsRaw : <dynamic>[]);
    final steps = <RecipeStep>[];
    for (var i = 0; i < stepsList.length; i++) {
      final step = stepsList[i];
      String instruction = '';
      int? timerSeconds;
      String? tip;
      int stepNumber = i + 1;
      if (step is String && step.trim().isNotEmpty) {
        instruction = step.trim();
      } else if (step is Map<String, dynamic>) {
        stepNumber = step['stepNumber'] as int? ?? step['number'] as int? ?? i + 1;
        instruction = (step['instruction'] ?? step['text'] ?? step['step'] ?? step['direction'] ?? '')
            .toString()
            .trim();
        timerSeconds = step['timerSeconds'] as int? ?? step['timer'] as int?;
        tip = step['tip']?.toString();
      }
      if (instruction.isEmpty) continue;
      steps.add(RecipeStep(
        stepNumber: stepNumber,
        instruction: instruction,
        timerSeconds: timerSeconds,
        tip: tip,
      ));
    }
    // If no steps from steps/directions, build minimal steps from description
    if (steps.isEmpty) {
      final desc = (data['description']?.toString() ?? '').trim();
      if (desc.isNotEmpty) {
        steps.add(RecipeStep(stepNumber: 1, instruction: desc, timerSeconds: null, tip: null));
      }
    }

    final n = data['nutrition'] as Map<String, dynamic>? ?? {};

    return Recipe(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      cuisine: data['cuisine']?.toString() ?? 'International',
      difficulty: data['difficulty']?.toString() ?? 'Medium',
      prepTime: data['prepTime'] as int? ?? 15,
      cookTime: data['cookTime'] as int? ?? 30,
      servings: data['servings'] as int? ?? 4,
      tags: List<String>.from(data['tags'] ?? []),
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: steps,
      nutrition: NutritionInfo(
        calories: n['calories'] as int? ?? 400,
        protein: (n['protein'] ?? 20).toDouble(),
        carbs: (n['carbs'] ?? 45).toDouble(),
        fat: (n['fat'] ?? 15).toDouble(),
        fiber: (n['fiber'] ?? 4).toDouble(),
      ),
      imageUrl: data['imageUrl']?.toString() ?? '',
      isFavorite: false,
      createdAt: DateTime(2024),
    );
  }
}
