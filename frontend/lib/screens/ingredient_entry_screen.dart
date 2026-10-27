import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/models/ingredient_model.dart';
import 'package:smart_recipe_app/models/recipe_model.dart';
import 'package:dio/dio.dart';
import 'package:smart_recipe_app/providers/ingredient_provider.dart';
import 'package:smart_recipe_app/providers/recipe_provider.dart';
import 'package:smart_recipe_app/widgets/ingredient_chip.dart';
import 'package:smart_recipe_app/utils/constants.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';

class IngredientEntryScreen extends ConsumerStatefulWidget {
  final String? category;
  final String? autoDetect; // 'camera' | 'gallery'
  const IngredientEntryScreen({super.key, this.category, this.autoDetect});

  @override
  ConsumerState<IngredientEntryScreen> createState() => _IngredientEntryScreenState();
}

class _IngredientEntryScreenState extends ConsumerState<IngredientEntryScreen> {
  final _textCtrl = TextEditingController();
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoDetect != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _detect(fromCamera: widget.autoDetect == 'camera');
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _addIngredient(String name) {
    if (name.trim().isEmpty) return;
    ref.read(ingredientNotifierProvider.notifier).add(IngredientModel(name: name.trim()));
    _textCtrl.clear();
  }


  Future<void> _detect({bool fromCamera = true}) async {
    setState(() => _isDetecting = true);
    await ref.read(detectionNotifierProvider.notifier).pickAndDetect(fromCamera: fromCamera);
    final detectionState = ref.read(detectionNotifierProvider);
    if (detectionState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${detectionState.error}'), backgroundColor: Colors.red),
      );
    } else {
      final result = detectionState.valueOrNull;
      if (result != null) {
        if (result.ingredients.isEmpty && result.suggestion != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.suggestion!)));
        } else {
          ref.read(ingredientNotifierProvider.notifier).addAll(result.ingredients);
        }
      }
    }
    setState(() => _isDetecting = false);
  }

  String _friendlyError(Object? error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is List && data.isNotEmpty) {
        return data.first['msg']?.toString() ?? 'Tarif oluşturulamadı.';
      }
      if (data is Map && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (error.response?.statusCode == 422) return 'En az 2 malzeme gereklidir.';
    }
    return 'Tarif oluşturulamadı. Lütfen tekrar deneyin.';
  }

  Future<void> _generateRecipe() async {
    final ingredients = ref.read(ingredientNotifierProvider);
    if (ingredients.length == 1) {
      await _showSuggestions(ingredients.first.name);
      return;
    }
    await ref.read(recipeNotifierProvider.notifier).generate(
          ingredients: ingredients.map((i) => i.name).toList(),
          category: widget.category,
        );
    final recipeState = ref.read(recipeNotifierProvider);
    if (recipeState.hasError) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(recipeState.error)), backgroundColor: Colors.red),
      );
    } else if (recipeState.hasValue && recipeState.value != null) {
      ref.invalidate(recipeHistoryProvider);
      ref.read(ingredientNotifierProvider.notifier).clear();
      context.push('/recipe/${recipeState.value!.id}');
    }
  }

  Future<void> _showSuggestions(String ingredient) async {
    setState(() => _isDetecting = true);
    await ref.read(recipeSuggestionsProvider.notifier).suggest(
          ingredient: ingredient,
          category: widget.category,
        );
    setState(() => _isDetecting = false);

    final suggestState = ref.read(recipeSuggestionsProvider);
    if (suggestState.hasError || !mounted) return;

    final suggestions = suggestState.valueOrNull ?? [];
    if (suggestions.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SuggestionSheet(
        ingredient: ingredient,
        suggestions: suggestions,
        onPick: (title) async {
          Navigator.pop(context);
          await ref.read(recipeNotifierProvider.notifier).generate(
                ingredients: [ingredient],
                category: widget.category,
                preferences: {'hint_title': title},
              );
          if (!mounted) return;
          final recipeState = ref.read(recipeNotifierProvider);
          if (recipeState.hasError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_friendlyError(recipeState.error)), backgroundColor: Colors.red),
            );
          } else if (recipeState.hasValue && recipeState.value != null) {
            ref.invalidate(recipeHistoryProvider);
            ref.read(ingredientNotifierProvider.notifier).clear();
            context.push('/recipe/${recipeState.value!.id}');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = ref.watch(ingredientNotifierProvider);
    final recipeState = ref.watch(recipeNotifierProvider);
    final isLoading = recipeState.isLoading || _isDetecting;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      appBar: AppBar(
        title: Text(widget.category != null ? widget.category! : 'Malzeme Girişi'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera / Gallery buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                    onPressed: isLoading ? null : () => _detect(fromCamera: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                    onPressed: isLoading ? null : () => _detect(fromCamera: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Autocomplete text field
            _IngredientAutocomplete(
              controller: _textCtrl,
              onSelected: _addIngredient,
            ),
            const SizedBox(height: 16),

            // Ingredient chips
            if (ingredients.isNotEmpty) ...[
              Text(
                'Eklenen malzemeler (${ingredients.length})',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: ingredients
                    .map((ing) => IngredientChipWidget(
                          ingredient: ing,
                          onRemove: () =>
                              ref.read(ingredientNotifierProvider.notifier).remove(ing),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.read(ingredientNotifierProvider.notifier).clear(),
                child: const Text('Tümünü Temizle'),
              ),
            ],

            const Spacer(),

            if (ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'En az 1 malzeme ekleyin.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            ElevatedButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(isLoading
                  ? 'Yükleniyor...'
                  : ingredients.length == 1
                      ? 'Tarif Önerileri Göster'
                      : 'Tarif Oluştur'),
              onPressed: (ingredients.isNotEmpty && !isLoading) ? _generateRecipe : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientAutocomplete extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSelected;

  const _IngredientAutocomplete({required this.controller, required this.onSelected});

  @override
  ConsumerState<_IngredientAutocomplete> createState() => _IngredientAutocompleteState();
}

class _IngredientAutocompleteState extends ConsumerState<_IngredientAutocomplete> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(suggestionsProvider(_query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: 'Malzeme adı yazın...',
            prefixIcon: const Icon(Icons.add),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () => widget.onSelected(widget.controller.text),
            ),
          ),
          onChanged: (v) => setState(() => _query = v),
          onSubmitted: widget.onSelected,
          textInputAction: TextInputAction.done,
        ),
        if (_query.length >= 2)
          suggestionsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (suggestions) {
              if (suggestions.isEmpty) return const SizedBox.shrink();
              return Container(
                constraints: const BoxConstraints(maxHeight: 160),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (_, i) => ListTile(
                    dense: true,
                    title: Text(suggestions[i].name),
                    subtitle: Text(suggestions[i].category ?? ''),
                    onTap: () {
                      widget.onSelected(suggestions[i].name);
                      setState(() => _query = '');
                    },
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _SuggestionSheet extends StatelessWidget {
  final String ingredient;
  final List<RecipeSuggestionModel> suggestions;
  final ValueChanged<String> onPick;

  const _SuggestionSheet({
    required this.ingredient,
    required this.suggestions,
    required this.onPick,
  });

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Kolay': return Colors.green;
      case 'Orta':  return Colors.orange;
      default:      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text('"$ingredient" ile yapılabilecek tarifler',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Bir tarif seç, detaylı tarifini oluşturalım.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          ...suggestions.map((s) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onPick(s.title),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(s.description,
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _difficultyColor(s.difficulty).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(s.difficulty,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _difficultyColor(s.difficulty))),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.timer_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text('${s.cookTime} dk',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                            const SizedBox(width: 8),
                            Icon(Icons.restaurant_outlined,
                                size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(s.category,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ]),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
