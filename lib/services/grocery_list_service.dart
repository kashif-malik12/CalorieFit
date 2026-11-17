import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';

class GroceryItem {
  final String id;
  final String name;
  final String category;
  final String quantity;
  final bool isChecked;

  const GroceryItem({
    required this.id,
    required this.name,
    this.category = 'Pantry',
    this.quantity = '',
    this.isChecked = false,
  });

  GroceryItem copyWith({
    String? id,
    String? name,
    String? category,
    String? quantity,
    bool? isChecked,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      isChecked: isChecked ?? this.isChecked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'isChecked': isChecked,
    };
  }

  static GroceryItem fromMap(Map<String, dynamic> m) {
    return GroceryItem(
      id: (m['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: (m['name'] as String?) ?? '',
      category: (m['category'] as String?) ?? 'Pantry',
      quantity: (m['quantity'] as String?) ?? '',
      isChecked: (m['isChecked'] as bool?) ?? false,
    );
  }

  /// Automatically categorizes a food name into grocery sections
  static String guessCategory(String foodName) {
    final lower = foodName.toLowerCase();
    if (lower.contains('apple') || lower.contains('banana') || lower.contains('spinach') ||
        lower.contains('avocado') || lower.contains('onion') || lower.contains('tomato') ||
        lower.contains('potato') || lower.contains('salad') || lower.contains('lettuce') ||
        lower.contains('broccoli') || lower.contains('lemon') || lower.contains('orange') ||
        lower.contains('fruit') || lower.contains('vegetable') || lower.contains('berry')) {
      return 'Produce & Greens';
    }
    if (lower.contains('chicken') || lower.contains('beef') || lower.contains('salmon') ||
        lower.contains('tuna') || lower.contains('turkey') || lower.contains('pork') ||
        lower.contains('steak') || lower.contains('meat') || lower.contains('shrimp') ||
        lower.contains('egg')) {
      return 'Meat, Seafood & Eggs';
    }
    if (lower.contains('milk') || lower.contains('yogurt') || lower.contains('cheese') ||
        lower.contains('butter') || lower.contains('cream') || lower.contains('whey')) {
      return 'Dairy & Refrigerated';
    }
    if (lower.contains('rice') || lower.contains('oat') || lower.contains('bread') ||
        lower.contains('pasta') || lower.contains('quinoa') || lower.contains('flour') ||
        lower.contains('tortilla')) {
      return 'Grains & Bakery';
    }
    return 'Pantry & Spices';
  }
}

class GroceryListService {
  static const String _prefKeyGrocery = 'user_grocery_list_items';
  final AppDb db;

  GroceryListService({AppDb? db}) : db = db ?? AppDb.instance;
  static final GroceryListService instance = GroceryListService();

  Future<List<GroceryItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyGrocery);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => GroceryItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveItems(List<GroceryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((i) => i.toMap()).toList();
    await prefs.setString(_prefKeyGrocery, jsonEncode(jsonList));
  }

  Future<void> addItem(String name, {String? quantity, String? category}) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final items = await getItems();
    final guessed = category ?? GroceryItem.guessCategory(cleanName);
    final newItem = GroceryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: cleanName,
      category: guessed,
      quantity: quantity ?? '',
      isChecked: false,
    );
    items.add(newItem);
    await saveItems(items);
  }

  Future<void> toggleItem(String id) async {
    final items = await getItems();
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(isChecked: !items[idx].isChecked);
      await saveItems(items);
    }
  }

  Future<void> deleteItem(String id) async {
    final items = await getItems();
    items.removeWhere((i) => i.id == id);
    await saveItems(items);
  }

  Future<void> clearChecked() async {
    final items = await getItems();
    items.removeWhere((i) => i.isChecked);
    await saveItems(items);
  }

  /// Automatically imports food ingredients from a given date's diary into the grocery list.
  Future<int> importFromDiaryDate(String dateStr) async {
    final rows = await db.getLogRowsForDate(dateStr);
    if (rows.isEmpty) return 0;

    final currentItems = await getItems();
    int added = 0;

    for (final r in rows) {
      final name = (r['food_name'] ?? r['name'] ?? '').toString().trim();
      final grams = ((r['grams'] as num?) ?? 100).round();
      if (name.isNotEmpty && !currentItems.any((i) => i.name.toLowerCase() == name.toLowerCase())) {
        final item = GroceryItem(
          id: '${DateTime.now().millisecondsSinceEpoch}_$added',
          name: name,
          category: GroceryItem.guessCategory(name),
          quantity: '${grams}g',
          isChecked: false,
        );
        currentItems.add(item);
        added++;
      }
    }

    if (added > 0) {
      await saveItems(currentItems);
    }
    return added;
  }
}
