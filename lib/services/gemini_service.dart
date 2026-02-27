import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/recipe.dart';

class GeminiService {
  static const _apiKey = 'AIzaSyAnynagIkqQR_arsxPhyRK3UqPBI_ewPTU';
  
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late ChatSession _chatSession;

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _initChat();
  }

  void _initChat() {
    _chatSession = _model.startChat(history: [
      Content.text('''You are CHEF AI - a world-class culinary expert and personal chef assistant. You have deep knowledge of:
- Global cuisines and cooking techniques
- Nutrition and healthy eating
- Ingredient substitutions and alternatives
- Meal planning and prep strategies
- Food safety and storage
- Budget-friendly cooking

RESPONSE RULES:
1. Always be warm, encouraging and specific
2. Give concrete actionable cooking advice
3. Suggest recipes based on available ingredients
4. Explain cooking techniques clearly
5. Keep responses concise (max 150 words) unless asked for detail
6. Use food emojis naturally
7. If asked to generate recipe, respond with recipe JSON

When generating a recipe add this at the end:
<RECIPE_JSON>
{
  "title": "Recipe Name",
  "description": "Brief description",
  "ingredients": ["ingredient 1", "ingredient 2"],
  "steps": [
    {"stepNumber": 1, "instruction": "Step text", "timerSeconds": 300},
    {"stepNumber": 2, "instruction": "Step text", "timerSeconds": null}
  ],
  "cookTime": 30,
  "prepTime": 10,
  "servings": 2,
  "difficulty": "Easy",
  "cuisine": "Italian",
  "tags": ["healthy", "quick"],
  "nutrition": {
    "calories": 450,
    "protein": 25,
    "carbs": 40,
    "fat": 15,
    "fiber": 8
  }
}
</RECIPE_JSON>'''),
    ]);
  }

  Future<List<Recipe>> analyzeIngredientsFromImage(Uint8List imageBytes) async {
    try {
      final prompt = '''Analyze this image and identify all food ingredients you see.
Then suggest 3 delicious recipes that can be made with these ingredients.

Return ONLY valid JSON array, no markdown:
[
  {
    "title": "Recipe Name",
    "description": "Brief appetizing description",
    "ingredients": ["ingredient 1 with amount", "ingredient 2 with amount"],
    "steps": [
      {"stepNumber": 1, "instruction": "Detailed step", "timerSeconds": 300},
      {"stepNumber": 2, "instruction": "Next step", "timerSeconds": null}
    ],
    "cookTime": 25,
    "prepTime": 10,
    "servings": 2,
    "difficulty": "Easy",
    "cuisine": "International",
    "tags": ["quick", "healthy"],
    "nutrition": {
      "calories": 400,
      "protein": 20,
      "carbs": 35,
      "fat": 12,
      "fiber": 6
    }
  }
]''';

      final response = await _visionModel.generateContent([
        Content.multi([
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ])
      ]);

      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> jsonList = jsonDecode(clean);
      
      return jsonList.map((json) => Recipe.fromJson({
        ...json,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to analyze image: $e');
    }
  }

  Future<Recipe> generateRecipeFromText(String ingredients, {
    String? cuisine,
    String? occasion,
    int? maxTime,
  }) async {
    try {
      final prompt = '''Create a delicious recipe using: $ingredients
${cuisine != null ? 'Cuisine: $cuisine' : ''}
${occasion != null ? 'Occasion: $occasion' : ''}
${maxTime != null ? 'Max time: $maxTime minutes' : ''}

Return ONLY valid JSON, no markdown:
{
  "title": "Recipe Name",
  "description": "Appetizing description",
  "ingredients": ["ingredient with amount"],
  "steps": [
    {"stepNumber": 1, "instruction": "Step", "timerSeconds": 300, "tip": "Optional tip"}
  ],
  "cookTime": 30,
  "prepTime": 10,
  "servings": 2,
  "difficulty": "Easy",
  "cuisine": "Italian",
  "tags": ["healthy"],
  "nutrition": {
    "calories": 450,
    "protein": 25,
    "carbs": 40,
    "fat": 15,
    "fiber": 8
  }
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(clean);
      
      return Recipe.fromJson({
        ...json,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to generate recipe: $e');
    }
  }

  Future<Map<String, List<Recipe>>> generateMealPlan({
    String? dietType,
    int? caloriesPerDay,
  }) async {
    try {
      final prompt = '''Create a 7-day meal plan.
${dietType != null ? 'Diet: $dietType' : ''}
${caloriesPerDay != null ? 'Calories/day: $caloriesPerDay' : ''}

Return ONLY valid JSON:
{
  "monday": [
    {
      "title": "Breakfast",
      "description": "Description",
      "ingredients": ["item"],
      "steps": [{"stepNumber": 1, "instruction": "Step", "timerSeconds": null}],
      "cookTime": 15,
      "prepTime": 5,
      "servings": 1,
      "difficulty": "Easy",
      "cuisine": "International",
      "tags": ["breakfast"],
      "nutrition": {"calories": 350, "protein": 15, "carbs": 40, "fat": 10, "fiber": 5}
    }
  ]
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> json = jsonDecode(clean);
      
      return json.map((day, recipes) => MapEntry(
        day,
        (recipes as List).map((r) => Recipe.fromJson({
          ...r,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'createdAt': DateTime.now().toIso8601String(),
        })).toList(),
      ));
    } catch (e) {
      throw Exception('Failed to generate meal plan: $e');
    }
  }

  Future<String> chat(String message) async {
    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ?? 'Sorry, I could not process your request.';
    } catch (e) {
      throw Exception('Chat failed: $e');
    }
  }

  Future<Map<String, List<String>>> generateShoppingList(
    List<Recipe> recipes,
  ) async {
    try {
      final allIngredients = recipes.expand((r) => r.ingredients).toList();
      final prompt = '''Organize into shopping categories:
${allIngredients.join(', ')}

Return ONLY valid JSON:
{
  "Produce": ["item"],
  "Meat & Seafood": ["item"],
  "Dairy": ["item"],
  "Pantry": ["item"],
  "Spices": ["item"]
}''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> json = jsonDecode(clean);
      
      return json.map((key, value) => MapEntry(key, List<String>.from(value)));
    } catch (e) {
      throw Exception('Failed to generate shopping list: $e');
    }
  }

  void resetChat() => _initChat();
}