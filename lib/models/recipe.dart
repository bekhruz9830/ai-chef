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
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      steps: (json['steps'] as List<dynamic>? ?? [])
          .map((s) => RecipeStep.fromJson(s))
          .toList(),
      cookTime: json['cookTime'] ?? 0,
      prepTime: json['prepTime'] ?? 0,
      servings: json['servings'] ?? 2,
      difficulty: json['difficulty'] ?? 'Easy',
      cuisine: json['cuisine'] ?? 'International',
      imageUrl: json['imageUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      nutrition: NutritionInfo.fromJson(json['nutrition'] ?? {}),
      isFavorite: json['isFavorite'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
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
    stepNumber: json['stepNumber'] ?? 0,
    instruction: json['instruction'] ?? '',
    timerSeconds: json['timerSeconds'],
    tip: json['tip'],
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
    calories: json['calories'] ?? 0,
    protein: (json['protein'] ?? 0).toDouble(),
    carbs: (json['carbs'] ?? 0).toDouble(),
    fat: (json['fat'] ?? 0).toDouble(),
    fiber: (json['fiber'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'calories': calories,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
    'fiber': fiber,
  };
} 