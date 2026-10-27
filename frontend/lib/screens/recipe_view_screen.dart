import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/models/recipe_model.dart';
import 'package:smart_recipe_app/providers/recipe_provider.dart';
import 'package:smart_recipe_app/services/api_service.dart';
import 'package:smart_recipe_app/utils/recipe_images.dart';
import 'package:smart_recipe_app/widgets/nutrition_panel.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';

class RecipeViewScreen extends ConsumerWidget {
  final String recipeId;
  const RecipeViewScreen({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeByIdProvider(recipeId));
    final favoritesNotifier = ref.read(favoritesNotifierProvider.notifier);
    final favoriteIds = ref.watch(favoritesNotifierProvider).valueOrNull ?? [];

    return recipeAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Tarif yüklenemedi: $e')),
      ),
      data: (recipe) => _buildBody(context, ref, recipe, favoritesNotifier, favoriteIds),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    RecipeModel recipe,
    FavoritesNotifier favoritesNotifier,
    List<String> favoriteIds,
  ) {
    final isFav = favoriteIds.contains(recipe.id);

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: -1),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            leading: BackButton(color: Colors.white, onPressed: () => context.canPop() ? context.pop() : context.go('/home')),
            actions: [
              IconButton(
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.white),
                onPressed: () => favoritesNotifier.toggle(recipe.id),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => _share(context, recipe),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
                maxLines: 2,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    recipeImagePath(recipe.title, category: recipe.category),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.green.shade50,
                      child: const Icon(Icons.restaurant, size: 80, color: Colors.green),
                    ),
                  ),
                  // Gradient — başlık okunabilsin diye
                  const DecoratedBox(
                    decoration: BoxDecoration(
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (recipe.prepTime > 0)
                        _MetaChip(icon: Icons.cut_outlined, label: 'Hazırlık: ${recipe.prepTime} dk'),
                      _MetaChip(icon: Icons.local_fire_department_outlined, label: 'Pişirme: ${recipe.cookTime} dk'),
                      _MetaChip(icon: Icons.people_outline, label: '${recipe.servings} kişilik'),
                      _MetaChip(icon: Icons.bar_chart, label: recipe.difficulty),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Nutrition panel
                  NutritionPanel(nutrition: recipe.nutrition),
                  const SizedBox(height: 24),

                  // Ingredients grouped
                  const _SectionTitle('Malzemeler'),
                  const SizedBox(height: 12),
                  _buildIngredientGroups(recipe.ingredients),
                  const SizedBox(height: 24),

                  // Steps
                  const _SectionTitle('Hazırlanışı'),
                  const SizedBox(height: 10),
                  ...List.generate(
                    recipe.steps.length,
                    (i) => _StepItem(index: i + 1, text: recipe.steps[i]),
                  ),
                  const SizedBox(height: 32),

                  // Comments & Ratings
                  const Divider(),
                  const SizedBox(height: 8),
                  _CommentSection(recipeId: recipe.id),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // "(marine için)" gibi suffix'i isimden ayıklar, grup adını döner
  (String cleanName, String group) _parseIngredient(RecipeIngredient ing) {
    // Önce group field'ı kontrol et (yeni AI yanıtları)
    if (ing.group != 'Malzemeler') {
      return (ing.name, ing.group);
    }
    // Eski yanıtlarda ismin sonundaki "(X için)" kalıbını çek
    final match = RegExp(r'^(.*?)\s*\(([^)]+için)\)\s*$').firstMatch(ing.name);
    if (match != null) {
      final cleanedName = match.group(1)!.trim();
      final groupName = match.group(2)!.trim();
      // İlk harfi büyüt
      final titled = groupName[0].toUpperCase() + groupName.substring(1);
      return (cleanedName, titled);
    }
    return (ing.name, 'Malzemeler');
  }

  Widget _buildIngredientGroups(List<RecipeIngredient> ingredients) {
    // Sırayı koruyarak grupla
    final Map<String, List<(String, RecipeIngredient)>> grouped = {};
    for (final ing in ingredients) {
      final (cleanName, group) = _parseIngredient(ing);
      grouped.putIfAbsent(group, () => []).add((cleanName, ing));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final groupName = entry.key;
        final items = entry.value;
        final showHeader = grouped.length > 1 || groupName != 'Malzemeler';

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader) ...[
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade800,
                  ),
                ),
                const Divider(height: 12),
              ],
              ...List.generate(items.length, (i) {
                final (cleanName, ing) = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${ing.amount} ${ing.unit} $cleanName'.trim(),
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _share(BuildContext context, RecipeModel recipe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recipe.title} tarifi kopyalandı!')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade800),
      );
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
          ],
        ),
      );
}


class _StepItem extends StatelessWidget {
  final int index;
  final String text;
  const _StepItem({required this.index, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text('$index',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
          ],
        ),
      );
}

// ── Comment Section ───────────────────────────────────────────────────────────

class _CommentSection extends StatefulWidget {
  final String recipeId;
  const _CommentSection({required this.recipeId});

  @override
  State<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<_CommentSection> {
  final _api = ApiService();
  final _controller = TextEditingController();
  List<RecipeComment> _comments = [];
  bool _loading = true;
  bool _sending = false;
  int _selectedRating = 0;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final list = await _api.getComments(widget.recipeId);
      if (mounted) setState(() { _comments = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen puan ve yorum girin.')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final comment = await _api.addComment(widget.recipeId, text, _selectedRating);
      _controller.clear();
      setState(() {
        _comments.insert(0, comment);
        _selectedRating = 0;
        _sending = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum gönderilemedi: $e'), backgroundColor: Colors.red),
        );
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _delete(RecipeComment c) async {
    try {
      await _api.deleteComment(widget.recipeId, c.id);
      setState(() => _comments.remove(c));
    } catch (_) {}
  }

  double get _avgRating {
    if (_comments.isEmpty) return 0;
    return _comments.fold(0.0, (s, c) => s + c.rating) / _comments.length;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Yorumlar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: Colors.green.shade800)),
            const Spacer(),
            if (_comments.isNotEmpty) ...[
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 3),
              Text(_avgRating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(' (${_comments.length})',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedRating = star),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        star <= _selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tarifinizi nasıl buldunuz?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: _sending ? null : _submit,
                  icon: _sending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Henüz yorum yok. İlk yorumu sen yaz!',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
          )
        else
          ..._comments.map((c) => _CommentCard(comment: c, onDelete: () => _delete(c))),
      ],
    );
  }
}

class _CommentCard extends StatelessWidget {
  final RecipeComment comment;
  final VoidCallback onDelete;
  const _CommentCard({required this.comment, required this.onDelete});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    comment.displayName.isNotEmpty ? comment.displayName[0].toUpperCase() : '?',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green.shade800, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(comment.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < comment.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber, size: 14,
                  )),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(comment.text, style: const TextStyle(fontSize: 13, height: 1.4)),
            if (comment.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDate(comment.createdAt!),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      );

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dakika önce';
    if (diff.inHours < 24) return '${diff.inHours} saat önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}
