import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_recipe_app/providers/auth_provider.dart';
import 'package:smart_recipe_app/models/user_model.dart';
import 'package:smart_recipe_app/services/api_service.dart';
import 'package:smart_recipe_app/utils/constants.dart';
import 'package:smart_recipe_app/widgets/app_bottom_nav.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Set<String> _dietary;
  late Set<String> _allergies;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider).valueOrNull;
    _dietary = Set.from(user?.preferences.dietary ?? []);
    _allergies = Set.from(user?.preferences.allergies ?? []);
  }

  Future<void> _savePreferences() async {
    setState(() => _saving = true);
    try {
      final prefs = DietaryPreferences(
        dietary: _dietary.toList(),
        allergies: _allergies.toList(),
      );
      await ApiService().updatePreferences(prefs);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tercihler kaydedildi.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.valueOrNull;

    return Scaffold(
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
      appBar: AppBar(
        title: const Text('Profil'),
        leading: BackButton(onPressed: () => context.go('/home')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + info
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    (user?.displayName.isNotEmpty == true ? user!.displayName[0] : '?').toUpperCase(),
                    style: TextStyle(fontSize: 32, color: Colors.green.shade800),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.displayName ?? '', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _SectionHeader('Diyet Tercihleri'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.dietaryOptions.map((opt) {
              final selected = _dietary.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: selected,
                onSelected: (val) => setState(() => val ? _dietary.add(opt) : _dietary.remove(opt)),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _SectionHeader('Alerjiler'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: AppConstants.allergyOptions.map((opt) {
              final selected = _allergies.contains(opt);
              return FilterChip(
                label: Text(opt),
                selected: selected,
                selectedColor: Colors.red.shade100,
                checkmarkColor: Colors.red,
                onSelected: (val) =>
                    setState(() => val ? _allergies.add(opt) : _allergies.remove(opt)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _saving ? null : _savePreferences,
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Tercihleri Kaydet'),
          ),
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Tarih Geçmişim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/history'),
          ),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Favorilerim'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/favorites'),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.green.shade800)),
      );
}
