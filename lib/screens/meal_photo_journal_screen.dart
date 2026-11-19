import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import 'food_scanner_screen.dart';

class MealJournalItem {
  final int id;
  final String date;
  final String time;
  final String mealLabel;
  final String foodName;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? imagePath;

  const MealJournalItem({
    required this.id,
    required this.date,
    required this.time,
    required this.mealLabel,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.imagePath,
  });
}

class MealPhotoJournalScreen extends StatefulWidget {
  const MealPhotoJournalScreen({super.key});

  @override
  State<MealPhotoJournalScreen> createState() => _MealPhotoJournalScreenState();
}

class _MealPhotoJournalScreenState extends State<MealPhotoJournalScreen> {
  List<MealJournalItem> _items = [];
  bool _isLoading = true;
  String _filterLabel = 'All';

  @override
  void initState() {
    super.initState();
    _loadJournal();
  }

  Future<void> _loadJournal() async {
    setState(() => _isLoading = true);
    final db = await AppDb.instance.db;

    final rows = await db.rawQuery('''
      SELECT id, date, time, label, food_name, manual_name, grams,
             calories_100, manual_kcal,
             protein_100, manual_protein,
             carbs_100, manual_carbs,
             fat_100, manual_fat,
             image_path
      FROM log_entries
      ORDER BY date DESC, time DESC, id DESC
      LIMIT 100
    ''');

    final list = rows.map((r) {
      final name = (r['food_name'] as String?) ?? (r['manual_name'] as String?) ?? 'Meal Entry';
      final g = ((r['grams'] as num?) ?? 100).toDouble();
      final factor = g / 100.0;
      final cal = ((r['calories_100'] as num?)?.toDouble() ?? (r['manual_kcal'] as num?)?.toDouble() ?? 0.0) * factor;
      final p = ((r['protein_100'] as num?)?.toDouble() ?? (r['manual_protein'] as num?)?.toDouble() ?? 0.0) * factor;
      final c = ((r['carbs_100'] as num?)?.toDouble() ?? (r['manual_carbs'] as num?)?.toDouble() ?? 0.0) * factor;
      final f = ((r['fat_100'] as num?)?.toDouble() ?? (r['manual_fat'] as num?)?.toDouble() ?? 0.0) * factor;

      return MealJournalItem(
        id: (r['id'] as num).toInt(),
        date: (r['date'] as String?) ?? '',
        time: (r['time'] as String?) ?? '',
        mealLabel: (r['label'] as String?) ?? 'Snack',
        foodName: name,
        grams: g,
        calories: cal,
        protein: p,
        carbs: c,
        fat: f,
        imagePath: r['image_path'] as String?,
      );
    }).toList();

    if (!mounted) return;
    setState(() {
      _items = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filterLabel == 'All'
        ? _items
        : _items.where((i) => i.mealLabel.toLowerCase().contains(_filterLabel.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Visual Meal Journal'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'].map((lbl) {
                      final isSelected = _filterLabel == lbl;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(lbl),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _filterLabel = lbl);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1),

                // Journal Timeline List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.photo_library_outlined, size: 48, color: theme.hintColor),
                              const SizedBox(height: 12),
                              Text(
                                'No meal logs found for this filter.',
                                style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, idx) {
                            final item = filtered[idx];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    if (item.imagePath != null && item.imagePath!.isNotEmpty && !kIsWeb && File(item.imagePath!).existsSync())
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          File(item.imagePath!),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: _mealColor(item.mealLabel).withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _mealIcon(item.mealLabel),
                                          color: _mealColor(item.mealLabel),
                                          size: 28,
                                        ),
                                      ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: _mealColor(item.mealLabel).withAlpha(20),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.mealLabel,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: _mealColor(item.mealLabel),
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${item.date.substring(5)}${item.time.isNotEmpty ? " • ${item.time}" : ""}',
                                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            item.foodName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'P: ${item.protein.round()}g • C: ${item.carbs.round()}g • F: ${item.fat.round()}g',
                                            style: TextStyle(fontSize: 11, color: theme.hintColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${item.calories.round()}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        Text(
                                          'kcal',
                                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: const Text('Scan Food Photo'),
        onPressed: () async {
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodScannerScreen(
                date: todayStr,
                onLogged: _loadJournal,
              ),
            ),
          );
          _loadJournal();
        },
      ),
    );
  }

  Color _mealColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('breakfast')) return Colors.orange;
    if (l.contains('lunch')) return Colors.teal;
    if (l.contains('dinner')) return Colors.indigo;
    return Colors.purple;
  }

  IconData _mealIcon(String label) {
    final l = label.toLowerCase();
    if (l.contains('breakfast')) return Icons.free_breakfast;
    if (l.contains('lunch')) return Icons.lunch_dining;
    if (l.contains('dinner')) return Icons.dinner_dining;
    return Icons.cookie;
  }
}
