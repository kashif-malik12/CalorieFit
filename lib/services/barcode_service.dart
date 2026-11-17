import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/models.dart';

class OpenFoodProduct {
  final String barcode;
  final String name;
  final String brand;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final String servingSize;
  final String? imageUrl;

  const OpenFoodProduct({
    required this.barcode,
    required this.name,
    this.brand = '',
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.servingSize = '100g',
    this.imageUrl,
  });

  Food toFood() {
    final title = brand.isNotEmpty ? '$name ($brand)' : name;
    return Food(
      name: title,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
      unit: 'g',
      baseAmount: 100,
      isSystem: false,
    );
  }
}

class BarcodeService {
  BarcodeService._();

  static Future<OpenFoodProduct?> fetchProduct(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return null;

    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v2/product/$cleanBarcode.json',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CalorieFit - Flutter App - Version 1.1'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as int? ?? 0;
      if (status != 1) return null;

      final product = data['product'] as Map<String, dynamic>? ?? {};
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      final name = (product['product_name'] as String?)?.trim() ??
          (product['generic_name'] as String?)?.trim() ??
          'Unknown Product';
      final brand = (product['brands'] as String?)?.trim() ?? '';
      final servingSize = (product['serving_size'] as String?)?.trim() ?? '100g';
      final imageUrl = product['image_front_small_url'] as String?;

      double numVal(dynamic v) {
        if (v is num) return v.toDouble();
        if (v is String) return double.tryParse(v) ?? 0.0;
        return 0.0;
      }

      final calories = numVal(nutriments['energy-kcal_100g'] ??
          nutriments['energy-kcal'] ??
          nutriments['energy-kcal_serving']);
      final protein = numVal(nutriments['proteins_100g'] ?? nutriments['proteins']);
      final carbs = numVal(nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates']);
      final fat = numVal(nutriments['fat_100g'] ?? nutriments['fat']);
      final fiber = numVal(nutriments['fiber_100g'] ?? nutriments['fiber']);
      final sugar = numVal(nutriments['sugars_100g'] ?? nutriments['sugars']);
      double sodium = numVal(nutriments['sodium_100g'] ?? nutriments['sodium']);
      if (sodium == 0 && nutriments['salt_100g'] != null) {
        sodium = numVal(nutriments['salt_100g']) * 400; // 1g salt ≈ 400mg sodium
      }

      return OpenFoodProduct(
        barcode: cleanBarcode,
        name: name,
        brand: brand,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
        servingSize: servingSize,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
