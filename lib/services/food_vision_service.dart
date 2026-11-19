import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Structured result from food vision analysis
class FoodVisionResult {
  final bool isFood;
  final String? detectedFoodName;
  final String? nonFoodCategory;
  final double confidence;
  final List<String> allLabels;
  final String message;
  final String? suggestedQuery;

  const FoodVisionResult({
    required this.isFood,
    this.detectedFoodName,
    this.nonFoodCategory,
    required this.confidence,
    required this.allLabels,
    required this.message,
    this.suggestedQuery,
  });

  /// Factory for when no food is detected (e.g. carpet, floor, electronics, person)
  factory FoodVisionResult.nonFood({
    required String detectedEntity,
    required double confidence,
    required List<String> labels,
  }) {
    return FoodVisionResult(
      isFood: false,
      nonFoodCategory: detectedEntity,
      confidence: confidence,
      allLabels: labels,
      message: 'No food detected in photo. Detected: $detectedEntity. Please point the camera at a meal, snack, or beverage.',
    );
  }

  /// Factory for when food is recognized
  factory FoodVisionResult.food({
    required String foodName,
    required double confidence,
    required List<String> labels,
    String? query,
  }) {
    return FoodVisionResult(
      isFood: true,
      detectedFoodName: foodName,
      confidence: confidence,
      allLabels: labels,
      message: 'Food recognized: $foodName',
      suggestedQuery: query ?? foodName,
    );
  }

  /// Factory for ambiguous or unidentifiable photo
  factory FoodVisionResult.unclear({List<String> labels = const []}) {
    return FoodVisionResult(
      isFood: false,
      nonFoodCategory: 'Unknown Object',
      confidence: 0.0,
      allLabels: labels,
      message: 'Could not clearly recognize food in this image. Please retake the photo with better lighting or enter the meal name manually.',
    );
  }
}

class FoodVisionService {
  FoodVisionService._();
  static final FoodVisionService instance = FoodVisionService._();

  // Non-food entity keywords detected by vision labelers
  static const Set<String> _kNonFoodKeywords = {
    'carpet', 'rug', 'floor', 'flooring', 'tile', 'wood', 'hardwood',
    'laminate flooring', 'textile', 'mat', 'linoleum', 'ceiling', 'wall',
    'furniture', 'table', 'desk', 'chair', 'couch', 'sofa', 'bed',
    'room', 'interior design', 'door', 'window', 'curtain', 'shelf',
    'person', 'human', 'face', 'hair', 'hand', 'arm', 'clothing', 't-shirt',
    'shirt', 'pants', 'trousers', 'shoe', 'footwear', 'sneakers', 'glasses',
    'electronics', 'gadget', 'computer', 'laptop', 'mobile phone', 'phone',
    'screen', 'display', 'keyboard', 'mouse', 'television', 'audio',
    'dog', 'cat', 'animal', 'carnivore', 'mammal', 'pet',
    'car', 'vehicle', 'automotive', 'wheel', 'tire', 'road',
    'paper', 'book', 'pen', 'pencil', 'box', 'cardboard', 'plastic bag',
    'plant', 'houseplant', 'flower', 'tree', 'grass', 'sky', 'cloud',
    'concrete', 'asphalt', 'brick', 'metal', 'iron', 'steel',
  };

