import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models.dart';

class OpenFoodFactsService {
  final http.Client? client;

  OpenFoodFactsService({this.client});

  http.Client get _client => client ?? http.Client();

  /// Fetches product information by barcode from Open Food Facts API v2.
  Future<Food?> fetchProductByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final url = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json');
    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'CalorieFitApp/1.6.0 (Android; contact: ali.kashifmalik@gmail.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1 || data['product'] == null) {
        return null;
      }

      final product = data['product'] as Map<String, dynamic>;
      return parseProductToFood(product);
    } catch (_) {
      return null;
    }
  }

  /// Searches for products by keyword from Open Food Facts.
  Future<List<Food>> searchFoods(String query, {int limit = 10}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final encoded = Uri.encodeComponent(trimmed);
    final url = Uri.parse(
        'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$encoded&search_simple=1&action=process&json=1&page_size=$limit');

    try {
      final response = await _client.get(
        url,
        headers: {'User-Agent': 'CalorieFitApp/1.6.0 (Android; contact: ali.kashifmalik@gmail.com)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final products = data['products'] as List<dynamic>?;
      if (products == null || products.isEmpty) return [];

      final results = <Food>[];
      for (final p in products) {
        if (p is Map<String, dynamic>) {
          final food = parseProductToFood(p);
          if (food != null && food.name.isNotEmpty) {
            results.add(food);
          }
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// Converts an OpenFoodFacts product JSON dictionary to a CalorieFit Food model.
  Food? parseProductToFood(Map<String, dynamic> product) {
    final name = (product['product_name'] ??
            product['product_name_en'] ??
            product['generic_name'] ??
            'Unknown Food')
        .toString()
        .trim();
    if (name.isEmpty) return null;

    final brand = (product['brands'] ?? '').toString().trim();
    final displayName = brand.isNotEmpty ? '$name ($brand)' : name;

    final nutriments = (product['nutriments'] as Map<String, dynamic>?) ?? {};

    double extractNum(List<String> keys) {
      for (final k in keys) {
        final val = nutriments[k];
        if (val is num) return val.toDouble();
        if (val is String) {
          final parsed = double.tryParse(val);
          if (parsed != null) return parsed;
        }
      }
      return 0.0;
    }

    final calories = extractNum(['energy-kcal_100g', 'energy-kcal', 'energy-kcal_value', 'energy-kcal_serving']);
    final protein = extractNum(['proteins_100g', 'proteins', 'proteins_value']);
    final carbs = extractNum(['carbohydrates_100g', 'carbohydrates', 'carbohydrates_value']);
    final fat = extractNum(['fat_100g', 'fat', 'fat_value']);
    final fiber = extractNum(['fiber_100g', 'fiber', 'fiber_value']);
    final sugar = extractNum(['sugars_100g', 'sugars', 'sugars_value']);
    final satFat = extractNum(['saturated-fat_100g', 'saturated-fat', 'saturated-fat_value']);

    // Sodium in mg. OpenFoodFacts sodium is usually in grams per 100g, or salt is in grams.
    double sodiumMg = extractNum(['sodium_100g', 'sodium']) * 1000;
    if (sodiumMg <= 0) {
      final saltG = extractNum(['salt_100g', 'salt']);
      if (saltG > 0) {
        sodiumMg = saltG * 400; // Salt is ~40% sodium
      }
    }

    final category = (product['categories'] ?? 'Packaged Foods').toString().split(',').first.trim();

    return Food(
      name: displayName,
      calories: calories > 0 ? calories : 0,
      protein: protein > 0 ? protein : 0,
      carbs: carbs > 0 ? carbs : 0,
      fat: fat > 0 ? fat : 0,
      fiber: fiber > 0 ? fiber : 0,
      sugar: sugar > 0 ? sugar : 0,
      sodium: sodiumMg > 0 ? sodiumMg : 0,
      saturatedFat: satFat > 0 ? satFat : 0,
      unit: 'g',
      baseAmount: 100,
      category: category.isNotEmpty ? category : 'Packaged Foods',
      isSystem: false,
    );
  }
}
