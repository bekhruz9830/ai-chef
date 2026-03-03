import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/keys.dart';
import '../models/recipe.dart';

class GroqService {
  static const _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static String get _apiKey => groqApiKey;

  static const _visionModels = [
    'meta-llama/llama-4-scout-17b-16e-instruct',
    'llama-3.2-11b-vision-preview',
    'llama-3.2-90b-vision-preview',
  ];

  // ─── PUBLIC API ───────────────────────────────────────────────────────────

  /// Recognizes food ingredients from photo. Use with [FirebaseRecipeService.findByIngredients].
  Future<List<String>> recognizeIngredients(Uint8List imageBytes) async {
    final ingredients = await _recognizeIngredients(imageBytes);
    debugPrint('✅ Recognized ingredients: $ingredients');
    return ingredients;
  }

  /// Legacy: recognize + fetch recipes via API. Prefer [recognizeIngredients] + [FirebaseRecipeService.findByIngredients].
  Future<List<Recipe>> analyzeIngredientsFromImage(Uint8List imageBytes) async {
    final ingredients = await recognizeIngredients(imageBytes);
    if (ingredients.isEmpty) {
      throw Exception('No food ingredients detected. Try a clearer photo.');
    }
    return _fetchRecipes(ingredients);
  }

  // ─── STEP 1: VISION ──────────────────────────────────────────────────────

  Future<List<String>> _recognizeIngredients(Uint8List imageBytes) async {
    String? lastError;

    for (final model in _visionModels) {
      try {
        final result = await _recognizeWithModel(model, imageBytes);
        if (result.isNotEmpty) return result;
      } catch (e) {
        lastError = e.toString();
        debugPrint('Vision model $model failed: $e');
      }
    }

    throw Exception('Could not recognize ingredients. $lastError');
  }

