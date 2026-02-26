import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/keys.dart';
import '../models/recipe.dart';

class GeminiService {
  /// From --dart-define=GROQ_API_KEY=... or from lib/config/keys.dart
  static String get _apiKey {
    final env = String.fromEnvironment('GROQ_API_KEY', defaultValue: '');
    if (env.isNotEmpty) return env;
    return groqApiKey;
  }
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
    if (_apiKey.isEmpty) {
      throw Exception(
        'Groq API key not set. Add it in lib/config/keys.dart (groqApiKey) or run with: '
        'flutter run --dart-define=GROQ_API_KEY=your_key',
      );
    }
    // Keep image under ~700KB so base64 stays under 1MB (API limit 4MB)
    const maxBytes = 700 * 1024;
    Uint8List bytes = imageBytes;
    if (imageBytes.length > maxBytes) {
      bytes = Uint8List.fromList(imageBytes.sublist(0, maxBytes));
    }
    final base64Image = base64Encode(bytes);
    final cuisineStr = cuisine ?? 'various cuisines';
    final prompt = '''Look at the food image. List ingredients you see, then suggest 4 real recipes from $cuisineStr cuisine.

Return ONLY a JSON array of 4 objects. No other text. Each object:
{"title":"Dish name","description":"One sentence","ingredients":["100g flour","2 eggs"],"steps":[{"stepNumber":1,"instruction":"Step text","timerSeconds":300}],"cookTime":25,"prepTime":10,"servings":2,"difficulty":"Easy","cuisine":"$cuisineStr","tags":[],"nutrition":{"calories":350,"protein":15,"carbs":40,"fat":12,"fiber":3}}

Use real dish names. Steps: stepNumber (int), instruction (string), timerSeconds (int or null).''';

    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
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
        'max_tokens': 4096,
      }),
    ).timeout(const Duration(seconds: 90));

    final status = response.statusCode;
    final bodyStr = response.body;

    if (status == 401) {
      throw Exception(
        'Invalid Groq API key. Get a key at console.groq.com and set it in lib/config/keys.dart (groqApiKey). Keys usually start with gsk_',
      );
    }
    if (status == 429) throw Exception('API quota exceeded. Try again in a minute.');
    if (status == 413) throw Exception('Image too large. Try a smaller or lower quality photo.');
    if (status >= 500) throw Exception('Server error. Try again later.');
    if (status != 200) {
      throw Exception(bodyStr.isNotEmpty ? bodyStr : 'API error $status');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid API response');
    }

    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('Empty API response');

    final first = choices[0];
    if (first is! Map<String, dynamic>) throw Exception('Unexpected response format');
    final message = first['message'] as Map<String, dynamic>?;
    if (message == null) throw Exception('No message in response');

    final content = message['content'];
    String text;
    if (content is String) {
      text = content;
    } else if (content is List) {
      final sb = StringBuffer();
      for (final part in content) {
        if (part is Map && part['type'] == 'text' && part['text'] != null) {
          sb.write(part['text']);
        }
      }
      text = sb.toString();
    } else {
      throw Exception('No text content in response');
    }

    if (text.trim().isEmpty) throw Exception('Empty recipe response. Try another photo.');

    // Strip ```json ... ```
    const jsonStart = '```json';
    const jsonEnd = '```';
    if (text.contains(jsonStart)) {
      final start = text.indexOf(jsonStart) + jsonStart.length;
      final end = text.contains(jsonEnd) ? text.indexOf(jsonEnd, start) : text.length;
      text = text.substring(start, end).trim();
    }

    int s = text.indexOf('[');
    int e = text.lastIndexOf(']');
    if (s == -1 || e == -1 || e <= s) throw Exception('No recipe list in response. Try another photo.');
    String jsonStr = text.substring(s, e + 1);
    jsonStr = jsonStr.replaceAll(RegExp(r',\s*([}\]])'), r'$1');

    List<dynamic> list;
    try {
      list = jsonDecode(jsonStr) as List;
    } catch (e) {
      throw Exception('Could not parse recipes. Try another photo.');
    }

    final recipes = <Recipe>[];
    for (var i = 0; i < list.length; i++) {
      try {
        final item = list[i];
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        _normalizeRecipeMap(map);
        map['id'] = '${DateTime.now().millisecondsSinceEpoch}_$i';
        map['createdAt'] = DateTime.now().toIso8601String();
        recipes.add(Recipe.fromJson(map));
      } catch (_) {}
    }
    if (recipes.isEmpty) throw Exception('Could not parse any recipes. Try another photo.');
    return recipes;
  }

  void _normalizeRecipeMap(Map<String, dynamic> map) {
    if (map['ingredients'] is! List) map['ingredients'] = [];
    map['ingredients'] = (map['ingredients'] as List)
        .map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (map['steps'] is! List) map['steps'] = [];
    final steps = <Map<String, dynamic>>[];
    for (final s in map['steps'] as List) {
      if (s is Map) steps.add(Map<String, dynamic>.from(s));
    }
    map['steps'] = steps;
    if (map['nutrition'] is! Map) {
      map['nutrition'] = {'calories': 400, 'protein': 20, 'carbs': 35, 'fat': 12, 'fiber': 5};
    }
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
    if (_apiKey.isEmpty) {
      throw Exception(
        'Groq API key not set. Add it in lib/config/keys.dart (groqApiKey).',
      );
    }
    _chatHistory.add({'role': 'user', 'content': message});
    final response = await http.post(
      Uri.parse(_url),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _textModel,
        'messages': _chatHistory,
        'max_tokens': 600,
      }),
    ).timeout(const Duration(seconds: 30));

    final status = response.statusCode;
    final bodyStr = response.body;

    if (status == 401) {
      throw Exception('Invalid Groq API key. Check lib/config/keys.dart');
    }
    if (status == 429) throw Exception('Too many requests. Wait a minute and try again.');
    if (status != 200) {
      throw Exception(bodyStr.isNotEmpty ? bodyStr : 'API error $status');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(bodyStr) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid API response');
    }

    final choices = body['choices'] as List?;
    if (choices == null || choices.isEmpty) throw Exception('Empty API response');

    final first = choices[0];
    if (first is! Map<String, dynamic>) throw Exception('Unexpected response format');
    final messageMap = first['message'] as Map<String, dynamic>?;
    if (messageMap == null) throw Exception('No message in response');

    final content = messageMap['content'];
    String reply;
    if (content is String) {
      reply = content;
    } else if (content is List) {
      final sb = StringBuffer();
      for (final part in content) {
        if (part is Map && part['type'] == 'text' && part['text'] != null) {
          sb.write(part['text']);
        }
      }
      reply = sb.toString();
    } else {
      throw Exception('No text in response');
    }

    reply = reply.trim();
    _chatHistory.add({'role': 'assistant', 'content': reply});
    return reply.isEmpty ? 'No response. Try asking again.' : reply;
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

