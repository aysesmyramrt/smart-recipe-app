import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/providers/recipe_provider.dart';
import 'package:smart_recipe_app/widgets/recipe_card.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';

class RecipeListScreen extends ConsumerWidget {
  final bool showFavorites;
  const RecipeListScreen({super.key, this.showFavorites = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(recipeHistoryProvider);
    final favoriteIds = ref.watch(favoritesNotifierProvider).valueOrNull ?? [];
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);

    return Scaffold(
      bottomNavigationBar: AppBottomNav(currentIndex: showFavorites ? 3 : 2),
      appBar: AppBar(
        title: Text(showFavorites ? 'Favorilerim' : 'Geçmişim'),
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
        actions: [
          if (!showFavorites)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tümünü Sil',
              onPressed: () => _confirmClearAll(context, ref),
            ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (recipes) {
          final filtered = showFavorites
              ? recipes.where((r) => favoriteIds.contains(r.id)).toList()
              : recipes;

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(showFavorites ? Icons.favorite_border : Icons.history,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    showFavorites ? 'Favori tarifiniz yok.' : 'Henüz tarif oluşturmadınız.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) {
              final recipe = filtered[i];
              final card = Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecipeCard(
                  recipe: recipe,
                  onTap: () => context.push('/recipe/${recipe.id}'),
                  onFavorite: () => favoritesNotifier.toggle(recipe.id),
                  isFavorite: favoriteIds.contains(recipe.id),
                ),
              );

              if (showFavorites) return card;

              return Dismissible(
                key: Key(recipe.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  color: Colors.red.shade400,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) =>
                    ref.read(recipeHistoryProvider.notifier).deleteItem(recipe.id),
                child: card,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Geçmişi Temizle'),
        content: const Text('Tüm tarif geçmişi silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(recipeHistoryProvider.notifier).clearAll();
  }
}
