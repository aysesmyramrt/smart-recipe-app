import 'package:flutter/material.dart';
import 'package:smart_recipe_app/models/recipe_model.dart';

class NutritionPanel extends StatelessWidget {
  final NutritionInfo nutrition;

  const NutritionPanel({super.key, required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Besin Değerleri (porsiyon başı)',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade800,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _NutritionItem(
                label: 'Kalori',
                value: '${nutrition.calories.round()}',
                unit: 'kcal',
                color: Colors.orange,
              ),
              _NutritionItem(
                label: 'Protein',
                value: '${nutrition.protein.round()}',
                unit: 'g',
                color: Colors.blue,
              ),
              _NutritionItem(
                label: 'Karbonhidrat',
                value: '${nutrition.carbs.round()}',
                unit: 'g',
                color: Colors.amber,
              ),
              _NutritionItem(
                label: 'Yağ',
                value: '${nutrition.fat.round()}',
                unit: 'g',
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MacroBar(nutrition: nutrition),
        ],
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
            ),
            Text(unit, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          ],
        ),
      );
}

class _MacroBar extends StatelessWidget {
  final NutritionInfo nutrition;
  const _MacroBar({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    final total = nutrition.protein + nutrition.carbs + nutrition.fat;
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            _bar(nutrition.protein / total, Colors.blue),
            _bar(nutrition.carbs / total, Colors.amber),
            _bar(nutrition.fat / total, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _bar(double ratio, Color color) => Expanded(
        flex: (ratio * 100).round(),
        child: Container(color: color),
      );
}
