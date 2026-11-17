import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../data/models.dart';

class RecipeIngredient {
  final Food food;
  double grams;

  RecipeIngredient({required this.food, required this.grams});

  double get factor => grams / food.baseAmount;
  double get calories => food.calories * factor;
  double get protein => food.protein * factor;
  double get carbs => food.carbs * factor;
  double get fat => food.fat * factor;
}

class RecipeBuilderScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const RecipeBuilderScreen({super.key, required this.onSaved});

  @override
  State<RecipeBuilderScreen> createState() => _RecipeBuilderScreenState();
}

class _RecipeBuilderScreenState extends State<RecipeBuilderScreen> {
  final TextEditingController _recipeNameController = TextEditingController();
  final List<RecipeIngredient> _ingredients = [];
  int _servings = 1;
  String _selectedCategory = 'Lunch';

  double get totalCalories => _ingredients.fold(0.0, (sum, i) => sum + i.calories);
  double get totalProtein => _ingredients.fold(0.0, (sum, i) => sum + i.protein);
  double get totalCarbs => _ingredients.fold(0.0, (sum, i) => sum + i.carbs);
  double get totalFat => _ingredients.fold(0.0, (sum, i) => sum + i.fat);

  double get servingCalories => _servings > 0 ? totalCalories / _servings : 0;
  double get servingProtein => _servings > 0 ? totalProtein / _servings : 0;
  double get servingCarbs => _servings > 0 ? totalCarbs / _servings : 0;
  double get servingFat => _servings > 0 ? totalFat / _servings : 0;

  @override
  void dispose() {
    _recipeNameController.dispose();
    super.dispose();
  }

  Future<void> _addIngredientDialog() async {
    final foods = await AppDb.instance.getActiveFoods();
    if (!mounted) return;

    Food? selectedFood;
    final amountController = TextEditingController(text: '100');

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) {
          return AlertDialog(
            title: const Text('Add Ingredient'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Food>(
                    decoration: const InputDecoration(
                      labelText: 'Select Food',
                      border: OutlineInputBorder(),
                    ),
                    items: foods.take(50).map((f) {
                      return DropdownMenuItem<Food>(
                        value: f,
                        child: Text(
                          f.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDState(() => selectedFood = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (selectedFood != null) {
                    final g = double.tryParse(amountController.text) ?? 100.0;
                    setState(() {
                      _ingredients.add(RecipeIngredient(food: selectedFood!, grams: g));
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveAsTemplate() async {
    final name = _recipeNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    final nowStr = DateTime.now().toIso8601String();
    final db = await AppDb.instance.db;

    final templateId = await db.insert('meal_templates', {
      'name': name,
      'label': _selectedCategory,
      'created_at': nowStr,
      'is_system': 0,
      'is_active': 1,
    });

    for (int i = 0; i < _ingredients.length; i++) {
      final ing = _ingredients[i];
      await db.insert('meal_template_items', {
        'template_id': templateId,
        'food_id': ing.food.id,
        'amount': ing.grams / _servings,
        'unit': 'g',
        'base_amount': ing.food.baseAmount,
        'sort_order': i,
      });
    }

    widget.onSaved();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved recipe "$name" with ${_ingredients.length} ingredients!')),
    );
  }

  Future<void> _logDirectlyToToday() async {
    final name = _recipeNameController.text.trim().isNotEmpty
        ? _recipeNameController.text.trim()
        : 'Custom Recipe';

    if (_ingredients.isEmpty) return;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    for (final ing in _ingredients) {
      final servingAmount = ing.grams / _servings;
      await AppDb.instance.insertLog(
        LogEntry(
          date: todayStr,
          foodId: ing.food.id,
          grams: servingAmount,
          unit: 'g',
          baseAmount: ing.food.baseAmount,
          label: _selectedCategory,
          time: timeStr,
          foodName: '${ing.food.name} (in $name)',
          calories100: ing.food.calories,
          protein100: ing.food.protein,
          carbs100: ing.food.carbs,
          fat100: ing.food.fat,
          fiber100: ing.food.fiber,
        ),
      );
    }

    widget.onSaved();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged 1 serving of "$name" (${servingCalories.round()} kcal) to Today!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe & Meal Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Template',
            onPressed: _saveAsTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Name & Category
            TextField(
              controller: _recipeNameController,
              decoration: const InputDecoration(
                labelText: 'Recipe / Dish Name',
                hintText: 'e.g. Post-Workout Oatmeal Bowl',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.restaurant_menu),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Meal Category',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Breakfast', child: Text('Breakfast')),
                      DropdownMenuItem(value: 'Morning Snack', child: Text('M. Snack')),
                      DropdownMenuItem(value: 'Lunch', child: Text('Lunch')),
                      DropdownMenuItem(value: 'Afternoon Snack', child: Text('A. Snack')),
                      DropdownMenuItem(value: 'Dinner', child: Text('Dinner')),
                      DropdownMenuItem(value: 'Evening Snack', child: Text('E. Snack')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedCategory = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _servings,
                    decoration: const InputDecoration(
                      labelText: 'Servings',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1 Serving')),
                      DropdownMenuItem(value: 2, child: Text('2 Servings')),
                      DropdownMenuItem(value: 3, child: Text('3 Servings')),
                      DropdownMenuItem(value: 4, child: Text('4 Servings')),
                      DropdownMenuItem(value: 6, child: Text('6 Servings')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _servings = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nutrition Summary Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nutrition per Serving (${1}/$_servings)',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${servingCalories.round()} kcal',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _macroTile('Protein', '${servingProtein.toStringAsFixed(1)}g', Colors.teal),
                        _macroTile('Carbs', '${servingCarbs.toStringAsFixed(1)}g', Colors.orange),
                        _macroTile('Fat', '${servingFat.toStringAsFixed(1)}g', Colors.redAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ingredients Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ingredients (${_ingredients.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Ingredient'),
                  onPressed: _addIngredientDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_ingredients.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No ingredients added yet. Tap "Add Ingredient" to start.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ),
              )
            else
              ..._ingredients.asMap().entries.map((entry) {
                final idx = entry.key;
                final ing = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(ing.food.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${ing.calories.round()} kcal • P: ${ing.protein.toStringAsFixed(1)}g • C: ${ing.carbs.toStringAsFixed(1)}g'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${ing.grams.round()}g', style: const TextStyle(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            setState(() => _ingredients.removeAt(idx));
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.bookmark_border),
                    label: const Text('Save as Template'),
                    onPressed: _saveAsTemplate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.playlist_add_check),
                    label: const Text('Log to Today'),
                    onPressed: _logDirectlyToToday,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _macroTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
