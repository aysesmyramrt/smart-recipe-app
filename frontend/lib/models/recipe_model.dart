class RecipeComment {
  final String id;
  final String userId;
  final String displayName;
  final String text;
  final int rating;
  final DateTime? createdAt;

  const RecipeComment({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.rating,
    this.createdAt,
  });

  factory RecipeComment.fromJson(Map<String, dynamic> json) => RecipeComment(
        id: json['id'] ?? '',
        userId: json['user_id'] ?? '',
        displayName: json['display_name'] ?? 'Kullanıcı',
        text: json['text'] ?? '',
        rating: json['rating'] ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
      );
}

class RecipeSuggestionModel {
  final String title;
  final String difficulty;
  final int cookTime;
  final String category;
  final String description;

  const RecipeSuggestionModel({
    required this.title,
    required this.difficulty,
    required this.cookTime,
    required this.category,
    required this.description,
  });

  factory RecipeSuggestionModel.fromJson(Map<String, dynamic> json) =>
      RecipeSuggestionModel(
        title: json['title'] ?? '',
        difficulty: json['difficulty'] ?? 'Kolay',
        cookTime: json['cook_time'] ?? 0,
        category: json['category'] ?? '',
        description: json['description'] ?? '',
      );
}

class RecipeIngredient {
  final String name;
  final String amount;
  final String unit;
  final String group; // "Hamur için", "Sos için", "Malzemeler" vs.

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.group = 'Malzemeler',
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] ?? '',
        amount: json['amount'] ?? '',
        unit: json['unit'] ?? '',
        group: json['group'] ?? 'Malzemeler',
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'amount': amount,
    'unit': unit,
    'group': group,
  };
}

class NutritionInfo {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const NutritionInfo({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
      );
}

class RecipeModel {
  final String id;
  final String title;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final NutritionInfo nutrition;
  final int prepTime;         // hazırlık süresi (dakika)
  final int cookTime;         // pişirme süresi (dakika)
  final int servings;         // kaç kişilik
  final String difficulty;    // Kolay | Orta | Zor
  final String category;
  final String? imageUrl;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    this.prepTime = 0,
    required this.cookTime,
    this.servings = 2,
    required this.difficulty,
    required this.category,
    this.imageUrl,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) => RecipeModel(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        ingredients: (json['ingredients'] as List<dynamic>? ?? [])
            .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
            .toList(),
        steps: List<String>.from(json['steps'] ?? []),
        nutrition: json['nutrition'] != null
            ? NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>)
            : const NutritionInfo(),
        prepTime: json['prep_time'] ?? 0,
        cookTime: json['cook_time'] ?? 0,
        servings: json['servings'] ?? 2,
        difficulty: json['difficulty'] ?? 'Kolay',
        category: json['category'] ?? 'Ana Yemek',
        imageUrl: json['image_url'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'steps': steps,
        'nutrition': {
          'calories': nutrition.calories,
          'protein': nutrition.protein,
          'carbs': nutrition.carbs,
          'fat': nutrition.fat,
        },
        'prep_time': prepTime,
        'cook_time': cookTime,
        'servings': servings,
        'difficulty': difficulty,
        'category': category,
        'image_url': imageUrl,
      };
}