  Future<List<String>> _recognizeWithModel(
      String model, Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.1,
            'max_tokens': 400,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                  },
                  {
                    'type': 'text',
                    'text': '''Look at this image and identify ALL food ingredients visible.
Be very specific about the TYPE of ingredient:
- For pasta/noodles: specify exactly what type (e.g. "long thin noodles", "pasta sheets", "rice noodles", "egg noodles", "spaghetti", "lasagna sheets")
- For meat: specify (e.g. "ground beef", "beef chunks", "chicken breast", "lamb", "pork belly")
- For vegetables: name each one

Reply ONLY with a JSON array of strings. Example: ["long thin noodles", "ground beef", "onion", "tomato"]
If no food is visible, return: []''',
                  },
                ],
              },
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('Vision [$model] status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    final first = choices != null && choices.isNotEmpty ? choices.first : null;
    final content = (first is Map<String, dynamic>)
        ? (first['message']?['content']?.toString().trim() ?? '')
        : '';

    debugPrint('Vision response: $content');

    final cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = cleaned.indexOf('[');
    final end = cleaned.lastIndexOf(']');
    if (start == -1 || end == -1) throw Exception('No JSON array: $content');

    final list = jsonDecode(cleaned.substring(start, end + 1)) as List;
    return list.map((e) => e.toString().toLowerCase().trim()).where((s) => s.isNotEmpty).toList();
  }

  // ─── STEP 2: RECIPE MATCHING ──────────────────────────────────────────────

  Future<List<Recipe>> _fetchRecipes(List<String> ingredients) async {
    try {
      return await _callRecipeAPI(ingredients);
    } catch (e) {
      debugPrint('Recipe API failed, retrying: $e');
      await Future.delayed(const Duration(milliseconds: 1500));
      return await _callRecipeAPI(ingredients);
    }
  }

  Future<List<Recipe>> _callRecipeAPI(List<String> ingredients) async {
    final ingredientsStr = ingredients.join(', ');

    final systemPrompt = '''You are a world-renowned culinary expert. Your job is to suggest REAL traditional dishes that actually use the scanned ingredients.

═══════════════════════════════════════
INGREDIENT → DISH MATCHING RULES (STRICT)
═══════════════════════════════════════

NOODLES / PASTA:
• "long thin noodles" / "spaghetti" / "egg noodles" → ONLY: Lagman (Uzbek), Spaghetti Carbonara (Italian), Pasta Bolognese (Italian), Ramen (Japanese), Pad Thai (Thai), Lo Mein (Chinese)
• "rice noodles" / "flat rice noodles" → ONLY: Pad Thai (Thai), Pho (Vietnamese), Bun Bo Hue (Vietnamese)
• "pasta sheets" / "lasagna sheets" / "wide flat pasta" → ONLY: Lasagna (Italian), Pastitsio (Greek)
• "short pasta" / "penne" / "rigatoni" → ONLY: Pasta al Forno (Italian), Pastitsio (Greek)
• FORBIDDEN with any noodles: Dimlama, Shurpa/Shorpa, Beshbarmak, Guacamole, Ceviche

MEAT:
• "ground beef" / "minced beef" → Pasta Bolognese, Köfte, Moussaka, Cheeseburger, Tacos
• "beef chunks" / "beef stew" → Plov (if with rice+carrot), Dimlama, Boeuf Bourguignon, Beef Stroganoff
• "lamb chunks" → Plov, Shurpa, Lagman (only if noodles present), Mansaf, Coq au Vin
• "pork belly" / "bacon" → Ramen, Churrasco, Feijoada, Coq au Vin
• "chicken" → Butter Chicken, Biryani, Coq au Vin, Teriyaki, Shawarma, Roast Chicken

RICE:
• "rice" + "lamb/beef" + "carrot" → Plov (Uzbek) — BEST MATCH
• "rice" + "chicken" + "spices" → Biryani (Indian), Kabsa (Arabic)
• "rice" + "vegetables" → Fried Rice (Chinese), Risotto (Italian)

EGGS:
• "eggs" + "pasta" → Spaghetti Carbonara (Italian), Pasta al Forno
• "eggs" + "vegetables" → Shakshuka (Arabic/Israeli), Frittata (Italian), Omelette
• "eggs" alone → Omelette, Shakshuka, Eggs Benedict

VEGETABLES:
• "tomato" + "eggplant" + "zucchini" → Ratatouille (French), Imam Bayildi (Turkish)
• "spinach" + "cheese/paneer" → Palak Paneer (Indian), Spanakopita (Greek)
• "chickpeas" → Hummus (Lebanese), Chana Masala (Indian), Falafel (Lebanese)
• "potatoes" + "meat" → Dimlama (Uzbek), Massaman Curry (Thai), Shepherd's Pie

═══════════════════════════════════════
ABSOLUTE RULES
═══════════════════════════════════════
1. ONLY suggest dishes where the scanned ingredients are ACTUALLY used in the traditional recipe
2. NEVER invent dishes — only real dishes with real names
3. Each dish MUST have at least 7 detailed cooking steps
4. Steps must be PRACTICAL and DETAILED (not "cook the meat" but "Heat oil in a heavy pan over high heat until smoking. Add lamb chunks — they should sizzle loudly. Brown on all sides for 10 minutes without stirring to form a crust.")
5. Salt, oil, water, garlic, basic spices are assumed always available
6. Reply ONLY with valid JSON array — no text outside JSON, no markdown''';

    final userPrompt = '''Scanned ingredients: $ingredientsStr

Find 4-5 REAL traditional dishes from DIFFERENT world cuisines that genuinely use these exact ingredients.

IMPORTANT MATCHING CHECK:
- If ingredients include "long thin noodles" or "spaghetti" → suggest Lagman, Spaghetti Carbonara, Ramen, Pad Thai (NOT lasagna, NOT ravioli)
- If ingredients include "rice" + "carrot" + "meat" → suggest Plov first
- If ingredients include "eggplant" → suggest Imam Bayildi, Moussaka, Ratatouille
- Always verify each dish actually uses the scanned ingredients before suggesting it

Reply ONLY with this JSON:
[
  {
    "title": "Dish Name in English",
    "cuisine": "Italian",
    "description": "Authentic description: what this dish is, where it is from, when it is eaten (2-3 sentences)",
    "difficulty": "Easy",
    "prepTime": 15,
    "cookTime": 45,
    "servings": 4,
    "tags": ["pasta", "italian", "traditional"],
    "ingredients": [
      "400g spaghetti",
      "200g guanciale or pancetta, diced",
      "4 egg yolks",
      "100g Pecorino Romano, grated",
      "Black pepper, salt"
    ],
    "steps": [
      {
        "stepNumber": 1,
        "instruction": "Bring a large pot of water to boil. Add 1 tablespoon of salt — the water should taste like the sea. This is the only chance to season the pasta itself.",
        "timerSeconds": null,
        "tip": "Use at least 4 liters of water for 400g pasta."
      },
      {
        "stepNumber": 2,
        "instruction": "Detailed step...",
        "timerSeconds": 300,
        "tip": "Chef tip here"
      }
    ],
    "nutrition": {
      "calories": 620,
      "protein": 28,
      "carbs": 72,
      "fat": 22
    }
  }
]''';

    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'temperature': 0.1,
            'max_tokens': 6000,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {'role': 'user', 'content': userPrompt},
            ],
          }),
        )
        .timeout(const Duration(seconds: 60));

    debugPrint('Recipe API status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Recipe API error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    final first = choices != null && choices.isNotEmpty ? choices.first : null;
    final content = (first is Map<String, dynamic>)
        ? (first['message']?['content']?.toString().trim() ?? '')
        : '';

    debugPrint('Recipe response length: ${content.length}');

    final cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
    final match = RegExp(r'\[[\s\S]*\]').firstMatch(cleaned);
    if (match == null) throw Exception('No JSON array in response: $content');

    final list = jsonDecode(match.group(0)!) as List;
    final now = DateTime.now();
    return list.asMap().entries.map((e) => _mapToRecipe(e.value, now, e.key)).toList();
  }

  // ─── MAPPING ──────────────────────────────────────────────────────────────

  Recipe _mapToRecipe(dynamic entry, DateTime createdAt, int index) {
    final r = entry is Map<String, dynamic> ? entry : <String, dynamic>{};
    final steps = (r['steps'] as List? ?? []).map((s) {
      final step = s is Map<String, dynamic> ? s : <String, dynamic>{};
      return RecipeStep(
        stepNumber: step['stepNumber'] as int? ?? 0,
        instruction: step['instruction']?.toString() ?? '',
        timerSeconds: step['timerSeconds'] as int?,
        tip: step['tip']?.toString(),
      );
    }).toList();

    final n = r['nutrition'] is Map<String, dynamic> ? r['nutrition'] as Map<String, dynamic> : <String, dynamic>{};
    return Recipe(
      id: '${createdAt.millisecondsSinceEpoch}_$index',
      title: r['title']?.toString() ?? '',
      description: r['description']?.toString() ?? '',
      ingredients: List<String>.from(r['ingredients'] ?? []),
      steps: steps,
      cookTime: r['cookTime'] as int? ?? 0,
      prepTime: r['prepTime'] as int? ?? 0,
      servings: r['servings'] as int? ?? 2,
      difficulty: r['difficulty']?.toString() ?? 'Medium',
      cuisine: r['cuisine']?.toString() ?? 'International',
      imageUrl: '',
      tags: List<String>.from(r['tags'] ?? []),
      nutrition: NutritionInfo(
        calories: n['calories'] as int? ?? 0,
        protein: (n['protein'] ?? 0).toDouble(),
        carbs: (n['carbs'] ?? 0).toDouble(),
        fat: (n['fat'] ?? 0).toDouble(),
        fiber: (n['fiber'] ?? 0).toDouble(),
      ),
      isFavorite: false,
      createdAt: createdAt,
    );
  }
}
