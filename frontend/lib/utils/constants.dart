import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static String get apiBaseUrl {
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    return 'https://smyramrt-smart-recipe-backend.hf.space';
  }

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 120000; // Gemini 2.5 can take up to 60s

  static const int maxHistoryItems = 50;
  static const int minIngredients = 2;
  static const int maxImageSizeMb = 10;

  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  static const List<String> dietaryOptions = [
    'Vejetaryen',
    'Vegan',
    'Glutensiz',
    'Helal',
    'Laktozsuz',
    'Düşük Karbonhidrat',
  ];

  static const List<String> allergyOptions = [
    'Fıstık',
    'Ağaç Fındığı',
    'Süt / Laktoz',
    'Yumurta',
    'Buğday / Gluten',
    'Soya',
    'Balık',
    'Kabuklu Deniz Ürünleri',
    'Susam',
  ];

  static const List<String> categories = [
    'Ana Yemek',
    'Kahvaltı',
    'Tatlı',
    'Çorba',
    'Salata',
    'Atıştırmalık',
  ];
}
