import 'package:flutter/material.dart';
import 'package:smart_recipe_app/models/ingredient_model.dart';

class IngredientChipWidget extends StatelessWidget {
  final IngredientModel ingredient;
  final VoidCallback onRemove;

  const IngredientChipWidget({
    super.key,
    required this.ingredient,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(ingredient.name),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
    );
  }
}
