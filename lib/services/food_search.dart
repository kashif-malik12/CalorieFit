// lib/services/food_search.dart
//
// Uses the USDA FoodData Central API (free, no sign-up required with DEMO_KEY).
// All nutrient values returned are per 100 g / 100 ml.

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

const String kUsdaApiKey = String.fromEnvironment(
  'USDA_API_KEY',
  defaultValue: '',
);

class FoodSearchException implements Exception {
  final String message;

  const FoodSearchException(this.message);

  @override
  String toString() => message;
}

Never _throwSearchError(Object error) {
  if (error is TimeoutException) {
    throw const FoodSearchException(
      'USDA search timed out. Check your connection and try again.',
    );
  }
  if (error is FoodSearchException) {
    throw error;
  }
  throw FoodSearchException('USDA search failed: $error');
}

void _throwHttpError(int statusCode) {
  if (statusCode == 401 || statusCode == 403) {
    throw const FoodSearchException(
      'USDA search is not configured correctly right now.',
    );
  }
  if (statusCode == 429) {
    throw const FoodSearchException(
      'USDA search is temporarily busy. Try again in a moment.',
    );
  }
  if (statusCode >= 500) {
    throw const FoodSearchException(
      'USDA search is temporarily unavailable. Try again later.',
    );
  }
  throw FoodSearchException('USDA request failed (HTTP $statusCode).');
}

void _ensureApiKeyConfigured() {
  if (kUsdaApiKey.trim().isEmpty) {
    throw const FoodSearchException(
      'USDA search is not configured on this build.',
    );
  }
}

// ── Serving-size lookup ────────────────────────────────────────────────────

/// A food entry returned by the candidate search (fdcId + display name).
class FoodCandidate {
  final int fdcId;
  final String name;
  final String dataType; // e.g. "Foundation", "SR Legacy", "Branded"

  const FoodCandidate({
    required this.fdcId,
    required this.name,
    required this.dataType,
  });
}

/// One USDA portion (e.g. "1 tablespoon" → 13.5 g).
class ServingPortion {
  final String name;   // human-readable label shown to the user
  final double grams;  // gram weight of this portion

  const ServingPortion({required this.name, required this.grams});
}

/// Search USDA for food candidates so the user can pick the right match.
/// Returns up to [pageSize] candidates ordered by relevance.
Future<List<FoodCandidate>> searchFoodCandidates(
  String query, {
  int pageSize = 15,
}) async {
  _ensureApiKeyConfigured();
  final trimmed = query.trim();
  if (trimmed.isEmpty) return [];

  final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
    'query': trimmed,
    'api_key': kUsdaApiKey,
    'pageSize': '$pageSize',
    'dataType': 'Foundation,SR Legacy',
  });

  http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 12));
  } catch (error) {
    _throwSearchError(error);
  }
  if (response.statusCode != 200) {
    _throwHttpError(response.statusCode);
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final foods = (body['foods'] as List?) ?? [];

  return foods.map((f) {
    return FoodCandidate(
      fdcId: (f['fdcId'] as num).toInt(),
      name: _titleCase(f['description'] as String? ?? 'Unknown'),
      dataType: (f['dataType'] as String?) ?? '',
    );
  }).toList();
}

/// Fetch the detailed record for [fdcId] and extract its standard portions.
/// Filters out trivial entries like "100 g" which add no value.
Future<List<ServingPortion>> fetchPortions(int fdcId) async {
  _ensureApiKeyConfigured();
  final uri = Uri.https(
    'api.nal.usda.gov',
    '/fdc/v1/food/$fdcId',
    {'api_key': kUsdaApiKey},
  );

  http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 12));
  } catch (error) {
    _throwSearchError(error);
  }
  if (response.statusCode != 200) {
    _throwHttpError(response.statusCode);
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final rawPortions = (body['foodPortions'] as List?) ?? [];

  final results = <ServingPortion>[];

  for (final p in rawPortions) {
    final grams = ((p['gramWeight'] as num?) ?? 0).toDouble();
    if (grams <= 0) continue;

    // Build a readable name from available fields
    final amount = ((p['amount'] as num?) ?? 1).toDouble();
    final amtStr = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);

    String label;
    final desc = (p['portionDescription'] as String?)?.trim() ?? '';
    final modifier = (p['modifier'] as String?)?.trim() ?? '';
    final unitName =
        ((p['measureUnit'] as Map?)?['name'] as String?)?.trim() ?? '';

    if (desc.isNotEmpty && desc.toLowerCase() != '1 serving') {
      label = desc;
    } else if (modifier.isNotEmpty) {
      label = '$amtStr $modifier';
    } else if (unitName.isNotEmpty && unitName != 'undetermined') {
      label = '$amtStr $unitName';
    } else {
      continue; // skip unidentifiable portions
    }

    // Skip trivial 100 g / 100 ml base entries
    if (RegExp(r'^100\s*(g|ml|gram)', caseSensitive: false).hasMatch(label)) {
      continue;
    }

    results.add(ServingPortion(name: label, grams: grams));
  }

  return results;
}

class FoodSearchResult {
  final String name;
  final double calories;  // per 100 g
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;    // mg per 100 g

  const FoodSearchResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
  });

  /// Pretty label shown in the results list.
  String get macroSummary =>
      '${calories.toStringAsFixed(0)} kcal | '
      'P ${protein.toStringAsFixed(1)} g | '
      'C ${carbs.toStringAsFixed(1)} g | '
      'F ${fat.toStringAsFixed(1)} g'
      '  (per 100 g)';
}

/// USDA nutrient IDs we care about.
const _kNutrientIds = {
  1008: 'calories',  // Energy, kcal
  1003: 'protein',   // Protein
  1005: 'carbs',     // Carbohydrate, by difference
  1004: 'fat',       // Total lipid (fat)
  1079: 'fiber',     // Fiber, total dietary
  2000: 'sugar',     // Sugars, total
  1093: 'sodium',    // Sodium, Na
};

/// Capitalises each word (USDA names are ALL-CAPS).
String _titleCase(String s) => s
    .toLowerCase()
    .split(' ')
    .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
    .join(' ');

Future<List<FoodSearchResult>> searchFoodsOnline(String query) async {
  _ensureApiKeyConfigured();
  final trimmed = query.trim();
  if (trimmed.isEmpty) return [];

  final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
    'query': trimmed,
    'api_key': kUsdaApiKey,
    'pageSize': '20',
    'dataType': 'Foundation,SR Legacy',
  });

  http.Response response;
  try {
    response = await http.get(uri).timeout(const Duration(seconds: 12));
  } catch (error) {
    _throwSearchError(error);
  }
  if (response.statusCode != 200) {
    _throwHttpError(response.statusCode);
  }

  final body = jsonDecode(response.body) as Map<String, dynamic>;
  final foods = (body['foods'] as List?) ?? [];

  final results = <FoodSearchResult>[];

  for (final f in foods) {
    final nutrients = (f['foodNutrients'] as List?) ?? [];

    double get(int id) {
      for (final n in nutrients) {
        if ((n['nutrientId'] as int?) == id) {
          return ((n['value'] as num?) ?? 0).toDouble();
        }
      }
      return 0;
    }

    final calories = get(1008);
    if (calories <= 0) continue; // skip zero-calorie entries

    results.add(FoodSearchResult(
      name: _titleCase(f['description'] as String? ?? 'Unknown'),
      calories: calories,
      protein: get(1003),
      carbs: get(1005),
      fat: get(1004),
      fiber: get(1079),
      sugar: get(2000),
      sodium: get(1093),
    ));
  }

  return results;
}

