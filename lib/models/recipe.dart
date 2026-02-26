class Recipe {
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<RecipeStep> steps;
  final int cookTime;
  final int prepTime;
  final int servings;
  final String difficulty;
  final String cuisine;
  final String imageUrl;
  final List<String> tags;
  final NutritionInfo nutrition;
  final bool isFavorite;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.cookTime,
    required this.prepTime,
    required this.servings,
    required this.difficulty,
    required this.cuisine,
    this.imageUrl = '',
    this.tags = const [],
    required this.nutrition,
    this.isFavorite = false,
    required this.createdAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => RecipeStep.fromJson(
              s is Map<String, dynamic> ? s : Map<String, dynamic>.from(s)))
          .toList(),
      cookTime: (json['cookTime'] is int)
          ? json['cookTime'] as int
          : int.tryParse(json['cookTime']?.toString() ?? '0') ?? 0,
      prepTime: (json['prepTime'] is int)
          ? json['prepTime'] as int
          : int.tryParse(json['prepTime']?.toString() ?? '0') ?? 0,
      servings: (json['servings'] is int)
          ? json['servings'] as int
          : int.tryParse(json['servings']?.toString() ?? '2') ?? 2,
      difficulty: json['difficulty']?.toString() ?? 'Easy',
      cuisine: json['cuisine']?.toString() ?? 'International',
      imageUrl: json['imageUrl']?.toString() ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      nutrition: NutritionInfo.fromJson(
        json['nutrition'] is Map<String, dynamic>
            ? json['nutrition'] as Map<String, dynamic>
            : (json['nutrition'] != null
                ? Map<String, dynamic>.from(json['nutrition'])
                : {}),
      ),
      isFavorite: json['isFavorite'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'ingredients': ingredients,
        'steps': steps.map((s) => s.toJson()).toList(),
        'cookTime': cookTime,
        'prepTime': prepTime,
        'servings': servings,
        'difficulty': difficulty,
        'cuisine': cuisine,
        'imageUrl': imageUrl,
        'tags': tags,
        'nutrition': nutrition.toJson(),
        'isFavorite': isFavorite,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Unsplash image URL for the dish; use in Image.network with errorBuilder fallback.
  static String getImageUrl(String dishName) {
    return 'https://source.unsplash.com/400x300/?${Uri.encodeComponent(dishName)},food';
  }

  static String getCuisineEmoji(String cuisine) {
    switch (cuisine.toLowerCase()) {
      case 'uzbek':
        return '🇺🇿';
      case 'italian':
        return '🇮🇹';
      case 'japanese':
        return '🇯🇵';
      case 'chinese':
        return '🇨🇳';
      case 'indian':
        return '🇮🇳';
      case 'french':
        return '🇫🇷';
      case 'mexican':
        return '🇲🇽';
      case 'turkish':
        return '🇹🇷';
      default:
        return '🍽️';
    }
  }

  Recipe copyWith({bool? isFavorite}) => Recipe(
        id: id,
        title: title,
        description: description,
        ingredients: ingredients,
        steps: steps,
        cookTime: cookTime,
        prepTime: prepTime,
        servings: servings,
        difficulty: difficulty,
        cuisine: cuisine,
        imageUrl: imageUrl,
        tags: tags,
        nutrition: nutrition,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
      );
}

class RecipeStep {
  final int stepNumber;
  final String instruction;
  final int? timerSeconds;
  final String? tip;

  RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.timerSeconds,
    this.tip,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) => RecipeStep(
        stepNumber: (json['stepNumber'] is int)
            ? json['stepNumber'] as int
            : int.tryParse(json['stepNumber']?.toString() ?? '0') ?? 0,
        instruction: json['instruction']?.toString() ?? '',
        timerSeconds: json['timerSeconds'] != null
            ? (json['timerSeconds'] is int
                ? json['timerSeconds'] as int
                : int.tryParse(json['timerSeconds'].toString()))
            : null,
        tip: json['tip']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'instruction': instruction,
        'timerSeconds': timerSeconds,
        'tip': tip,
      };
}

class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] is int)
            ? json['calories'] as int
            : int.tryParse(json['calories']?.toString() ?? '0') ?? 0,
        protein: (json['protein'] is num)
            ? (json['protein'] as num).toDouble()
            : double.tryParse(json['protein']?.toString() ?? '0') ?? 0,
        carbs: (json['carbs'] is num)
            ? (json['carbs'] as num).toDouble()
            : double.tryParse(json['carbs']?.toString() ?? '0') ?? 0,
        fat: (json['fat'] is num)
            ? (json['fat'] as num).toDouble()
            : double.tryParse(json['fat']?.toString() ?? '0') ?? 0,
        fiber: (json['fiber'] is num)
            ? (json['fiber'] as num).toDouble()
            : double.tryParse(json['fiber']?.toString() ?? '0') ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
      };
}
