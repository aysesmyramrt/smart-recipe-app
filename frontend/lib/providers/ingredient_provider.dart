import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_recipe_app/models/ingredient_model.dart';
import 'package:smart_recipe_app/services/api_service.dart';
import 'package:smart_recipe_app/services/camera_service.dart';
import 'package:smart_recipe_app/utils/constants.dart';

// Selected ingredients list
class IngredientNotifier extends Notifier<List<IngredientModel>> {
  @override
  List<IngredientModel> build() => [];

  void add(IngredientModel ingredient) {
    if (!state.contains(ingredient)) {
      state = [...state, ingredient];
    }
  }

  void addAll(List<String> names) {
    final newItems = names
        .map((n) => IngredientModel(name: n))
        .where((i) => !state.contains(i))
        .toList();
    state = [...state, ...newItems];
  }

  void remove(IngredientModel ingredient) {
    state = state.where((i) => i != ingredient).toList();
  }

  void clear() => state = [];

  bool get canGenerate => state.length >= AppConstants.minIngredients;
}

final ingredientNotifierProvider =
    NotifierProvider<IngredientNotifier, List<IngredientModel>>(IngredientNotifier.new);

// Detection state
class DetectionNotifier extends AsyncNotifier<DetectionResult?> {
  @override
  Future<DetectionResult?> build() async => null;

  Future<void> detectFromXFile(XFile xFile) async {
    state = const AsyncLoading();
    final bytes = await xFile.readAsBytes();
    final filename = xFile.name.isNotEmpty ? xFile.name : 'ingredient.jpg';
    state = await AsyncValue.guard(
      () => ApiService().detectIngredients(bytes, filename: filename),
    );
  }

  Future<void> pickAndDetect({bool fromCamera = true}) async {
    final cameraService = CameraService();
    final xFile = fromCamera
        ? await cameraService.pickFromCamera()
        : await cameraService.pickFromGallery();
    if (xFile == null) return;
    await detectFromXFile(xFile);
  }
}

final detectionNotifierProvider =
    AsyncNotifierProvider<DetectionNotifier, DetectionResult?>(DetectionNotifier.new);

// Suggestions (autocomplete)
final suggestionsProvider = FutureProvider.family<List<IngredientModel>, String>((ref, query) async {
  if (query.length < 2) return [];
  return ApiService().getSuggestions(query);
});