  // Specific food keywords mapped to friendly presentation names
  static const Map<String, String> _kSpecificFoodNames = {
    'pizza': 'Pizza Slice',
    'salad': 'Mixed Garden Salad',
    'caesar salad': 'Chicken Caesar Salad',
    'sandwich': 'Deli Sandwich',
    'burger': 'Beef Cheeseburger',
    'hamburger': 'Beef Burger',
    'cheeseburger': 'Cheeseburger',
    'french fries': 'Crispy French Fries',
    'fries': 'French Fries',
    'pasta': 'Italian Pasta',
    'spaghetti': 'Spaghetti Bolognese',
    'noodle': 'Noodle Bowl',
    'ramen': 'Ramen Soup',
    'sushi': 'Assorted Sushi',
    'steak': 'Grilled Beef Steak',
    'beef': 'Roast Beef',
    'chicken': 'Grilled Chicken Breast',
    'poultry': 'Roasted Chicken',
    'fish': 'Grilled Fish Fillet',
    'salmon': 'Baked Salmon & Greens',
    'shrimp': 'Steamed Shrimp',
    'seafood': 'Seafood Dish',
    'soup': 'Warm Vegetable Soup',
    'stew': 'Hearty Beef Stew',
    'curry': 'Chicken Curry with Rice',
    'rice': 'Steamed Rice',
    'fried rice': 'Egg Fried Rice',
    'bread': 'Whole Grain Bread',
    'toast': 'Toasted Bread',
    'baguette': 'French Baguette',
    'croissant': 'Butter Croissant',
    'pastry': 'Fresh Pastry',
    'pancake': 'Pancakes with Syrup',
    'waffle': 'Belgian Waffle',
    'oatmeal': 'Oatmeal & Fruit Bowl',
    'porridge': 'Warm Porridge',
    'cereal': 'Breakfast Cereal with Milk',
    'egg': 'Scrambled Eggs',
    'scrambled eggs': 'Scrambled Eggs & Toast',
    'omelette': 'Cheese & Herb Omelette',
    'apple': 'Fresh Whole Apple',
    'banana': 'Fresh Banana',
    'orange': 'Fresh Orange',
    'strawberry': 'Fresh Strawberries',
    'berry': 'Mixed Berries',
    'avocado': 'Fresh Avocado',
    'broccoli': 'Steamed Broccoli',
    'tomato': 'Fresh Tomatoes',
    'potato': 'Baked Potato',
    'coffee': 'Brewed Coffee',
    'espresso': 'Espresso',
    'cappuccino': 'Cappuccino',
    'latte': 'Caffè Latte',
    'tea': 'Green Tea',
    'smoothie': 'Fruit Smoothie',
    'juice': 'Fresh Fruit Juice',
    'yogurt': 'Greek Yogurt',
    'cheese': 'Artisan Cheese',
    'cake': 'Slice of Cake',
    'cookie': 'Chocolate Chip Cookie',
    'ice cream': 'Ice Cream Scoop',
    'chocolate': 'Dark Chocolate',
    'dessert': 'Sweet Dessert',
  };

  // General food category keywords
  static const Set<String> _kGeneralFoodCategories = {
    'food', 'dish', 'cuisine', 'meal', 'produce', 'vegetable', 'fruit',
    'tableware', 'serveware', 'plate', 'platter', 'bowl', 'finger food',
    'fast food', 'junk food', 'comfort food', 'baked goods', 'dairy',
    'meat', 'beverage', 'drink', 'snack', 'breakfast', 'lunch', 'dinner',
    'recipe', 'ingredient',
  };

  /// Analyzes an image file using on-device ML Kit image labeling.
  /// If [labelsOverride] is provided (useful for tests), it bypasses ML Kit channel invocation.
  Future<FoodVisionResult> analyzeImageFile(
    File imageFile, {
    List<ImageLabel>? labelsOverride,
  }) async {
    if (!imageFile.existsSync() && labelsOverride == null) {
      return FoodVisionResult.unclear();
    }

    List<ImageLabel> labels = [];

    if (labelsOverride != null) {
      labels = labelsOverride;
    } else {
      ImageLabeler? labeler;
      try {
        labeler = ImageLabeler(
          options: ImageLabelerOptions(confidenceThreshold: 0.35),
        );
        final inputImage = InputImage.fromFilePath(imageFile.path);
        labels = await labeler.processImage(inputImage);
      } catch (e) {
        debugPrint('ML Kit image labeling error: $e');
        // Graceful fallback if ML Kit is unavailable
        return FoodVisionResult.unclear();
      } finally {
        await labeler?.close();
      }
    }

    return classifyLabels(labels);
  }

