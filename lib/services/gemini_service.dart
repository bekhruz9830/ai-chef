import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/recipe.dart';

class GeminiService {
  /// Set via: flutter run --dart-define=GROQ_API_KEY=your_key
  static String get _apiKey => String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _textModel = 'llama-3.3-70b-versatile';
  static const _visionModel = 'meta-llama/llama-4-scout-17b-16e-instruct';

  final List<Map<String, dynamic>> _chatHistory = [];
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;

  GeminiService._internal() {
    _chatHistory.add({'role': 'system', 'content': 'You are CHEF AI culinary expert. Use food emojis. Under 150 words.'});
  }

  /// Analyzes image and returns 4 real traditional recipes for [cuisine].
  Future<List<Recipe>> analyzeIngredientsFromImage(Uint8List imageBytes, {String? cuisine}) async {
    // Limit image size for API (Groq suggests max 4MB base64)
    Uint8List bytes = imageBytes;
    if (imageBytes.length > 2 * 1024 * 1024) {
      bytes = Uint8List.fromList(imageBytes.sublist(0, 2 * 1024 * 1024));
    }
    final base64Image = base64Encode(bytes);
    final cuisineStr = cuisine ?? 'various cuisines';
    final prompt = '''You are a professional chef. Look at the image and list the ingredients you see.
Then create 4 real dishes from $cuisineStr cuisine that use those or similar ingredients.

Rules: Use real dish names. Each recipe needs: title, description, ingredients (with amounts), steps (stepNumber, instruction, timerSeconds in seconds or null), cookTime, prepTime, servings, difficulty, cuisine, tags array, nutrition (calories, protein, carbs, fat, fiber).

Return ONLY a valid JSON array of 4 objects. No markdown, no text before or after. Example shape:
[{"title":"Dish Name","description":"Short description","ingredients":["200g item"],"steps":[{"stepNumber":1,"instruction":"Do this.","timerSeconds":300}],"cookTime":20,"prepTime":10,"servings":2,"difficulty":"Easy","cuisine":"$cuisineStr","tags":[],"nutrition":{"calories":400,"protein":20,"carbs":35,"fat":12,"fiber":5}}]''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': _visionModel,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}},
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'max_tokens': 4000,
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final body = response.body;
      if (response.statusCode == 429) throw Exception('API quota exceeded. Try again later.');
      if (response.statusCode >= 500) throw Exception('Server error. Try again later.');
      throw Exception(body.isNotEmpty ? body : 'API error ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('Empty API response');
    final choice = choices[0] as Map<String, dynamic>?;
    final message = choice?['message'] as Map<String, dynamic>?;
    final content = message?['content'];
    if (content == null) throw Exception('No content in API response');
    String text = content is String ? content : content.toString();

    // Strip markdown code block if present
    const jsonStart = '```json';
    const jsonEnd = '```';
    if (text.contains(jsonStart)) {
      final start = text.indexOf(jsonStart) + jsonStart.length;
      final end = text.contains(jsonEnd) ? text.indexOf(jsonEnd, start) : text.length;
      text = text.substring(start, end).trim();
    }
    final s = text.indexOf('[');
    final e = text.lastIndexOf(']');
    if (s == -1 || e == -1 || e <= s) throw Exception('No recipe list in response');
    String jsonStr = text.substring(s, e + 1);
    // Remove trailing commas before ] or } for lenient parse
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*([}\]])'), r'$1');

    List<dynamic> list;
    try {
      list = jsonDecode(jsonStr) as List;
    } catch (e) {
      throw Exception('Invalid JSON from API: $e');
    }

    final recipes = <Recipe>[];
    for (var i = 0; i < list.length; i++) {
      try {
        final item = list[i];
        if (item is! Map<String, dynamic>) continue;
        final map = Map<String, dynamic>.from(item);
        map['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
        map['createdAt'] = DateTime.now().toIso8601String();
        recipes.add(Recipe.fromJson(map));
      } catch (_) {}
    }
    if (recipes.isEmpty) throw Exception('Could not parse any recipes. Try another photo.');
    return recipes;
  }

  Future<Recipe> generateRecipeFromText(String ingredients, {String? cuisine, int? maxTime}) async {
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': [{'role': 'user', 'content': 'Recipe for: $ingredients. JSON only:\n{"title":"","description":"","ingredients":[],"steps":[{"stepNumber":1,"instruction":"","timerSeconds":300}],"cookTime":20,"prepTime":10,"servings":2,"difficulty":"Easy","cuisine":"International","tags":[],"nutrition":{"calories":400,"protein":20,"carbs":35,"fat":12,"fiber":6}}'}], 'max_tokens': 2000}));
    final text = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    final json = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1));
    return Recipe.fromJson({...Map<String, dynamic>.from(json as Map), 'id': '${DateTime.now().millisecondsSinceEpoch}', 'createdAt': DateTime.now().toIso8601String()});
  }

  Future<Map<String, List<Recipe>>> generateMealPlan({String? dietType, int? caloriesPerDay}) async {
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': [{'role': 'user', 'content': '7-day meal plan. Diet: ${dietType ?? "Balanced"}. JSON only:\n{"monday":[],"tuesday":[],"wednesday":[],"thursday":[],"friday":[],"saturday":[],"sunday":[]}'}], 'max_tokens': 3000}));
    final text = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    final Map<String, dynamic> json = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1));
    return json.map((day, recipes) => MapEntry(day, (recipes as List).map((r) => Recipe.fromJson({...Map<String, dynamic>.from(r as Map), 'id': '${DateTime.now().millisecondsSinceEpoch}', 'createdAt': DateTime.now().toIso8601String()})).toList()));
  }

  Future<String> chat(String message) async {
    _chatHistory.add({'role': 'user', 'content': message});
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': _chatHistory, 'max_tokens': 500}));
    if (response.statusCode != 200) throw Exception(response.body);
    final reply = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    _chatHistory.add({'role': 'assistant', 'content': reply});
    return reply;
  }

  Future<Map<String, List<String>>> generateShoppingList(List<Recipe> recipes) async {
    final ingredients = recipes.expand((r) => r.ingredients).join(', ');
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': [{'role': 'user', 'content': 'Organize: $ingredients\nJSON only:\n{"Produce":[],"Meat & Seafood":[],"Dairy":[],"Pantry":[],"Spices":[]}'}], 'max_tokens': 1000}));
    final text = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    final Map<String, dynamic> json = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1));
    return json.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  /// Generate 2 recipes similar to the given recipe.
  Future<List<Recipe>> generateSimilarRecipes(Recipe recipe) async {
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': [{'role': 'user', 'content': 'Suggest 2 recipes similar to "${recipe.title}" (${recipe.cuisine}). Same style and ingredients. Return ONLY JSON array of 2 objects:\n[{"title":"","description":"","ingredients":[],"steps":[{"stepNumber":1,"instruction":"","timerSeconds":300}],"cookTime":20,"prepTime":10,"servings":2,"difficulty":"Easy","cuisine":"${recipe.cuisine}","tags":[],"nutrition":{"calories":400,"protein":20,"carbs":35,"fat":12,"fiber":6}}]'}], 'max_tokens': 2000}));
    if (response.statusCode != 200) throw Exception(response.body);
    final text = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    final s = text.indexOf('['); final e = text.lastIndexOf(']') + 1;
    if (s == -1 || e == 0) return [];
    final list = jsonDecode(text.substring(s, e)) as List;
    return list.map((j) => Recipe.fromJson({...Map<String, dynamic>.from(j as Map), 'id': '${DateTime.now().millisecondsSinceEpoch}', 'createdAt': DateTime.now().toIso8601String()})).toList();
  }

  /// Get 3вЂ“5 cooking tips specific to this recipe.
  Future<String> getCookingTips(Recipe recipe) async {
    final response = await http.post(Uri.parse(_url),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': _textModel, 'messages': [{'role': 'user', 'content': 'For this recipe: "${recipe.title}". Ingredients: ${recipe.ingredients.take(5).join(", ")}. Give 3 to 5 short cooking tips specific to this dish. Number them. No JSON, just plain text.'}], 'max_tokens': 400}));
    if (response.statusCode != 200) throw Exception(response.body);
    final text = jsonDecode(response.body)['choices'][0]['message']['content'] as String;
    return text.trim();
  }

  void resetChat() {
    _chatHistory.clear();
    _chatHistory.add({'role': 'system', 'content': 'You are CHEF AI culinary expert. Use food emojis. Under 150 words.'});
  }
}

