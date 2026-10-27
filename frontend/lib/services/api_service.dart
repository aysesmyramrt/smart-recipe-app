import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_recipe_app/utils/constants.dart';
import 'package:smart_recipe_app/utils/auth_notifier.dart';
import 'package:smart_recipe_app/models/recipe_model.dart';
import 'package:smart_recipe_app/models/ingredient_model.dart';
import 'package:smart_recipe_app/models/user_model.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
    ));
    _dio.interceptors.add(_AuthInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }

  // ── Auth ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _authPost(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}$path');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    ).timeout(const Duration(milliseconds: AppConstants.connectTimeoutMs));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        data['detail']?.toString() ?? 'İşlem başarısız',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String displayName,
  }) => _authPost('/auth/register', {
        'email': email,
        'password': password,
        'display_name': displayName,
      });

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => _authPost('/auth/login', {'email': email, 'password': password});

  Future<UserModel> getProfile() async {
    final resp = await _dio.get('/auth/profile');
    final data = resp.data is String
        ? jsonDecode(resp.data as String) as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }

  // ── Ingredients ───────────────────────────────────────────────────────────

  Future<DetectionResult> detectIngredients(List<int> bytes, {String filename = 'ingredient.jpg'}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final resp = await _dio.post('/ingredients/detect', data: form);
    return DetectionResult.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<IngredientModel>> getSuggestions(String query) async {
    final resp = await _dio.get('/ingredients/suggestions', queryParameters: {'q': query});
    return (resp.data as List).map((e) => IngredientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Recipes ───────────────────────────────────────────────────────────────

  Future<List<RecipeSuggestionModel>> suggestRecipes({
    required String ingredient,
    String? category,
  }) async {
    final resp = await _dio.post('/recipes/multi-suggest', data: {
      'ingredient': ingredient,
      if (category != null) 'category': category,
    });
    return (resp.data as List)
        .map((e) => RecipeSuggestionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeModel> generateRecipe({
    required List<String> ingredients,
    Map<String, dynamic>? preferences,
    String? category,
  }) async {
    final body = {
      'ingredients': ingredients,
      'preferences': preferences ?? {},
      if (category != null) 'category': category,
    };
    final resp = await _dio.post('/recipes/generate', data: body);
    final data = resp.data is String
        ? jsonDecode(resp.data as String) as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return RecipeModel.fromJson(data);
  }

  Future<List<RecipeModel>> getHistory() async {
    final resp = await _dio.get('/recipes/history');
    return (resp.data as List)
        .map((e) => RecipeModel.fromJson((e as Map<String, dynamic>)['recipe'] as Map<String, dynamic>))
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  Future<RecipeModel> getRecipeById(String id) async {
    final resp = await _dio.get('/recipes/$id');
    final data = resp.data is String
        ? jsonDecode(resp.data as String) as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return RecipeModel.fromJson(data);
  }

  /// Popüler tarif cache'inden getirir. Yoksa null döner.
  Future<RecipeModel?> getPopularRecipe(String title) async {
    try {
      final resp = await _dio.get('/recipes/popular/${Uri.encodeComponent(title)}');
      final data = resp.data is String
          ? jsonDecode(resp.data as String) as Map<String, dynamic>
          : resp.data as Map<String, dynamic>;
      return RecipeModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> deleteHistoryItem(String recipeId) async =>
      _dio.delete('/recipes/history/$recipeId');

  Future<void> clearHistory() async =>
      _dio.delete('/recipes/history');

  Future<void> addFavorite(String recipeId) async =>
      _dio.post('/recipes/favorites/$recipeId');

  Future<void> removeFavorite(String recipeId) async =>
      _dio.delete('/recipes/favorites/$recipeId');

  Future<List<String>> getFavoriteIds() async {
    final resp = await _dio.get('/recipes/favorites');
    return (resp.data as List).map((e) => e['recipe_id'] as String).toList();
  }

  // ── Comments ──────────────────────────────────────────────────────────────

  Future<List<RecipeComment>> getComments(String recipeId) async {
    final resp = await _dio.get('/recipes/$recipeId/comments');
    return (resp.data as List)
        .map((e) => RecipeComment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RecipeComment> addComment(String recipeId, String text, int rating) async {
    final resp = await _dio.post('/recipes/$recipeId/comments',
        data: {'text': text, 'rating': rating});
    final data = resp.data is String
        ? jsonDecode(resp.data as String) as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return RecipeComment.fromJson(data);
  }

  Future<void> deleteComment(String recipeId, String commentId) async =>
      _dio.delete('/recipes/$recipeId/comments/$commentId');

  // ── Users ─────────────────────────────────────────────────────────────────

  Future<DietaryPreferences> updatePreferences(DietaryPreferences prefs) async {
    final resp = await _dio.put('/users/preferences', data: prefs.toJson());
    return DietaryPreferences.fromJson(resp.data as Map<String, dynamic>);
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;
    final rawData = err.response?.data;
    final detail = (rawData is Map ? rawData['detail'] : null)
        ?? err.message
        ?? 'Bilinmeyen hata';

    // 401 → token geçersiz/süresi dolmuş, login'e yönlendir
    if (statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove('user');
      authRefreshNotifier.value++;
    }

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(detail.toString(), statusCode: statusCode),
        response: err.response,
        type: err.type,
      ),
    );
  }
}
