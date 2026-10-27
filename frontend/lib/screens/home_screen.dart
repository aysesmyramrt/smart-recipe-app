import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/providers/auth_provider.dart';
import 'package:smart_recipe_app/providers/recipe_provider.dart';
import 'package:smart_recipe_app/widgets/recipe_card.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';

class _Category {
  final String label;
  final String value;
  final String imageUrl;
  const _Category({required this.label, required this.value, required this.imageUrl});
}

const _categories = [
  _Category(
    label: 'Ana Yemekler',
    value: 'Ana Yemek',
    imageUrl: 'asset:assets/images/anayemek.jpg',
  ),
  _Category(
    label: 'Kahvaltı',
    value: 'Kahvaltı',
    imageUrl: 'asset:assets/images/kahvalti.jpg',
  ),
  _Category(
    label: 'Tatlılar',
    value: 'Tatlı',
    imageUrl: 'asset:assets/images/tatli.jpg',
  ),
  _Category(
    label: 'Aperatifler',
    value: 'Aperatif',
    imageUrl: 'asset:assets/images/aperatif.jpg',
  ),
  _Category(
    label: 'İçecekler',
    value: 'İçecek',
    imageUrl: 'asset:assets/images/icecek.jpg',
  ),
  _Category(
    label: 'Diyet Yemekleri',
    value: 'Diyet',
    imageUrl: 'asset:assets/images/diyet.jpg',
  ),
];

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final historyAsync = ref.watch(recipeHistoryProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          slivers: [
            SliverAppBar(
              floating: true,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Merhaba, ${user?.displayName.split(' ').first ?? ''}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const Text('Ne pişirelim?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () => context.push('/profile'),
                ),
              ],
            ),

            // Quick scan banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: _ScanBanner(
                  onCamera: () => context.push('/ingredients', extra: {'autoDetect': 'camera'}),
                  onGallery: () => context.push('/ingredients', extra: {'autoDetect': 'gallery'}),
                  onTap: () => context.push('/ingredients'),
                ),
              ),
            ),

            // Category header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Kategori Seç',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),

            // Category cards grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final cat = _categories[i];
                    return _CategoryCard(
                      category: cat,
                      onTap: () => context.push('/category', extra: {'category': cat.value}),
                    );
                  },
                  childCount: _categories.length,
                ),
              ),
            ),

            // Recent recipes
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Son Tarifler',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),

            historyAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Yüklenemedi: $e')),
              ),
              data: (recipes) {
                if (recipes.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Henüz tarif oluşturmadınız.',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: RecipeCard(
                        recipe: recipes[i],
                        onTap: () => context.push('/recipe/${recipes[i].id}'),
                      ),
                    ),
                    childCount: recipes.length,
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

class _ScanBanner extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onTap;
  const _ScanBanner({required this.onCamera, required this.onGallery, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.green.shade700, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Malzemelerini tarat,',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'yemeğini hazırla!',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ScanButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Kamera',
                        onTap: onCamera,
                      ),
                      const SizedBox(width: 10),
                      _ScanButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Galeri',
                        onTap: onGallery,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.document_scanner_outlined, color: Colors.white54, size: 64),
          ],
        ),
      ),
    );
  }
}

class _ScanButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ScanButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white38),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.grey.shade200,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              category.imageUrl.startsWith('asset:')
                  ? Image.asset(
                      category.imageUrl.substring(6),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant, size: 48, color: Colors.white),
                      ),
                    )
                  : Image.network(
                      category.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.restaurant, size: 48, color: Colors.white),
                      ),
                    ),
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.65),
                    ],
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
              // Label at the bottom
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  category.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

