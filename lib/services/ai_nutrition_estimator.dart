import 'dart:convert';
import 'package:http/http.dart' as http;

class AiMealItem {
  final String name;
  final double estimatedGrams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const AiMealItem({
    required this.name,
    required this.estimatedGrams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class AiEstimatedMeal {
  final String query;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final List<AiMealItem> items;
  final String confidence; // 'High', 'Medium', 'Estimated'
  final String advice;

  const AiEstimatedMeal({
    required this.query,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    this.totalFiber = 0.0,
    required this.items,
    this.confidence = 'High',
    this.advice = '',
  });
}

class AiNutritionEstimator {
  AiNutritionEstimator._();
  static final AiNutritionEstimator instance = AiNutritionEstimator._();

  // Common ingredient heuristic database for offline natural language parsing
  static final Map<String, Map<String, double>> _ingredientBank = {
    'egg': {'cal_per_unit': 72, 'p': 6.3, 'c': 0.4, 'f': 4.8, 'wt': 50},
    'toast': {'cal_per_unit': 75, 'p': 3.0, 'c': 13.0, 'f': 1.0, 'wt': 30},
    'bread': {'cal_per_unit': 80, 'p': 3.2, 'c': 14.0, 'f': 1.1, 'wt': 35},
    'chicken': {'cal_per_unit': 165, 'p': 31.0, 'c': 0.0, 'f': 3.6, 'wt': 100},
    'rice': {'cal_per_unit': 130, 'p': 2.7, 'c': 28.0, 'f': 0.3, 'wt': 100},
    'oats': {'cal_per_unit': 150, 'p': 5.0, 'c': 27.0, 'f': 3.0, 'wt': 40},
    'oatmeal': {'cal_per_unit': 150, 'p': 5.0, 'c': 27.0, 'f': 3.0, 'wt': 40},
    'banana': {'cal_per_unit': 105, 'p': 1.3, 'c': 27.0, 'f': 0.3, 'wt': 118},
    'apple': {'cal_per_unit': 95, 'p': 0.5, 'c': 25.0, 'f': 0.3, 'wt': 182},
    'avocado': {'cal_per_unit': 160, 'p': 2.0, 'c': 8.5, 'f': 14.7, 'wt': 100},
    'milk': {'cal_per_unit': 120, 'p': 8.0, 'c': 12.0, 'f': 5.0, 'wt': 240},
    'butter': {'cal_per_unit': 100, 'p': 0.1, 'c': 0.1, 'f': 11.5, 'wt': 14},
    'olive oil': {'cal_per_unit': 120, 'p': 0.0, 'c': 0.0, 'f': 14.0, 'wt': 14},
    'oil': {'cal_per_unit': 120, 'p': 0.0, 'c': 0.0, 'f': 14.0, 'wt': 14},
    'beef': {'cal_per_unit': 250, 'p': 26.0, 'c': 0.0, 'f': 17.0, 'wt': 100},
    'steak': {'cal_per_unit': 270, 'p': 28.0, 'c': 0.0, 'f': 18.0, 'wt': 100},
    'fish': {'cal_per_unit': 140, 'p': 22.0, 'c': 0.0, 'f': 5.0, 'wt': 100},
    'salmon': {'cal_per_unit': 208, 'p': 20.0, 'c': 0.0, 'f': 13.0, 'wt': 100},
    'broccoli': {'cal_per_unit': 35, 'p': 2.8, 'c': 7.0, 'f': 0.4, 'wt': 100},
    'potato': {'cal_per_unit': 130, 'p': 3.0, 'c': 30.0, 'f': 0.2, 'wt': 150},
    'salad': {'cal_per_unit': 45, 'p': 1.5, 'c': 8.0, 'f': 0.5, 'wt': 100},
    'pasta': {'cal_per_unit': 200, 'p': 7.0, 'c': 42.0, 'f': 1.0, 'wt': 150},
    'pizza': {'cal_per_unit': 285, 'p': 12.0, 'c': 36.0, 'f': 10.0, 'wt': 107},
    'burger': {'cal_per_unit': 350, 'p': 17.0, 'c': 32.0, 'f': 18.0, 'wt': 150},
    'coffee': {'cal_per_unit': 5, 'p': 0.3, 'c': 0.0, 'f': 0.0, 'wt': 200},
    'tea': {'cal_per_unit': 2, 'p': 0.0, 'c': 0.4, 'f': 0.0, 'wt': 200},
    'yogurt': {'cal_per_unit': 100, 'p': 10.0, 'c': 6.0, 'f': 4.0, 'wt': 150},
    'cheese': {'cal_per_unit': 110, 'p': 7.0, 'c': 1.0, 'f': 9.0, 'wt': 30},
    'almonds': {'cal_per_unit': 160, 'p': 6.0, 'c': 6.0, 'f': 14.0, 'wt': 28},
    'nuts': {'cal_per_unit': 170, 'p': 5.0, 'c': 6.0, 'f': 15.0, 'wt': 28},
  };

  /// Parses natural language input into structured nutritional breakdown
  Future<AiEstimatedMeal> estimateMeal(String prompt, {String? geminiApiKey}) async {
    final clean = prompt.trim().toLowerCase();
    if (clean.isEmpty) {
      throw Exception('Meal description cannot be empty');
    }

    // If a remote Gemini API key is provided and available, we can optionally use it
    if (geminiApiKey != null && geminiApiKey.trim().isNotEmpty) {
      try {
        final res = await _callGeminiApi(prompt, geminiApiKey.trim());
        if (res != null) return res;
      } catch (_) {
        // Fallback to local heuristic parser
      }
    }

    return _estimateHeuristic(prompt);
  }

  AiEstimatedMeal _estimateHeuristic(String prompt) {
    final clean = prompt.toLowerCase();
    final items = <AiMealItem>[];

    double sumCal = 0;
    double sumP = 0;
    double sumC = 0;
    double sumF = 0;

    // Check numbers preceding food keywords
    final regex = RegExp(r'(\d+(?:\.\d+)?)\s*(?:x\s*)?([a-z\s]+)');
    final matches = regex.allMatches(clean);

    final detectedKeys = <String>{};

    for (final match in matches) {
      final qty = double.tryParse(match.group(1) ?? '1') ?? 1.0;
      final textAfter = match.group(2) ?? '';

      for (final entry in _ingredientBank.entries) {
        if (textAfter.contains(entry.key) && !detectedKeys.contains(entry.key)) {
          detectedKeys.add(entry.key);
          final data = entry.value;
          final cal = data['cal_per_unit']! * qty;
          final p = data['p']! * qty;
          final c = data['c']! * qty;
          final f = data['f']! * qty;
          final wt = data['wt']! * qty;

          items.add(AiMealItem(
            name: '${qty.round() > 1 ? "${qty.toStringAsFixed(0)} " : ""}${entry.key.toUpperCase()}',
            estimatedGrams: wt,
            calories: cal,
            protein: p,
            carbs: c,
            fat: f,
          ));

          sumCal += cal;
          sumP += p;
          sumC += c;
          sumF += f;
          break;
        }
      }
    }

    // Check remaining words without explicit leading numbers
    for (final entry in _ingredientBank.entries) {
      if (clean.contains(entry.key) && !detectedKeys.contains(entry.key)) {
        detectedKeys.add(entry.key);
        final data = entry.value;
        final cal = data['cal_per_unit']!;
        final p = data['p']!;
        final c = data['c']!;
        final f = data['f']!;
        final wt = data['wt']!;

        items.add(AiMealItem(
          name: entry.key.toUpperCase(),
          estimatedGrams: wt,
          calories: cal,
          protein: p,
          carbs: c,
          fat: f,
        ));

        sumCal += cal;
        sumP += p;
        sumC += c;
        sumF += f;
      }
    }

    if (items.isEmpty) {
      // General fallback estimation
      sumCal = 350;
      sumP = 15;
      sumC = 45;
      sumF = 12;
      items.add(AiMealItem(
        name: prompt,
        estimatedGrams: 200,
        calories: sumCal,
        protein: sumP,
        carbs: sumC,
        fat: sumF,
      ));
    }

    return AiEstimatedMeal(
      query: prompt,
      totalCalories: sumCal,
      totalProtein: sumP,
      totalCarbs: sumC,
      totalFat: sumF,
      totalFiber: (sumC * 0.1).clamp(1.0, 15.0),
      items: items,
      confidence: items.length > 1 ? 'High' : 'Estimated',
      advice: 'Estimated using standard dietary reference databases. You can adjust grams before logging.',
    );
  }

  Future<AiEstimatedMeal?> _callGeminiApi(String prompt, String apiKey) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final systemInstruction =
        'Estimate the total nutrition of this meal. Return JSON only with keys: total_calories, total_protein, total_carbs, total_fat, total_fiber, and items (list of {name, grams, calories, protein, carbs, fat}).';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': '$systemInstruction\nMeal: $prompt'}
          ]
        }
      ],
      'generationConfig': {'response_mime_type': 'application/json'},
    });

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 8));

    if (resp.statusCode == 200) {
      final jsonResp = jsonDecode(resp.body);
      final candidateText = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'];
      if (candidateText != null) {
        final parsed = jsonDecode(candidateText);
        final rawItems = parsed['items'] as List? ?? [];
        final items = rawItems.map((i) {
          return AiMealItem(
            name: (i['name'] as String?) ?? 'Ingredient',
            estimatedGrams: ((i['grams'] as num?) ?? 100).toDouble(),
            calories: ((i['calories'] as num?) ?? 0).toDouble(),
            protein: ((i['protein'] as num?) ?? 0).toDouble(),
            carbs: ((i['carbs'] as num?) ?? 0).toDouble(),
            fat: ((i['fat'] as num?) ?? 0).toDouble(),
          );
        }).toList();

        return AiEstimatedMeal(
          query: prompt,
          totalCalories: ((parsed['total_calories'] as num?) ?? 0).toDouble(),
          totalProtein: ((parsed['total_protein'] as num?) ?? 0).toDouble(),
          totalCarbs: ((parsed['total_carbs'] as num?) ?? 0).toDouble(),
          totalFat: ((parsed['total_fat'] as num?) ?? 0).toDouble(),
          totalFiber: ((parsed['total_fiber'] as num?) ?? 0).toDouble(),
          items: items,
          confidence: 'High',
          advice: 'AI-generated estimate based on global nutritional standards.',
        );
      }
    }
    return null;
  }
}
