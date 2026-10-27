import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/models/popular_recipe.dart';
import 'package:smart_recipe_app/providers/recipe_provider.dart';
import 'package:smart_recipe_app/services/api_service.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';
import 'package:smart_recipe_app/widgets/popular_recipe_card.dart';

List<PopularRecipe> _pickRandom(List<PopularRecipe> all, String difficulty) {
  final filtered = all.where((r) => r.difficulty == difficulty).toList();
  filtered.shuffle(Random());
  return filtered.take(3).toList();
}

class CategoryRecipesScreen extends ConsumerStatefulWidget {
  final String category;
  const CategoryRecipesScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryRecipesScreen> createState() => _CategoryRecipesScreenState();
}

class _CategoryRecipesScreenState extends ConsumerState<CategoryRecipesScreen> {
  late List<PopularRecipe> _easy;
  late List<PopularRecipe> _medium;
  late List<PopularRecipe> _hard;

  static const _categoryImages = {
    'Ana Yemek': 'assets/images/anayemek.jpg',
    'Kahvaltı':  'assets/images/kahvalti.jpg',
    'Tatlı':     'assets/images/tatli.jpg',
    'Aperatif':  'assets/images/aperatif.jpg',
    'İçecek':    'assets/images/icecek.jpg',
    'Diyet':     'assets/images/diyet.jpg',
  };

  String get _categoryImage =>
      _categoryImages[widget.category] ?? 'assets/images/anayemek.jpg';

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final all = categoryRecipes[widget.category] ?? [];
    setState(() {
      _easy   = _pickRandom(all, 'Kolay');
      _medium = _pickRandom(all, 'Orta');
      _hard   = _pickRandom(all, 'Zor');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            leading: BackButton(
              color: Colors.white,
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.category,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _categoryImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade400),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Popüler Tarifler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  TextButton.icon(
                    onPressed: _shuffle,
                    style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                    icon: const Icon(Icons.shuffle_rounded, size: 16),
                    label: const Text('Yenile'),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                DifficultySection(
                  title: 'Kolay',
                  emoji: '🟢',
                  color: Colors.green,
                  recipes: _easy,
                  onTap: _generateRecipe,
                ),
                const SizedBox(height: 8),
                DifficultySection(
                  title: 'Orta',
                  emoji: '🟡',
                  color: Colors.orange,
                  recipes: _medium,
                  onTap: _generateRecipe,
                ),
                const SizedBox(height: 8),
                DifficultySection(
                  title: 'Zor',
                  emoji: '🔴',
                  color: Colors.red,
                  recipes: _hard,
                  onTap: _generateRecipe,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Kendi Malzemelerimi Gir'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.black45, width: 1.5),
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push('/ingredients', extra: {'category': widget.category}),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateRecipe(PopularRecipe recipe) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '"${recipe.title}" yükleniyor...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    void closeDialog() {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
      }
    }

    try {
      // 1. Önce cache'e bak
      try {
        final cached = await ApiService().getPopularRecipe(recipe.title);
        if (cached != null) {
          closeDialog();
          if (mounted) context.push('/recipe/${cached.id}');
          return;
        }
      } catch (_) {
        // cache hatası → devam et, AI'ya sor
      }

      // 2. Cache'de yoksa AI ile üret (dialog hâlâ açık)
      await ref.read(recipeNotifierProvider.notifier).generate(
        ingredients: [recipe.title],
        category: widget.category,
        preferences: {'hint_title': recipe.title},
      );

      closeDialog();

      final recipeState = ref.read(recipeNotifierProvider);
      if (!mounted) return;

      if (recipeState.hasError) {
        final err = recipeState.error;
        String msg = 'Tarif oluşturulamadı. Lütfen tekrar deneyin.';
        if (err is DioException) {
          final statusCode = err.response?.statusCode;
          if (statusCode == 429) {
            msg = 'Şu an çok yoğun, birkaç saniye bekleyip tekrar deneyin.';
          } else {
            final detail = err.response?.data?['detail'];
            if (detail != null) msg = detail.toString();
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
        );
      } else if (recipeState.hasValue && recipeState.value != null) {
        context.push('/recipe/${recipeState.value!.id}');
      }
    } catch (e) {
      closeDialog();
      if (!mounted) return;
      String msg = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      if (e is DioException && e.response?.statusCode == 429) {
        msg = 'Şu an çok yoğun, birkaç saniye bekleyip tekrar deneyin.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red, duration: const Duration(seconds: 4)),
      );
    }
  }
}
