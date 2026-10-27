import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_recipe_app/utils/constants.dart';
import 'package:smart_recipe_app/utils/auth_notifier.dart';
import 'package:smart_recipe_app/utils/theme.dart';
import 'package:smart_recipe_app/screens/login_screen.dart';
import 'package:smart_recipe_app/screens/home_screen.dart';
import 'package:smart_recipe_app/screens/ingredient_entry_screen.dart';
import 'package:smart_recipe_app/screens/recipe_view_screen.dart';
import 'package:smart_recipe_app/screens/recipe_list_screen.dart';
import 'package:smart_recipe_app/screens/profile_screen.dart';
import 'package:smart_recipe_app/screens/category_recipes_screen.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (_) {}
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SmartRecipeApp()));
}

final _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: authRefreshNotifier,
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.getString(AppConstants.tokenKey) != null;
    final onLogin = state.matchedLocation == '/login';
    if (!hasToken && !onLogin) return '/login';
    if (hasToken && onLogin) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/ingredients',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return IngredientEntryScreen(
          category: extra?['category'] as String?,
          autoDetect: extra?['autoDetect'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/recipe/:id',
      builder: (_, state) => RecipeViewScreen(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/history', builder: (_, __) => const RecipeListScreen(showFavorites: false)),
    GoRoute(path: '/favorites', builder: (_, __) => const RecipeListScreen(showFavorites: true)),
    GoRoute(
      path: '/category',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CategoryRecipesScreen(category: extra?['category'] as String? ?? '');
      },
    ),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
  ],
);

class _NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class SmartRecipeApp extends StatelessWidget {
  const SmartRecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Akıllı Tarif',
      theme: AppTheme.light,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: _NoStretchScrollBehavior(),
    );
  }
}