  /// Classifies detected image labels into Food vs Non-Food with specific naming
  FoodVisionResult classifyLabels(List<ImageLabel> labels) {
    if (labels.isEmpty) {
      return FoodVisionResult.unclear();
    }

    final allTextLabels = labels.map((l) => l.label).toList();

    // Check for high-confidence non-food entities first
    ImageLabel? strongestNonFood;
    for (final label in labels) {
      final clean = label.label.trim().toLowerCase();
      for (final nonFood in _kNonFoodKeywords) {
        if (clean == nonFood || clean.contains(nonFood)) {
          if (strongestNonFood == null || label.confidence > strongestNonFood.confidence) {
            strongestNonFood = label;
          }
          break;
        }
      }
    }

    // Check for specific food entities
    ImageLabel? bestSpecificFood;
    String? matchedSpecificName;
    for (final label in labels) {
      final clean = label.label.trim().toLowerCase();
      for (final entry in _kSpecificFoodNames.entries) {
        if (clean == entry.key || clean.contains(entry.key)) {
          if (bestSpecificFood == null || label.confidence > bestSpecificFood.confidence) {
            bestSpecificFood = label;
            matchedSpecificName = entry.value;
          }
          break;
        }
      }
    }

    // Check for general food indicators (Food, Dish, Cuisine, Produce, etc.)
    ImageLabel? bestGeneralFood;
    for (final label in labels) {
      final clean = label.label.trim().toLowerCase();
      for (final gen in _kGeneralFoodCategories) {
        if (clean == gen || clean.contains(gen)) {
          if (bestGeneralFood == null || label.confidence > bestGeneralFood.confidence) {
            bestGeneralFood = label;
          }
          break;
        }
      }
    }

    // DECISION LOGIC:
    // 1. If non-food is detected with high confidence and NO food labels exist:
    if (strongestNonFood != null && bestSpecificFood == null && bestGeneralFood == null) {
      return FoodVisionResult.nonFood(
        detectedEntity: _formatEntityName(strongestNonFood.label),
        confidence: strongestNonFood.confidence,
        labels: allTextLabels,
      );
    }

    // 2. If non-food confidence is significantly higher than any weak food hint (e.g. carpet table vs 0.35 food hint):
    if (strongestNonFood != null &&
        bestSpecificFood == null &&
        strongestNonFood.confidence > 0.70 &&
        (bestGeneralFood == null || bestGeneralFood.confidence < 0.50)) {
      return FoodVisionResult.nonFood(
        detectedEntity: _formatEntityName(strongestNonFood.label),
        confidence: strongestNonFood.confidence,
        labels: allTextLabels,
      );
    }

    // 3. If a specific food entity is detected:
    if (bestSpecificFood != null && matchedSpecificName != null) {
      return FoodVisionResult.food(
        foodName: matchedSpecificName,
        confidence: bestSpecificFood.confidence,
        labels: allTextLabels,
        query: bestSpecificFood.label,
      );
    }

    // 4. If general food category is detected (e.g. "Food", "Dish", "Cuisine", "Meal"):
    if (bestGeneralFood != null && bestGeneralFood.confidence >= 0.40) {
      return FoodVisionResult.food(
        foodName: 'Prepared Meal / Dish',
        confidence: bestGeneralFood.confidence,
        labels: allTextLabels,
        query: 'mixed meal plate with protein and vegetables',
      );
    }

    // 5. If we have any non-food label at all:
    if (strongestNonFood != null) {
      return FoodVisionResult.nonFood(
        detectedEntity: _formatEntityName(strongestNonFood.label),
        confidence: strongestNonFood.confidence,
        labels: allTextLabels,
      );
    }

    // 6. Otherwise unclear
    return FoodVisionResult.unclear(labels: allTextLabels);
  }

  String _formatEntityName(String raw) {
    if (raw.toLowerCase().contains('carpet') || raw.toLowerCase().contains('rug')) {
      return 'Floor Carpet / Rug';
    }
    if (raw.toLowerCase().contains('floor')) {
      return 'Floor / Flooring';
    }
    if (raw.toLowerCase().contains('furniture') || raw.toLowerCase().contains('chair') || raw.toLowerCase().contains('table')) {
      return 'Furniture';
    }
    if (raw.toLowerCase().contains('electronic') ||
        raw.toLowerCase().contains('computer') ||
        raw.toLowerCase().contains('laptop') ||
        raw.toLowerCase().contains('phone') ||
        raw.toLowerCase().contains('screen')) {
      return 'Electronics / Screen';
    }
    if (raw.toLowerCase().contains('person') || raw.toLowerCase().contains('face')) {
      return 'Person / Face';
    }
    return raw;
  }
}
