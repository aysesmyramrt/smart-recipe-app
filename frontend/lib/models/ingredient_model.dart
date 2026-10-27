class IngredientModel {
  final String name;
  final String? category;

  const IngredientModel({required this.name, this.category});

  factory IngredientModel.fromJson(Map<String, dynamic> json) =>
      IngredientModel(
        name: json['name'] ?? '',
        category: json['category'],
      );

  Map<String, dynamic> toJson() => {'name': name, 'category': category};

  @override
  bool operator ==(Object other) =>
      other is IngredientModel && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class DetectionResult {
  final List<String> ingredients;
  final List<double> confidenceScores;
  final String? suggestion;

  const DetectionResult({
    required this.ingredients,
    required this.confidenceScores,
    this.suggestion,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      DetectionResult(
        ingredients: List<String>.from(json['ingredients'] ?? []),
        confidenceScores:
            List<double>.from((json['confidence_scores'] ?? []).map((e) => (e as num).toDouble())),
        suggestion: json['suggestion'],
      );
}
