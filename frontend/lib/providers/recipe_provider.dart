import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_recipe_app/models/recipe_model.dart';
import 'package:smart_recipe_app/services/api_service.dart';

class RecipeSuggestionsNotifier extends AsyncNotifier<List<RecipeSuggestionModel>> {
  @override
  Future<List<RecipeSuggestionModel>> build() async => [];

  Future<void> suggest({required String ingredient, String? category}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ApiService().suggestRecipes(ingredient: ingredient, category: category),
    );
  }

  void clear() => state = const AsyncData([]);
}

final recipeSuggestionsProvider =
    AsyncNotifierProvider<RecipeSuggestionsNotifier, List<RecipeSuggestionModel>>(
        RecipeSuggestionsNotifier.new);

// Current generated recipe
class RecipeNotifier extends AsyncNotifier<RecipeModel?> {
  @override
  Future<RecipeModel?> build() async => null;

  Future<void> generate({
    required List<String> ingredients,
    Map<String, dynamic>? preferences,
    String? category,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ApiService().generateRecipe(
        ingredients: ingredients,
        preferences: preferences,
        category: category,
      ),
    );
  }
}

final recipeNotifierProvider =
    AsyncNotifierProvider<RecipeNotifier, RecipeModel?>(RecipeNotifier.new);

// History
class RecipeHistoryNotifier extends AsyncNotifier<List<RecipeModel>> {
  @override
  Future<List<RecipeModel>> build() => ApiService().getHistory();

  Future<void> deleteItem(String recipeId) async {
    await ApiService().deleteHistoryItem(recipeId);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((r) => r.id != recipeId).toList());
  }

  Future<void> clearAll() async {
    await ApiService().clearHistory();
    state = const AsyncData([]);
  }
}

final recipeHistoryProvider =
    AsyncNotifierProvider<RecipeHistoryNotifier, List<RecipeModel>>(RecipeHistoryNotifier.new);

// Recipe by ID
final recipeByIdProvider = FutureProvider.family<RecipeModel, String>((ref, id) async {
  return ApiService().getRecipeById(id);
});

// Favorites
class FavoritesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() => ApiService().getFavoriteIds();

  Future<void> toggle(String recipeId) async {
    final current = state.valueOrNull ?? [];
    if (current.contains(recipeId)) {
      await ApiService().removeFavorite(recipeId);
      state = AsyncData(current.where((id) => id != recipeId).toList());
    } else {
      await ApiService().addFavorite(recipeId);
      state = AsyncData([...current, recipeId]);
    }
  }

  bool isFavorite(String recipeId) => (state.valueOrNull ?? []).contains(recipeId);
}

final favoritesNotifierProvider =
    AsyncNotifierProvider<FavoritesNotifier, List<String>>(FavoritesNotifier.new);
