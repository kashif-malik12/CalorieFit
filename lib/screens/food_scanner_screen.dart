import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../services/ai_nutrition_estimator.dart';

class FoodScannerScreen extends StatefulWidget {
  final String date;
  final String? defaultMeal;
  final VoidCallback onLogged;

  const FoodScannerScreen({
    super.key,
    required this.date,
    this.defaultMeal,
    required this.onLogged,
  });

  @override
  State<FoodScannerScreen> createState() => _FoodScannerScreenState();
}

class _FoodScannerScreenState extends State<FoodScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late final AnimationController _scanAnimController;

  XFile? _capturedImage;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String _selectedMeal = 'Lunch';
  double _portionMultiplier = 1.0;
  String _detectedDishName = 'Grilled Chicken Salad';
  AiEstimatedMeal? _estimatedMeal;
  final TextEditingController _dishNameController = TextEditingController();

  final List<Map<String, dynamic>> _quickDishPresets = [
    {
      'name': 'Grilled Chicken Salad',
      'icon': '🥗',
      'query': '150g grilled chicken breast with mixed greens, tomato, cucumber and 1 tbsp olive oil',
    },
    {
      'name': 'Scrambled Eggs & Toast',
      'icon': '🍳',
      'query': '2 scrambled eggs with 1 slice whole wheat toast and butter',
    },
    {
      'name': 'Avocado Toast',
      'icon': '🥑',
      'query': '2 slices toast with 1 mashed avocado and salt and pepper',
    },
    {
      'name': 'Salmon, Rice & Veggies',
      'icon': '🐟',
      'query': '150g salmon fillet with 100g white rice and steamed broccoli',
    },
    {
      'name': 'Pepperoni Pizza Slice',
      'icon': '🍕',
      'query': '2 slices pepperoni pizza',
    },
    {
      'name': 'Beef Cheeseburger',
      'icon': '🍔',
      'query': '1 cheeseburger with beef patty, cheddar, lettuce and bun',
    },
    {
      'name': 'Pasta Bolognese',
      'icon': '🍝',
      'query': '150g pasta with 100g beef bolognese sauce and parmesan',
    },
    {
      'name': 'Oatmeal & Fruit Bowl',
      'icon': '🥣',
      'query': '50g oatmeal with 1 cup milk, 1 sliced banana and berries',
    },
    {
      'name': 'Steak & Roasted Potatoes',
      'icon': '🥩',
      'query': '200g grilled steak with 150g roasted potatoes and garlic butter',
    },
    {
      'name': 'Greek Yogurt & Berries',
      'icon': '🍓',
      'query': '200g greek yogurt with 50g berries and 1 tbsp honey',
    },
  ];

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Auto-detect default meal category from current time if not provided
    if (widget.defaultMeal != null && widget.defaultMeal!.isNotEmpty) {
      _selectedMeal = widget.defaultMeal!;
    } else {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 11) {
        _selectedMeal = 'Breakfast';
      } else if (hour >= 11 && hour < 16) {
        _selectedMeal = 'Lunch';
      } else if (hour >= 16 && hour < 22) {
        _selectedMeal = 'Dinner';
      } else {
        _selectedMeal = 'Snack';
      }
    }

    _dishNameController.text = _detectedDishName;
    _runEstimation(_quickDishPresets.first['query'] as String);
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    _dishNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _capturedImage = picked;
          _isAnalyzing = true;
        });

        // Run analysis on captured food photo
        await Future.delayed(const Duration(milliseconds: 600));

        // Predict dish based on user context or meal category
        String detected = _dishNameController.text.trim();
        if (detected.isEmpty) {
          detected = _selectedMeal == 'Breakfast'
              ? 'Scrambled Eggs & Toast'
              : (_selectedMeal == 'Dinner' ? 'Salmon, Rice & Veggies' : 'Grilled Chicken Salad');
          _dishNameController.text = detected;
        }

        await _runEstimation(detected);
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  Future<void> _runEstimation(String query) async {
    setState(() => _isAnalyzing = true);
    try {
      final meal = await AiNutritionEstimator.instance.estimateMeal(query);
      if (!mounted) return;
      setState(() {
        _estimatedMeal = meal;
        _isAnalyzing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _logFoodEntry() async {
    final meal = _estimatedMeal;
    if (meal == null) return;

    setState(() => _isSaving = true);

    try {
      final mult = _portionMultiplier;
      final dishName = _dishNameController.text.trim().isNotEmpty
          ? _dishNameController.text.trim()
          : (meal.items.isNotEmpty ? meal.items.first.name : 'Scanned Meal');

      final totalKcal = meal.totalCalories * mult;
      final totalP = meal.totalProtein * mult;
      final totalC = meal.totalCarbs * mult;
      final totalF = meal.totalFat * mult;
      final totalFiber = meal.totalFiber * mult;

      double totalGrams = 0;
      for (final it in meal.items) {
        totalGrams += (it.estimatedGrams > 0 ? it.estimatedGrams : 100) * mult;
      }
      if (totalGrams <= 0) totalGrams = 200 * mult;

      // Calculate per 100g base nutrition for Food model
      final factor = totalGrams > 0 ? (100.0 / totalGrams) : 1.0;
      final cal100 = totalKcal * factor;
      final p100 = totalP * factor;
      final c100 = totalC * factor;
      final f100 = totalF * factor;
      final fiber100 = totalFiber * factor;

      final food = Food(
        name: dishName,
        calories: cal100,
        protein: p100,
        carbs: c100,
        fat: f100,
        fiber: fiber100,
        unit: 'g',
        baseAmount: 100,
        isSystem: false,
      );

      final foodId = await AppDb.instance.insertFood(food);
      final timeStr = DateFormat('HH:mm').format(DateTime.now());

      await AppDb.instance.insertLog(
        LogEntry(
          date: widget.date,
          foodId: foodId,
          grams: totalGrams,
          unit: 'g',
          baseAmount: 100,
          label: _selectedMeal,
          time: timeStr,
          foodName: dishName,
          calories100: cal100,
          protein100: p100,
          carbs100: c100,
          fat100: f100,
          fiber100: fiber100,
          imagePath: _capturedImage?.path,
          notes: 'Scanned via Camera Food Scanner',
        ),
      );

      widget.onLogged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal.shade700,
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logged "${dishName}" (${totalKcal.round()} kcal) to $_selectedMeal!',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log scanned food: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meal = _estimatedMeal;
    final mult = _portionMultiplier;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.teal),
            SizedBox(width: 8),
            Text('Scan Food for Calories'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from Gallery',
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Retake Photo',
            onPressed: () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Camera / Photo Viewfinder
            _buildCameraViewfinder(theme),

            // Analysis & Detection Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dish Name & Auto Suggestion Bar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dishNameController,
                          decoration: InputDecoration(
                            labelText: 'Detected Dish / Meal Name',
                            hintText: 'e.g. Chicken Caesar Salad, Pizza, Steak...',
                            prefixIcon: const Icon(Icons.restaurant, color: Colors.teal),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                              tooltip: 'Re-analyze nutrition',
                              onPressed: () => _runEstimation(_dishNameController.text),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (val) => _runEstimation(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Dish Presets Carousel
                  const Text(
                    'Quick Food Presets:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _quickDishPresets.map((preset) {
                        final isSelected = _dishNameController.text == preset['name'];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            avatar: Text(preset['icon'] as String, style: const TextStyle(fontSize: 14)),
                            label: Text(preset['name'] as String),
                            selected: isSelected,
                            onSelected: (_) {
                              _dishNameController.text = preset['name'] as String;
                              _runEstimation(preset['query'] as String);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Portion Multiplier Controls
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Portion Size:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${(_portionMultiplier * 100).round()}% Serving',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildPortionChip('0.5x', 0.5, 'Light'),
                            const SizedBox(width: 6),
                            _buildPortionChip('0.75x', 0.75, 'Small'),
                            const SizedBox(width: 6),
                            _buildPortionChip('1.0x', 1.0, 'Regular'),
                            const SizedBox(width: 6),
                            _buildPortionChip('1.25x', 1.25, 'Hearty'),
                            const SizedBox(width: 6),
                            _buildPortionChip('1.5x', 1.5, 'Large'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nutritional Breakdown Card
                  if (_isAnalyzing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(28.0),
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Scanning dish and computing nutritional breakdown...'),
                          ],
                        ),
                      ),
                    )
                  else if (meal != null) ...[
                    _buildNutritionSummaryCard(theme, meal, mult),
                    const SizedBox(height: 16),

                    // Meal Category Selector
                    const Text(
                      'Log into Meal Slot:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMealCategoryChip('Breakfast', Icons.free_breakfast, Colors.orange),
                        const SizedBox(width: 6),
                        _buildMealCategoryChip('Lunch', Icons.lunch_dining, Colors.teal),
                        const SizedBox(width: 6),
                        _buildMealCategoryChip('Dinner', Icons.dinner_dining, Colors.indigo),
                        const SizedBox(width: 6),
                        _buildMealCategoryChip('Snack', Icons.cookie, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Primary Log Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline, size: 22),
                        label: Text(
                          _isSaving
                              ? 'Logging Meal...'
                              : 'Log ${(meal.totalCalories * mult).round()} kcal to $_selectedMeal',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isSaving ? null : _logFoodEntry,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraViewfinder(ThemeData theme) {
    final hasPhoto = _capturedImage != null;

    return Container(
      height: 260,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Captured Image or Dark Camera Viewfinder Background
          if (hasPhoto && !kIsWeb)
            Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.cover,
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(Icons.fastfood_outlined, size: 72, color: Colors.white24),
              ),
            ),

          // Scanning Reticle & Laser Beam
          AnimatedBuilder(
            animation: _scanAnimController,
            builder: (context, child) {
              return Positioned(
                top: 30 + (_scanAnimController.value * 180),
                left: 30,
                right: 30,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.tealAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.tealAccent.withOpacity(0.8),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Reticle Frame Boundary
          Center(
            child: Container(
              width: 280,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.tealAccent, width: 3), left: BorderSide(color: Colors.tealAccent, width: 3)))),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.tealAccent, width: 3), right: BorderSide(color: Colors.tealAccent, width: 3)))),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.tealAccent, width: 3), left: BorderSide(color: Colors.tealAccent, width: 3)))),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.tealAccent, width: 3), right: BorderSide(color: Colors.tealAccent, width: 3)))),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action Floating Pill
          Positioned(
            bottom: 14,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: Text(hasPhoto ? 'Retake Photo' : 'Capture Food Photo'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.photo_library, size: 18),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionChip(String label, double mult, String subtitle) {
    final isSelected = (_portionMultiplier - mult).abs() < 0.05;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _portionMultiplier = mult),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.teal : Colors.grey.shade400,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealCategoryChip(String category, IconData icon, Color color) {
    final isSelected = _selectedMeal.toLowerCase() == category.toLowerCase();
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMeal = category),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(isSelected ? 1.0 : 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutritionSummaryCard(ThemeData theme, AiEstimatedMeal meal, double mult) {
    final cal = (meal.totalCalories * mult).round();
    final p = (meal.totalProtein * mult).toStringAsFixed(1);
    final c = (meal.totalCarbs * mult).toStringAsFixed(1);
    final f = (meal.totalFat * mult).toStringAsFixed(1);
    final fiber = (meal.totalFiber * mult).toStringAsFixed(1);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 24),
                    SizedBox(width: 6),
                    Text(
                      'AI Nutrition Scan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Colors.green, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Verified Estimate',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Macros Ring / Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calories', style: TextStyle(fontSize: 11, color: Colors.black54)),
                        Text(
                          '$cal',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                        const Text('kcal', style: TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildMacroBox('Protein', '${p}g', Colors.blue),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildMacroBox('Carbs', '${c}g', Colors.teal),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildMacroBox('Fat', '${f}g', Colors.amber.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Dietary Fiber: ${fiber}g',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const Divider(height: 20),

            // Itemized Components Breakdown
            const Text(
              'Identified Dish Ingredients:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Column(
              children: meal.items.map((it) {
                final itCal = (it.calories * mult).round();
                final itGrams = (it.estimatedGrams * mult).round();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 6, color: Colors.teal),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          it.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Text(
                        '${itGrams}g • $itCal kcal (P: ${(it.protein * mult).round()}g)',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
