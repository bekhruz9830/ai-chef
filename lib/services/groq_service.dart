import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/keys.dart';
import '../models/recipe.dart';
import '../data/cuisine_dishes.dart';

/// AI service using Groq API (OpenAI-compatible).
/// Vision: meta-llama/llama-4-scout-17b-16e-instruct (scan ingredients)
/// Text:   llama-3.3-70b-versatile (recipes, chat)
class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;

  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';
  static const _chatModel = 'llama-3.3-70b-versatile';

  // ════════════════════════════════════════════════════════
  // GROQ HTTP
  // ════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> _request({
    required String model,
    required List<Map<String, dynamic>> messages,
    bool jsonMode = false,
    int maxTokens = 4096,
    double temperature = 0.2, // низкая = точность важнее фантазии
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
      'temperature': temperature,
    };
    if (jsonMode) body['response_format'] = {'type': 'json_object'};

    final resp = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode(body),
    );

    if (resp.statusCode != 200) {
      final err =
          resp.body.isNotEmpty ? jsonDecode(resp.body) : <String, dynamic>{};
      throw Exception(
          'Groq API ${resp.statusCode}: ${err['error']?['message'] ?? resp.body}');
    }

    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    final reply = choices?.isNotEmpty == true
        ? ((choices!.first as Map)['message']?['content'] as String?)
        : null;

    if (reply == null || reply.isEmpty) throw Exception('Groq returned empty response.');
    return {'content': reply};
  }

  // ════════════════════════════════════════════════════════
  // ════════════════════════════════════════════════════════

  /// Возвращает URL картинки для конкретного блюда.
  /// [dishNameEn] — точное английское название: "Uzbek Plov", "Beef Stroganoff"

  Future<String?> getDishImageUrl(String dishNameEn) async {
    // Попытка 1: точное название + food
    // Попытка 2: только название
    // Попытка 3: только первое слово (страна/тип)
    if (url == null && dishNameEn.contains(' ')) {
    }
    return url;
  }

    try {
        'q': query,
        'image_type': 'photo',
        'category': 'food',   // ТОЛЬКО еда
        'safesearch': 'true',
        'min_width': '640',
        'per_page': '5',
        'order': 'popular',
      });
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final hits = data['hits'] as List?;
        if (hits != null && hits.isNotEmpty) {
          return hits.first['webformatURL'] as String?;
        }
      }
    } catch (e) {
    }
    return null;
  }

  // ════════════════════════════════════════════════════════
  // ШАГ 1 — SCAN: анализ фото → список ингредиентов
  // ════════════════════════════════════════════════════════
  Future<List<String>> scanIngredientsFromImage(Uint8List imageBytes) async {
    if (imageBytes.length > 4 * 1024 * 1024) {
      throw Exception('Image too large. Please choose a photo under 4 MB.');
    }

    final base64Image = base64Encode(imageBytes);

    // Промпт: только ингредиенты, никаких рецептов
    const prompt = '''
Look at this image carefully. Identify every food ingredient, vegetable, fruit, meat, spice or product you can see.

Return ONLY a valid JSON array of ingredient names in English.
Example: ["chicken breast", "red onion", "garlic", "tomato", "olive oil"]

Rules:
- Use specific culinary names (e.g. "chicken thigh" not "meat")
- No duplicates
- No explanations, no markdown, ONLY the JSON array
''';

    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      },
    ];

    try {
      final result = await _request(
        model: _visionModel,
        messages: messages,
        maxTokens: 1024,
        temperature: 0.1, // максимальная точность при распознавании
      );

      String clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        clean = clean.substring(start, end + 1);
      }

      final List<dynamic> list = jsonDecode(clean);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('scanIngredientsFromImage error: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════════
  // ШАГ 2 — DISHES: блюда берём ТОЛЬКО из базы данных
  // AI не выбирает блюда — только генерирует рецепт для выбранного
  // ════════════════════════════════════════════════════════
  Future<List<Recipe>> getDishSuggestions({
    required List<String> ingredients,
    required String country,
    int count = 5,
  }) async {
    final cuisine = getCuisineByName(country);
    if (cuisine == null || cuisine.dishes.isEmpty) {
      debugPrint('⚠️ No dishes found for $country');
      return [];
    }

    // Берём первые count блюд из базы (можно рандомизировать)
    final dishesToShow = cuisine.dishes.length > count
        ? (cuisine.dishes..shuffle()).take(count).toList()
        : cuisine.dishes;

    // Для каждого блюда из базы генерируем рецепт через AI
    final List<Recipe> recipes = [];
    await Future.wait(dishesToShow.map((dbDish) async {
      try {
        final recipe = await _generateRecipeForDish(
          dishTitle: dbDish.title,
          dishNameEn: dbDish.nameEn,
          country: country,
          ingredients: ingredients,
        );
        if (recipe != null) {
          // Картинка по точному запросу из базы
          recipes.add(recipe);
        }
      } catch (e) {
        debugPrint('Error generating recipe for ${dbDish.title}: $e');
      }
    }));

    return recipes;
  }

  /// Генерирует рецепт для конкретного блюда из базы
  Future<Recipe?> _generateRecipeForDish({
    required String dishTitle,
    required String dishNameEn,
    required String country,
    required List<String> ingredients,
  }) async {
    final ingredientList = ingredients.join(', ');

    final prompt = '''
Generate the authentic traditional recipe for "$dishTitle" ($dishNameEn) from $country cuisine.

User has these ingredients available: $ingredientList

Return ONLY valid JSON object, no markdown:
{
  "title": "$dishTitle",
  "name_en": "$dishNameEn",
  "description": "Authentic 2-sentence description of this traditional $country dish",
  "cuisine": "$country",
  "prepTime": 20,
  "cookTime": 45,
  "servings": 4,
  "difficulty": "Easy|Medium|Hard",
  "ingredients": ["exact amount + ingredient name"],
  "steps": [
    {"stepNumber": 1, "instruction": "Detailed authentic cooking step", "timerSeconds": 0}
  ],
  "nutrition": {"calories": 350, "protein": 25, "carbs": 30, "fat": 12, "fiber": 3},
  "tags": ["tag1", "tag2"]
}

Rules:
- prepTime and cookTime must be plain integers (no "min" text)
- Minimum 5 cooking steps
- Use authentic $country cooking technique
- nutrition values must be plain numbers (no "g" or "kcal" text)
''';

    try {
      final result = await _request(
        model: _chatModel,
        messages: [
          {
            'role': 'system',
            'content': 'You are a $country cuisine expert chef. Return only authentic traditional recipes as valid JSON.',
          },
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
        maxTokens: 2048,
        temperature: 0.2,
      );

      final clean = (result['content'] as String)
          .replaceAll('```json', '').replaceAll('```', '').trim();
      final json = _safeJsonParse(clean);
      if (json == null) return null;

      return Recipe.fromJson({
        ...json,
        'id': _generateId(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('_generateRecipeForDish error for $dishTitle: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // ШАГ 3 — FULL RECIPE: точный рецепт конкретного блюда
  // ════════════════════════════════════════════════════════
  Future<Recipe?> getFullRecipe({
    required String dishTitle,
    required String dishNameEn,
    required String country,
    int servings = 4,
  }) async {
    final prompt = '''
Provide the EXACT authentic traditional recipe for "$dishTitle" ($dishNameEn) from $country cuisine.

This must be the REAL traditional recipe as it is cooked in $country — not a variation.

Return ONLY valid JSON object:
{
  "title": "$dishTitle",
  "name_en": "$dishNameEn",
  "description": "Authentic 2-3 sentence description",
  "cuisine": "$country",
  "prepTime": "X min",
  "cookTime": "X min",
  "servings": $servings,
  "difficulty": "Easy|Medium|Hard",
  "ingredients": ["exact amount + ingredient name"],
  "steps": [
    {
      "stepNumber": 1,
      "instruction": "Detailed cooking instruction with technique",
      "timerSeconds": 300
    }
  ],
  "nutrition": {
    "calories": "X kcal",
    "protein": "Xg",
    "carbs": "Xg",
    "fat": "Xg",
    "fiber": "Xg"
  },
  "tags": ["tag1", "tag2"]
}

Rules:
- Minimum 6 cooking steps
- Set timerSeconds for any step with waiting/cooking time (0 if no timer needed)
- Ingredient amounts for $servings servings
- Only real traditional recipe
''';

    try {
      final result = await _request(
        model: _chatModel,
        messages: [
          {
            'role': 'system',
            'content':
                'You are a $country cuisine expert chef. Return only authentic traditional recipes.',
          },
          {'role': 'user', 'content': prompt},
        ],
        jsonMode: true,
        maxTokens: 4096,
        temperature: 0.2,
      );

      final clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final json = _safeJsonParse(clean);
      if (json == null) return null;

      final recipe = Recipe.fromJson({
        ...json,
        'id': _generateId(),
        'createdAt': DateTime.now().toIso8601String(),
      });

      // Точная картинка для блюда
      recipe.imageUrl = await getDishImageUrl('$country $dishNameEn');

      return recipe;
    } catch (e) {
      debugPrint('getFullRecipe error: $e');
      return null;
    }
  }

  // ════════════════════════════════════════════════════════
  // СТАРЫЕ МЕТОДЫ (сохранены для совместимости)
  // ════════════════════════════════════════════════════════

  /// Старый метод — scan фото → сразу рецепты (без выбора страны).
  /// Оставлен для обратной совместимости. Лучше использовать
  /// scanIngredientsFromImage → getDishSuggestions → getFullRecipe
  Future<List<Recipe>> analyzeIngredientsFromImage(Uint8List imageBytes) async {
    if (imageBytes.length > 4 * 1024 * 1024) {
      throw Exception('Image too large. Please choose a photo under 4 MB.');
    }
    final base64Image = base64Encode(imageBytes);
    const prompt = '''
Analyze this image. Identify food ingredients visible.
Suggest 3 real, authentic recipes using those ingredients.
Return ONLY a valid JSON array. Each recipe must have:
"title","description","ingredients"(array),"steps"(array with "stepNumber","instruction","timerSeconds"),
"cookTime","prepTime","servings","difficulty","cuisine",
"nutrition"({"calories","protein","carbs","fat","fiber"}).
No markdown. Only JSON array.
''';
    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          },
        ],
      },
    ];
    try {
      final result = await _request(
        model: _visionModel,
        messages: messages,
        maxTokens: 4096,
      );
      String clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final start = clean.indexOf('[');
      final end = clean.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        clean = clean.substring(start, end + 1);
      }
      final List<dynamic> jsonList = jsonDecode(clean);
      return jsonList
          .map((json) => Recipe.fromJson({
                ...(json as Map<String, dynamic>),
                'id': _generateId(),
                'createdAt': DateTime.now().toIso8601String(),
              }))
          .toList();
    } catch (e) {
      debugPrint('analyzeIngredientsFromImage error: $e');
      rethrow;
    }
  }

  Future<Recipe?> generateRecipeFromText(
    String ingredients, {
    String? cuisine,
    String? occasion,
    int? maxTime,
  }) async {
    try {
      final prompt = '''
Create an authentic recipe using: $ingredients
${cuisine != null ? 'Cuisine: $cuisine' : ''}
${occasion != null ? 'Occasion: $occasion' : ''}
${maxTime != null ? 'Max time: $maxTime minutes' : ''}
Use a REAL dish name from the specified cuisine. Return ONLY valid JSON, no markdown.
''';
      final result = await _request(
        model: _chatModel,
        messages: [{'role': 'user', 'content': prompt}],
        jsonMode: true,
      );
      final clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final json = _safeJsonParse(clean);
      if (json == null) return null;
      final recipe = Recipe.fromJson({
        ...json,
        'id': _generateId(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      recipe.imageUrl = await getDishImageUrl(recipe.nameEn ?? recipe.title);
      return recipe;
    } catch (e) {
      debugPrint('generateRecipeFromText error: $e');
      return null;
    }
  }

  Future<Map<String, List<Recipe>>> generateMealPlan({
    String? dietType,
    int? caloriesPerDay,
  }) async {
    try {
      final prompt = '''
Create a 7-day meal plan with REAL authentic dish names.
${dietType != null ? 'Diet: $dietType' : ''}
${caloriesPerDay != null ? 'Calories/day: $caloriesPerDay' : ''}
Return ONLY valid JSON object with day names as keys and arrays of recipe objects as values.
''';
      final result = await _request(
        model: _chatModel,
        messages: [{'role': 'user', 'content': prompt}],
        jsonMode: true,
      );
      final clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final Map<String, dynamic>? json = _safeJsonParse(clean);
      if (json == null) return {};
      return json.map((day, recipes) => MapEntry(
            day,
            (recipes as List)
                .map((r) => Recipe.fromJson({
                      ...r,
                      'id': _generateId(),
                      'createdAt': DateTime.now().toIso8601String(),
                    }))
                .toList(),
          ));
    } catch (e) {
      debugPrint('generateMealPlan error: $e');
      return {};
    }
  }

  Future<String> chat(String message) async {
    try {
      _chatHistory.add({'role': 'user', 'content': message});
      final result = await _request(
        model: _chatModel,
        messages: _chatHistory,
        maxTokens: 1024,
        temperature: 0.7, // для чата можно чуть выше
      );
      final content = result['content'] as String;
      _chatHistory.add({'role': 'assistant', 'content': content});
      return content;
    } catch (e) {
      _chatHistory.removeLast();
      debugPrint('Chat failed: $e');
      rethrow;
    }
  }

  Future<Map<String, List<String>>> generateShoppingList(
      List<Recipe> recipes) async {
    try {
      final allIngredients = recipes.expand((r) => r.ingredients).toList();
      final prompt = '''
Organize these ingredients into shopping categories.
Return a JSON object with category names as keys and arrays of ingredient strings as values.
Ingredients: ${allIngredients.join(', ')}
Return ONLY valid JSON.
''';
      final result = await _request(
        model: _chatModel,
        messages: [{'role': 'user', 'content': prompt}],
        jsonMode: true,
      );
      final clean = (result['content'] as String)
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final Map<String, dynamic>? json = _safeJsonParse(clean);
      if (json == null) return {};
      return json.map((key, value) =>
          MapEntry(key, List<String>.from(value)));
    } catch (e) {
      debugPrint('generateShoppingList error: $e');
      return {};
    }
  }

  void resetChat() => _initChat();
}
