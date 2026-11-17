import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../services/ai_nutrition_estimator.dart';

class AiMealEstimatorScreen extends StatefulWidget {
  final String date;
  final VoidCallback onLogged;

  const AiMealEstimatorScreen({
    super.key,
    required this.date,
    required this.onLogged,
  });

  @override
  State<AiMealEstimatorScreen> createState() => _AiMealEstimatorScreenState();
}

class _AiMealEstimatorScreenState extends State<AiMealEstimatorScreen> {
  final TextEditingController _promptController = TextEditingController(
    text: '2 scrambled eggs with 1 slice toast and half an avocado',
  );
  bool _isLoading = false;
  AiEstimatedMeal? _estimatedMeal;
  String _mealCategory = 'Lunch';

  final List<String> _samplePrompts = [
    '2 boiled eggs with 1 slice toast',
    'Grilled chicken with brown rice and broccoli',
    'Bowl of oatmeal with banana and milk',
    '1 slice pizza with a soda',
    'Salmon fillet with roasted potatoes',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _estimate() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final meal = await AiNutritionEstimator.instance.estimateMeal(text);
      if (!mounted) return;
      setState(() {
        _estimatedMeal = meal;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estimation failed: $e')),
      );
    }
  }

  Future<void> _logToDiary() async {
    final meal = _estimatedMeal;
    if (meal == null) return;

    final timeStr = DateFormat('HH:mm').format(DateTime.now());

    for (final item in meal.items) {
      final food = Food(
        name: item.name,
        calories: item.calories,
        protein: item.protein,
        carbs: item.carbs,
        fat: item.fat,
        fiber: (item.carbs * 0.1).clamp(0.0, 10.0),
        unit: 'g',
        baseAmount: item.estimatedGrams > 0 ? item.estimatedGrams : 100,
        isSystem: false,
      );

      final foodId = await AppDb.instance.insertFood(food);

      await AppDb.instance.insertLog(
        LogEntry(
          date: widget.date,
          foodId: foodId,
          grams: item.estimatedGrams > 0 ? item.estimatedGrams : 100,
          unit: 'g',
          baseAmount: item.estimatedGrams > 0 ? item.estimatedGrams : 100,
          label: _mealCategory,
          time: timeStr,
          foodName: item.name,
          calories100: item.calories,
          protein100: item.protein,
          carbs100: item.carbs,
          fat100: item.fat,
          notes: 'AI Estimated (${meal.query})',
        ),
      );
    }

    widget.onLogged();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${meal.totalCalories.round()} kcal from AI estimate to ${widget.date}!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meal Estimator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple.withAlpha(30),
                          child: const Icon(Icons.auto_awesome, color: Colors.purple),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Describe What You Ate',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Type in natural language, AI will calculate macros',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _promptController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 2 eggs with toast and butter, coffee with milk',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'Quick Presets:',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _samplePrompts.map((p) {
                        return ActionChip(
                          avatar: const Icon(Icons.flash_on, size: 14),
                          label: Text(p, style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            _promptController.text = p;
                            _estimate();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Calculate Nutrition Estimate'),
                        onPressed: _isLoading ? null : _estimate,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estimated Result Card
            if (_estimatedMeal != null) ...[
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Nutrition',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_estimatedMeal!.totalCalories.round()} kcal',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _nutrientCol('Protein', '${_estimatedMeal!.totalProtein.round()}g', Colors.teal),
                          _nutrientCol('Carbs', '${_estimatedMeal!.totalCarbs.round()}g', Colors.orange),
                          _nutrientCol('Fat', '${_estimatedMeal!.totalFat.round()}g', Colors.redAccent),
                          _nutrientCol('Fiber', '${_estimatedMeal!.totalFiber.round()}g', Colors.brown),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Detected Ingredients:',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      ..._estimatedMeal!.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ),
                                Text(
                                  '~${item.estimatedGrams.round()}g (${item.calories.round()} kcal)',
                                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                                ),
                              ],
                            ),
                          )),

                      const Divider(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _mealCategory,
                              decoration: const InputDecoration(
                                labelText: 'Log Under Meal',
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
                                if (v != null) setState(() => _mealCategory = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add to Diary'),
                              onPressed: _logToDiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _nutrientCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
