import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/grocery_list_service.dart';

class GroceryListScreen extends StatefulWidget {
  const GroceryListScreen({super.key});

  @override
  State<GroceryListScreen> createState() => _GroceryListScreenState();
}

class _GroceryListScreenState extends State<GroceryListScreen> {
  final GroceryListService _service = GroceryListService.instance;
  List<GroceryItem> _items = [];
  bool _isLoading = true;

  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    final list = await _service.getItems();
    if (mounted) {
      setState(() {
        _items = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddDialog() async {
    _itemController.clear();
    _qtyController.clear();
    String selectedCategory = 'Produce & Greens';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Add Grocery Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _itemController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Item name',
                  hintText: 'e.g. Organic Eggs, Oats',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: 'Quantity / Weight',
                  hintText: 'e.g. 1 dozen, 500g',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Produce & Greens', child: Text('Produce & Greens')),
                  DropdownMenuItem(value: 'Meat, Seafood & Eggs', child: Text('Meat, Seafood & Eggs')),
                  DropdownMenuItem(value: 'Dairy & Refrigerated', child: Text('Dairy & Refrigerated')),
                  DropdownMenuItem(value: 'Grains & Bakery', child: Text('Grains & Bakery')),
                  DropdownMenuItem(value: 'Pantry & Spices', child: Text('Pantry & Spices')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedCategory = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = _itemController.text.trim();
                if (name.isNotEmpty) {
                  await _service.addItem(name, quantity: _qtyController.text.trim(), category: selectedCategory);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadItems();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importToday() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final count = await _service.importFromDiaryDate(todayStr);
    _loadItems();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(count > 0 ? 'Imported $count ingredients from today’s diary!' : 'No new ingredients found in today’s diary.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group items by category
    final Map<String, List<GroceryItem>> grouped = {};
    for (final it in _items) {
      grouped.putIfAbsent(it.category, () => []).add(it);
    }

    final hasChecked = _items.any((i) => i.isChecked);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Grocery Checklist'),
        actions: [
          IconButton(
            tooltip: 'Import from Today’s Meals',
            icon: const Icon(Icons.sync_alt),
            onPressed: _importToday,
          ),
          if (hasChecked)
            IconButton(
              tooltip: 'Clear completed items',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                await _service.clearChecked();
                _loadItems();
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_basket_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Your grocery list is empty!', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Add items manually or import directly from today’s meals.', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _importToday,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Today’s Ingredients'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    ...grouped.entries.map((entry) {
                      final category = entry.key;
                      final items = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(category), size: 18, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  category,
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 6),
                                Text('(${items.length})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
                            ),
                            child: Column(
                              children: items.map((it) {
                                return CheckboxListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  dense: true,
                                  title: Text(
                                    it.name,
                                    style: TextStyle(
                                      decoration: it.isChecked ? TextDecoration.lineThrough : null,
                                      color: it.isChecked ? Colors.grey : null,
                                      fontWeight: it.isChecked ? FontWeight.normal : FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: it.quantity.isNotEmpty
                                      ? Text(it.quantity, style: TextStyle(color: Colors.grey.shade600, fontSize: 11))
                                      : null,
                                  value: it.isChecked,
                                  onChanged: (_) async {
                                    await _service.toggleItem(it.id);
                                    _loadItems();
                                  },
                                  secondary: IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                    onPressed: () async {
                                      await _service.deleteItem(it.id);
                                      _loadItems();
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Item'),
      ),
    );
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'Produce & Greens':
        return Icons.eco;
      case 'Meat, Seafood & Eggs':
        return Icons.kebab_dining;
      case 'Dairy & Refrigerated':
        return Icons.egg_outlined;
      case 'Grains & Bakery':
        return Icons.bakery_dining;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
