import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/barcode_service.dart';
import 'food_scanner_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(BarcodeProduct product, double grams, String mealCategory) onAddProduct;

  const BarcodeScannerScreen({
    super.key,
    required this.onAddProduct,
  });

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '100');

  bool _isTorchOn = false;
  bool _isLoading = false;
  String? _errorMessage;
  BarcodeProduct? _scannedProduct;
  String _selectedMeal = 'Lunch';

  final List<Map<String, String>> _sampleBarcodes = [
    {'name': 'Nutella', 'code': '3017620422003'},
    {'name': 'Rolled Oats', 'code': '7311070005700'},
    {'name': 'Coca-Cola', 'code': '5449000000996'},
    {'name': 'Greek Yogurt', 'code': '5201051001079'},
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _codeController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _performLookup(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _scannedProduct = null;
    });

    try {
      final product = await BarcodeService.instance.lookupBarcode(cleanCode);
      if (!mounted) return;
      if (product != null) {
        setState(() {
          _scannedProduct = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No product found for barcode $cleanCode in OpenFoodFacts.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error looking up barcode: $e';
        _isLoading = false;
      });
    }
  }

  void _confirmAdd() {
    final product = _scannedProduct;
    if (product == null) return;
    final grams = double.tryParse(_amountController.text) ?? 100.0;
    widget.onAddProduct(product, grams, _selectedMeal);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.teal),
            label: const Text('Scan Plate', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.bold)),
            onPressed: () {
              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodScannerScreen(
                    date: todayStr,
                    onLogged: () {},
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            tooltip: 'Flashlight Toggle',
            onPressed: () {
              setState(() {
                _isTorchOn = !_isTorchOn;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isTorchOn ? 'Flashlight ON' : 'Flashlight OFF'),
                  duration: const Duration(milliseconds: 700),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Viewfinder Area
            Container(
              height: 260,
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated laser line
                  AnimatedBuilder(
                    animation: _animController,
                    builder: (context, child) {
                      return Positioned(
                        top: 40 + (_animController.value * 160),
                        child: Container(
                          width: 240,
                          height: 2,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withAlpha(150),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Reticle frame
                  Container(
                    width: 250,
                    height: 170,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    child: Text(
                      'Align barcode within frame to scan',
                      style: TextStyle(
                        color: Colors.white.withAlpha(200),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barcode Entry & Presets
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Enter or scan barcode number',
                            hintText: 'e.g. 3017620422003',
                            prefixIcon: const Icon(Icons.qr_code_scanner),
                            suffixIcon: _isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: () => _performLookup(_codeController.text),
                                  ),
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: _performLookup,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Quick Test Samples:',
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: _sampleBarcodes.map((item) {
                      return ActionChip(
                        avatar: const Icon(Icons.bolt, size: 16),
                        label: Text(item['name']!),
                        onPressed: () {
                          _codeController.text = item['code']!;
                          _performLookup(item['code']!);
                        },
                      );
                    }).toList(),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Product Result Card
                  if (_scannedProduct != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: theme.colorScheme.primaryContainer,
                                  child: Icon(Icons.check, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _scannedProduct!.name,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_scannedProduct!.brand.isNotEmpty)
                                        Text(
                                          'Brand: ${_scannedProduct!.brand}',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.hintColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            // Nutrients per 100g
                            Text(
                              'Nutritional values (per 100g):',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _nutrientStat('Calories', '${_scannedProduct!.calories100.round()} kcal', theme),
                                _nutrientStat('Protein', '${_scannedProduct!.protein100.toStringAsFixed(1)}g', theme),
                                _nutrientStat('Carbs', '${_scannedProduct!.carbs100.toStringAsFixed(1)}g', theme),
                                _nutrientStat('Fat', '${_scannedProduct!.fat100.toStringAsFixed(1)}g', theme),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Portion and Meal category
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Serving Amount',
                                      suffixText: 'g',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedMeal,
                                    decoration: const InputDecoration(
                                      labelText: 'Meal Type',
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
                                    onChanged: (val) {
                                      if (val != null) setState(() => _selectedMeal = val);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Add to Food Diary'),
                                onPressed: _confirmAdd,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutrientStat(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: theme.hintColor, fontSize: 10)),
      ],
    );
  }
}
