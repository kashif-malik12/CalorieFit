// lib/main.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqflite.dart' as common;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data/db.dart';
import 'data/models.dart';
import 'services/food_search.dart';
import 'settings/target_settings.dart';
import 'settings/retention_settings.dart';

const bool kResetOnStartup = false;
const String kBrandMarkAsset = 'assets/branding/caloriefit_mark.png';
const String kBrandLogoAsset = 'assets/branding/caloriefit_logo.png';
const Color kBrandPrimary = Color(0xFF0B3C49);
const Color kBrandAccent = Color(0xFF3AC47D);
const Color kBrandSurface = Color(0xFFF4FBF7);
const String kPrivacyPolicyLastUpdated = '2026-04-02';
const String kPrivacyPolicyContactName = 'Tradister';
const String kPrivacyPolicyContactEmail = 'admin@tradister.com';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    common.databaseFactory = databaseFactoryFfiWeb;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux) {
    sqfliteFfiInit();
    common.databaseFactory = databaseFactoryFfi;
  } else {
    common.databaseFactory = sqflite.databaseFactory;
  }

  await AppDb.instance.db;
//  await AppDb.instance.reseedSystemLibrary();

  runApp(const CalorieFitApp());
}

class CalorieFitApp extends StatelessWidget {
  const CalorieFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CalorieFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: kBrandPrimary,
        scaffoldBackgroundColor: kBrandSurface,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kBrandPrimary,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      home: const InitGate(),
    );
  }
}

class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        kBrandMarkAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class BrandedAppBarTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BrandedAppBarTitle({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 30),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle ?? 'CalorieFit',
              style: textTheme.labelMedium?.copyWith(
                color: kBrandPrimary.withValues(alpha: 0.72),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class InitGate extends StatefulWidget {
  const InitGate({super.key});

  @override
  State<InitGate> createState() => _InitGateState();
}

class _InitGateState extends State<InitGate> {
  late final Future<void> _initFuture = _init();

  Future<void> _init() async {
    try {
      if (kResetOnStartup) {
        await AppDb.instance.resetDb();
        await TargetSettings.resetAllTargets();
      }

      await AppDb.instance.db;

      final days = await RetentionSettings.getRetentionDays();
      await AppDb.instance.purgeDataOlderThanDays(days);
    } catch (e, st) {
      throw Exception('$e\n\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(kBrandLogoAsset, width: 220),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Startup Error')),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText('App failed to start:\n\n${snap.error}'),
            ),
          );
        }

        return const HomeShell();
      },
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _idx = 0;

  void _onNavTap(int i) => setState(() => _idx = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(navIndex: 0, onNavTap: _onNavTap),
      FoodsPage(navIndex: 1, onNavTap: _onNavTap),
      GlobalPage(navIndex: 2, onNavTap: _onNavTap),
    ];

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DrawerHeader(
                child: Text(
                  'CalorieFit',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ask Question'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _UpcomingFeaturePage(title: 'Ask Question'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Join Group Classes'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _UpcomingFeaturePage(title: 'Join Group Classes'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_search_outlined),
                title: const Text('Find Personal Coach'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _UpcomingFeaturePage(title: 'Find Personal Coach'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy Policy'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const _PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: pages[_idx],
    );
  }
}

// ---------------- Shared helpers ----------------

String _fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

Widget _bottomNav(int currentIndex, void Function(int) onTap) {
  return NavigationBar(
    selectedIndex: currentIndex,
    onDestinationSelected: onTap,
    destinations: const [
      NavigationDestination(icon: Icon(Icons.today), label: 'Daily Log'),
      NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'My Foods'),
      NavigationDestination(icon: Icon(Icons.menu_book), label: 'Library'),
    ],
  );
}

const _kMealCategories = [
  'Breakfast',
  'Morning Snack',
  'Lunch',
  'Afternoon Snack',
  'Dinner',
  'Post Dinner Snack',
];

String _baseLabel(Food f) {
  final u = f.unit;
  final b = f.baseAmount;
  return 'per ${b.toStringAsFixed(b == b.roundToDouble() ? 0 : 1)} $u';
}

String _numStr(double v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1);

String _macroLine({
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
}) {
  return '${calories.toStringAsFixed(0)} kcal | '
      'P ${_numStr(protein)}g | '
      'C ${_numStr(carbs)}g | '
      'F ${_numStr(fat)}g';
}

String _microLine({
  required double fiber,
  required double sugar,
  required double sodium,
}) {
  return 'Fi ${_numStr(fiber)}g | '
      'Su ${_numStr(sugar)}g | '
      'Na ${_numStr(sodium)}mg';
}

String _fatDetailLine({
  required double saturatedFat,
  required double transFat,
  required double cholesterol,
}) {
  return 'Sat ${_numStr(saturatedFat)}g | '
      'Trans ${_numStr(transFat)}g | '
      'Chol ${_numStr(cholesterol)}mg';
}

String _foodListSubtitle(Food f, {String? extra}) {
  final lines = <String>[
    '${_baseLabel(f)}${extra != null && extra.isNotEmpty ? ' | $extra' : ''}',
    _macroLine(
      calories: f.calories,
      protein: f.protein,
      carbs: f.carbs,
      fat: f.fat,
    ),
  ];
  return lines.join('\n');
}

String _templateListSubtitle({
  required String label,
  required double calories,
  required double protein,
  required double carbs,
  required double fat,
  bool isDefaultLabel = false,
  String? ingredientsPreview,
}) {
  final labelText = isDefaultLabel ? 'Default label: $label' : 'Label: $label';

  final lines = <String>[
    labelText,
    _macroLine(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
    ),
    if (ingredientsPreview != null && ingredientsPreview.trim().isNotEmpty)
      ingredientsPreview.trim(),
  ];

  return lines.join('\n');
}

String _logSubtitleFromRow(Map<String, Object?> r) {
  final entryType = (r['entry_type'] as String?) ?? 'food';

  final time = (r['time'] as String?)?.trim();
  final label = (r['label'] as String?)?.trim();

  final metaParts = <String>[
    if (time != null && time.isNotEmpty) time,
    if (label != null && label.isNotEmpty) label,
  ];
  final meta = metaParts.join(' | ');

  if (entryType == 'manual') {
    final kcal = ((r['calories'] as num?) ?? 0).toDouble();
    final protein = ((r['protein'] as num?) ?? 0).toDouble();
    final carbs = ((r['carbs'] as num?) ?? 0).toDouble();
    final fat = ((r['fat'] as num?) ?? 0).toDouble();
    final fiber = ((r['fiber'] as num?) ?? 0).toDouble();
    final sugar = ((r['sugar'] as num?) ?? 0).toDouble();
    final sodium = ((r['sodium'] as num?) ?? 0).toDouble();
    final cholesterol = ((r['cholesterol'] as num?) ?? 0).toDouble();
    final saturatedFat = ((r['saturated_fat'] as num?) ?? 0).toDouble();
    final transFat = ((r['trans_fat'] as num?) ?? 0).toDouble();

    final lines = <String>[
      if (meta.isNotEmpty) meta,
      _macroLine(
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
      _microLine(
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
      ),
      _fatDetailLine(
        saturatedFat: saturatedFat,
        transFat: transFat,
        cholesterol: cholesterol,
      ),
    ];
    return lines.join('\n');
  } else {
    final amount = ((r['grams'] as num?) ?? 0).toDouble();
    final unit = (r['unit'] as String?)?.trim().isNotEmpty == true ? (r['unit'] as String) : 'g';
    final baseAmount = ((r['base_amount'] as num?) ?? 100).toDouble();
    final safeBase = baseAmount <= 0 ? 1.0 : baseAmount;
    final factor = amount / safeBase;

    final kcalPerBase = ((r['calories'] as num?) ?? 0).toDouble();
    final proteinPerBase = ((r['protein'] as num?) ?? 0).toDouble();
    final carbsPerBase = ((r['carbs'] as num?) ?? 0).toDouble();
    final fatPerBase = ((r['fat'] as num?) ?? 0).toDouble();

    final kcal = kcalPerBase * factor;
    final protein = proteinPerBase * factor;
    final carbs = carbsPerBase * factor;
    final fat = fatPerBase * factor;
    final fiber = (((r['fiber'] as num?) ?? 0).toDouble()) * factor;
    final sugar = (((r['sugar'] as num?) ?? 0).toDouble()) * factor;
    final sodium = (((r['sodium'] as num?) ?? 0).toDouble()) * factor;
    final cholesterol =
        (((r['cholesterol'] as num?) ?? 0).toDouble()) * factor;
    final saturatedFat =
        (((r['saturated_fat'] as num?) ?? 0).toDouble()) * factor;
    final transFat = (((r['trans_fat'] as num?) ?? 0).toDouble()) * factor;

    final amountStr = amount.toStringAsFixed(amount == amount.roundToDouble() ? 0 : 1);

    final lines = <String>[
      if (meta.isNotEmpty) meta,
      '$amountStr $unit',
      _macroLine(
        calories: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
      ),
      _microLine(
        fiber: fiber,
        sugar: sugar,
        sodium: sodium,
      ),
      _fatDetailLine(
        saturatedFat: saturatedFat,
        transFat: transFat,
        cholesterol: cholesterol,
      ),
    ];
    return lines.join('\n');
  }
}

Future<void> _showTodayEntryDetails(
  BuildContext context,
  Map<String, Object?> row,
) async {
  final entryType = (row['entry_type'] as String?) ?? 'food';
  final name = (row['name'] as String?) ?? 'Unknown';
  final time = (row['time'] as String?)?.trim();
  final label = (row['label'] as String?)?.trim();
  final calories = ((row['calories'] as num?) ?? 0).toDouble();
  final protein = ((row['protein'] as num?) ?? 0).toDouble();
  final carbs = ((row['carbs'] as num?) ?? 0).toDouble();
  final fat = ((row['fat'] as num?) ?? 0).toDouble();
  final fiber = ((row['fiber'] as num?) ?? 0).toDouble();
  final sugar = ((row['sugar'] as num?) ?? 0).toDouble();
  final sodium = ((row['sodium'] as num?) ?? 0).toDouble();
  final cholesterol = ((row['cholesterol'] as num?) ?? 0).toDouble();
  final saturatedFat = ((row['saturated_fat'] as num?) ?? 0).toDouble();
  final transFat = ((row['trans_fat'] as num?) ?? 0).toDouble();
  List<Map<String, Object?>> templateItems = const [];

  if (entryType == 'manual') {
    final template = await AppDb.instance.getUserMealTemplateByExactName(name);
    if (template?.id != null) {
      templateItems = await AppDb.instance.getMealTemplateItemsJoined(
        template!.id!,
      );
    }
  }

  String amountLabel() {
    if (entryType == 'manual') {
      return templateItems.isNotEmpty
          ? 'Entry type: template summary'
          : 'Entry type: manual summary';
    }
    final amount = ((row['grams'] as num?) ?? 0).toDouble();
    final unit =
        (row['unit'] as String?)?.trim().isNotEmpty == true
            ? (row['unit'] as String)
            : 'g';
    return 'Amount: ${_numStr(amount)} $unit';
  }

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder:
        (ctx) => SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if ((time != null && time.isNotEmpty) ||
                              (label != null && label.isNotEmpty))
                            Text(
                              [
                                if (time != null && time.isNotEmpty) time,
                                if (label != null && label.isNotEmpty) label,
                              ].join(' | '),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            amountLabel(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Nutrition summary',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(_macroLine(
                                    calories: calories,
                                    protein: protein,
                                    carbs: carbs,
                                    fat: fat,
                                  )),
                                  const SizedBox(height: 6),
                                  Text(_microLine(
                                    fiber: fiber,
                                    sugar: sugar,
                                    sodium: sodium,
                                  )),
                                  const SizedBox(height: 6),
                                  Text(_fatDetailLine(
                                    saturatedFat: saturatedFat,
                                    transFat: transFat,
                                    cholesterol: cholesterol,
                                  )),
                                ],
                              ),
                            ),
                          ),
                          if (templateItems.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Foods in template',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...templateItems.map((item) {
                                      final foodName =
                                          (item['food_name'] as String?) ??
                                          'Unknown';
                                      final amount =
                                          ((item['amount'] as num?) ?? 0)
                                              .toDouble();
                                      final unit =
                                          (item['unit'] as String?) ?? 'g';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          '${_numStr(amount)} $unit | $foodName',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
  );
}

DataRow _macroRow(String name, double taken, int target, String unit) {
  final bal = target - taken;
  String fmt(double x) => x.toStringAsFixed(1);

  final takenStr = (name == 'Calories') ? taken.round().toString() : fmt(taken);
  final balStr = (name == 'Calories')
      ? (bal >= 0 ? '+${bal.round()}' : '-${(-bal).round()}')
      : (bal >= 0 ? '+${fmt(bal)}' : '-${fmt(-bal)}');

  return DataRow(
    cells: [
      DataCell(Text(name)),
      DataCell(Text(takenStr)),
      DataCell(Text('$target')),
      DataCell(Text(balStr)),
      DataCell(Text(unit)),
    ],
  );
}

Widget _progressBarCalories({
  required int taken,
  required int target,
  required DayTotals totals,
  required MacroTargets targets,
}) {
  final safeTarget = target <= 0 ? 1 : target;
  final progress = (taken / safeTarget).clamp(0.0, 1.0);
  final over = taken - safeTarget;

  Widget macroBar({
    required String label,
    required double value,
    required double targetVal,
    required Color color,
    String unit = 'g',
  }) {
    final safeT = targetVal <= 0 ? 1.0 : targetVal;
    final p = (value / safeT).clamp(0.0, 1.0);
    final valStr = value.toStringAsFixed(0);
    final tgtStr = targetVal.toStringAsFixed(0);
    return Row(
      children: [
        SizedBox(
          width: 14,
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 6,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$valStr/$tgtStr $unit',
          style: const TextStyle(fontSize: 11, color: Colors.black54),
        ),
      ],
    );
  }

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(
                over <= 0 ? '${safeTarget - taken} kcal left' : '$over kcal over',
                style: TextStyle(
                  fontSize: 13,
                  color: over <= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$taken kcal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('/ $safeTarget', style: const TextStyle(fontSize: 14, color: Colors.black45)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress, minHeight: 10),
          ),
          const SizedBox(height: 14),
          macroBar(
            label: 'P',
            value: totals.protein,
            targetVal: targets.protein.toDouble(),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 6),
          macroBar(
            label: 'C',
            value: totals.carbs,
            targetVal: targets.carbs.toDouble(),
            color: const Color(0xFF2196F3),
          ),
          const SizedBox(height: 6),
          macroBar(
            label: 'F',
            value: totals.fat,
            targetVal: targets.fat.toDouble(),
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(height: 6),
          macroBar(
            label: 'Fi',
            value: totals.fiber,
            targetVal: targets.fiber.toDouble(),
            color: const Color(0xFF8BC34A),
          ),
          const SizedBox(height: 6),
          macroBar(
            label: 'S',
            value: totals.sugar,
            targetVal: targets.sugar.toDouble(),
            color: const Color(0xFFE91E63),
          ),
          const SizedBox(height: 6),
          macroBar(
            label: 'Na',
            value: totals.sodium,
            targetVal: targets.sodium.toDouble(),
            color: const Color(0xFF9C27B0),
            unit: 'mg',
          ),
        ],
      ),
    ),
  );
}

List<Widget> _buildCategorizedLog(
  BuildContext context,
  List<Map<String, Object?>> rows,
  VoidCallback onDelete,
) {
  // Group rows by label; rows are already sorted by time from the DB
  final Map<String, List<Map<String, Object?>>> grouped = {};
  for (final r in rows) {
    final label = (r['label'] as String?)?.trim();
    final key = (label != null && label.isNotEmpty) ? label : 'Other';
    grouped.putIfAbsent(key, () => []).add(r);
  }

  final result = <Widget>[];

  void addSection(String cat) {
    final entries = grouped[cat];
    if (entries == null || entries.isEmpty) return;

    result.add(Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Row(
        children: [
          Text(
            cat,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(thickness: 1)),
        ],
      ),
    ));

    for (final r in entries) {
      final logId = r['log_id'] as int;
      final name = (r['name'] as String?) ?? 'Unknown';
      final subtitle = _logSubtitleFromRow(r);
      result.add(Card(
        child: ListTile(
          isThreeLine: true,
          title: Text(name),
          subtitle: Text(subtitle),
          onTap: () => _showTodayEntryDetails(context, r),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await AppDb.instance.deleteLog(logId);
              onDelete();
            },
          ),
        ),
      ));
    }
  }

  for (final cat in _kMealCategories) {
    addSection(cat);
  }
  // Any entry with an unrecognised or missing label
  addSection('Other');

  return result;
}

Widget _targetsTable({required DayTotals totals, required MacroTargets targets}) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Taken vs Target', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('Taken')),
                DataColumn(label: Text('Target')),
                DataColumn(label: Text('Balance')),
                DataColumn(label: Text('Unit')),
              ],
              rows: [
                _macroRow('Calories', totals.calories, targets.calories, 'kcal'),
                _macroRow('Protein', totals.protein, targets.protein, 'g'),
                _macroRow('Carbs', totals.carbs, targets.carbs, 'g'),
                _macroRow('Fat', totals.fat, targets.fat, 'g'),
                _macroRow('Fiber', totals.fiber, targets.fiber, 'g'),
                _macroRow('Sugar', totals.sugar, targets.sugar, 'g'),
                _macroRow('Sodium', totals.sodium, targets.sodium, 'mg'),
                _macroRow('Cholesterol', totals.cholesterol, targets.cholesterol, 'mg'),
                _macroRow('Saturated fat', totals.saturatedFat, targets.saturatedFat, 'g'),
                _macroRow('Trans fat', totals.transFat, targets.transFat, 'g'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------- Retention dialog ----------------

Future<void> editRetentionDaysDialog(BuildContext context) async {
  final current = await RetentionSettings.getRetentionDays();
  final ctrl = TextEditingController(text: current.toString());

  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Data retention'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How many days should the app keep your history?'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Days to keep',
              helperText: 'Min 7, max 3650',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );

  if (ok != true) return;

  final days = int.tryParse(ctrl.text.trim()) ?? current;
  await RetentionSettings.setRetentionDays(days);

  final deleted = await AppDb.instance.purgeDataOlderThanDays(days);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved. Deleted $deleted old entries.')),
    );
  }
}

// ---------------- Targets dialogs ----------------

Future<void> editDefaultTargetsOneDialog(BuildContext context) async {
  final c = await TargetSettings.getCalories();
  final p = await TargetSettings.getProtein();
  final cb = await TargetSettings.getCarbs();
  final f = await TargetSettings.getFat();
  final fi = await TargetSettings.getFiber();
  final su = await TargetSettings.getSugar();
  final so = await TargetSettings.getSodium();
  final ch = await TargetSettings.getCholesterol();
  final sf = await TargetSettings.getSaturatedFat();
  final tf = await TargetSettings.getTransFat();

  final cCtrl = TextEditingController(text: c.toString());
  final pCtrl = TextEditingController(text: p.toString());
  final cbCtrl = TextEditingController(text: cb.toString());
  final fCtrl = TextEditingController(text: f.toString());
  final fiCtrl = TextEditingController(text: fi.toString());
  final suCtrl = TextEditingController(text: su.toString());
  final soCtrl = TextEditingController(text: so.toString());
  final chCtrl = TextEditingController(text: ch.toString());
  final sfCtrl = TextEditingController(text: sf.toString());
  final tfCtrl = TextEditingController(text: tf.toString());

  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Default targets'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: cCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
            TextField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)')),
            TextField(controller: cbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)')),
            TextField(controller: fCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)')),
            TextField(controller: fiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fiber (g)')),
            TextField(controller: suCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sugar (g)')),
            TextField(controller: soCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sodium (mg)')),
            TextField(controller: chCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cholesterol (mg)')),
            TextField(controller: sfCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Saturated fat (g)')),
            TextField(controller: tfCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trans fat (g)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );

  if (res != true) return;

  int parse(TextEditingController t) => int.tryParse(t.text.trim()) ?? 0;

  await TargetSettings.setCalories(parse(cCtrl));
  await TargetSettings.setProtein(parse(pCtrl));
  await TargetSettings.setCarbs(parse(cbCtrl));
  await TargetSettings.setFat(parse(fCtrl));
  await TargetSettings.setFiber(parse(fiCtrl));
  await TargetSettings.setSugar(parse(suCtrl));
  await TargetSettings.setSodium(parse(soCtrl));
  await TargetSettings.setCholesterol(parse(chCtrl));
  await TargetSettings.setSaturatedFat(parse(sfCtrl));
  await TargetSettings.setTransFat(parse(tfCtrl));

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default targets saved')));
  }
}

Future<void> editTargetsForDateOneDialog(BuildContext context, String date) async {
  final cur = await AppDb.instance.getTargetsForDate(date);

  final cCtrl = TextEditingController(text: cur.calories.toString());
  final pCtrl = TextEditingController(text: cur.protein.toString());
  final cbCtrl = TextEditingController(text: cur.carbs.toString());
  final fCtrl = TextEditingController(text: cur.fat.toString());
  final fiCtrl = TextEditingController(text: cur.fiber.toString());
  final suCtrl = TextEditingController(text: cur.sugar.toString());
  final soCtrl = TextEditingController(text: cur.sodium.toString());
  final chCtrl = TextEditingController(text: cur.cholesterol.toString());
  final sfCtrl = TextEditingController(text: cur.saturatedFat.toString());
  final tfCtrl = TextEditingController(text: cur.transFat.toString());

  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Targets for $date'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: cCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
            TextField(controller: pCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)')),
            TextField(controller: cbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)')),
            TextField(controller: fCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)')),
            TextField(controller: fiCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fiber (g)')),
            TextField(controller: suCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sugar (g)')),
            TextField(controller: soCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sodium (mg)')),
            TextField(controller: chCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Cholesterol (mg)')),
            TextField(controller: sfCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Saturated fat (g)')),
            TextField(controller: tfCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trans fat (g)')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
      ],
    ),
  );

  if (res != true) return;

  int parse(TextEditingController t) => int.tryParse(t.text.trim()) ?? 0;

  await AppDb.instance.setTargetsForDate(
    date,
    MacroTargets(
      calories: parse(cCtrl),
      protein: parse(pCtrl),
      carbs: parse(cbCtrl),
      fat: parse(fCtrl),
      fiber: parse(fiCtrl),
      sugar: parse(suCtrl),
      sodium: parse(soCtrl),
      cholesterol: parse(chCtrl),
      saturatedFat: parse(sfCtrl),
      transFat: parse(tfCtrl),
    ),
  );

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Targets saved for $date')));
  }
}

double _activityFactor(String value) {
  switch (value) {
    case 'Light':
      return 1.375;
    case 'Moderate':
      return 1.55;
    case 'Active':
      return 1.725;
    case 'Very active':
      return 1.9;
    case 'Sedentary':
    default:
      return 1.2;
  }
}

int _goalAdjustment(String value) {
  switch (value) {
    case 'Lose':
      return -400;
    case 'Gain':
      return 300;
    case 'Maintain':
    default:
      return 0;
  }
}

Future<void> showBmiAndCalorieToolsDialog(BuildContext context, String date) async {
  // Load existing extra targets so calculator doesn't wipe them
  final existingTargets = await AppDb.instance.getTargetsForDate(date);

  if (!context.mounted) return;

  final heightCtrl = TextEditingController(text: '170');
  final weightCtrl = TextEditingController(text: '70');
  final ageCtrl = TextEditingController(text: '30');
  final fiberCtrl = TextEditingController(text: existingTargets.fiber.toString());
  final sugarCtrl = TextEditingController(text: existingTargets.sugar.toString());
  final sodiumCtrl = TextEditingController(text: existingTargets.sodium.toString());
  final cholesterolCtrl = TextEditingController(
    text: existingTargets.cholesterol.toString(),
  );
  final saturatedFatCtrl = TextEditingController(
    text: existingTargets.saturatedFat.toString(),
  );
  final transFatCtrl = TextEditingController(
    text: existingTargets.transFat.toString(),
  );

  String sex = 'Male';
  String activity = 'Moderate';
  String goal = 'Maintain';

  double parseNum(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  int parseInt(TextEditingController c) =>
      int.tryParse(c.text.trim()) ?? 0;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setInner) {
        final heightCm = parseNum(heightCtrl);
        final weightKg = parseNum(weightCtrl);
        final age = parseInt(ageCtrl);

        final heightM = heightCm > 0 ? heightCm / 100 : 0;
        final bmi = (heightM > 0) ? (weightKg / (heightM * heightM)) : 0.0;

        String bmiText;
        if (bmi <= 0) {
          bmiText = '-';
        } else if (bmi < 18.5) {
          bmiText = 'Underweight';
        } else if (bmi < 25) {
          bmiText = 'Normal';
        } else if (bmi < 30) {
          bmiText = 'Overweight';
        } else {
          bmiText = 'Obesity';
        }

        double bmr = 0;
        if (heightCm > 0 && weightKg > 0 && age > 0) {
          if (sex == 'Male') {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
          } else {
            bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
          }
        }

        final tdee = bmr * _activityFactor(activity);
        final targetCalories = (tdee + _goalAdjustment(goal)).round();

        final protein =
            goal == 'Lose' ? (weightKg * 2.0).round() : (weightKg * 1.8).round();
        final fat = ((targetCalories * 0.25) / 9).round();
        final carbs = (((targetCalories - (protein * 4) - (fat * 9)) / 4))
            .clamp(0, 100000)
            .round();
        final fiber = parseInt(fiberCtrl);
        final sugar = parseInt(sugarCtrl);
        final sodium = parseInt(sodiumCtrl);
        final cholesterol = parseInt(cholesterolCtrl);
        final saturatedFat = parseInt(saturatedFatCtrl);
        final transFat = parseInt(transFatCtrl);

        return AlertDialog(
          title: const Text('BMI & calorie target'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)'),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  onChanged: (_) => setInner(() {}),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: sex,
                  decoration: const InputDecoration(labelText: 'Sex'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (v) => setInner(() => sex = v ?? 'Male'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: activity,
                  decoration: const InputDecoration(labelText: 'Activity'),
                  items: const [
                    DropdownMenuItem(value: 'Sedentary', child: Text('Sedentary')),
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Moderate', child: Text('Moderate')),
                    DropdownMenuItem(value: 'Active', child: Text('Active')),
                    DropdownMenuItem(value: 'Very active', child: Text('Very active')),
                  ],
                  onChanged: (v) => setInner(() => activity = v ?? 'Moderate'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: goal,
                  decoration: const InputDecoration(labelText: 'Goal'),
                  items: const [
                    DropdownMenuItem(value: 'Lose', child: Text('Lose')),
                    DropdownMenuItem(value: 'Maintain', child: Text('Maintain')),
                    DropdownMenuItem(value: 'Gain', child: Text('Gain')),
                  ],
                  onChanged: (v) => setInner(() => goal = v ?? 'Maintain'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: fiberCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Fiber target (g)'),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: sugarCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sugar target (g)'),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: sodiumCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Sodium target (mg)'),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: cholesterolCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cholesterol target (mg)',
                  ),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: saturatedFatCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Saturated fat target (g)',
                  ),
                  onChanged: (_) => setInner(() {}),
                ),
                TextField(
                  controller: transFatCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trans fat target (g)',
                  ),
                  onChanged: (_) => setInner(() {}),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('BMI: ${bmi > 0 ? bmi.toStringAsFixed(1) : '-'}'),
                        Text('BMI status: $bmiText'),
                        const SizedBox(height: 8),
                        Text('BMR: ${bmr > 0 ? bmr.toStringAsFixed(0) : '-'} kcal'),
                        Text('Estimated daily calories: ${targetCalories > 0 ? targetCalories : '-'} kcal'),
                        const SizedBox(height: 8),
                        Text('Protein target: ${protein > 0 ? protein : '-'} g'),
                        Text('Carbs target: ${carbs >= 0 ? carbs : '-'} g'),
                        Text('Fat target: ${fat > 0 ? fat : '-'} g'),
                        Text('Fiber target: $fiber g'),
                        Text('Sugar target: $sugar g'),
                        Text('Sodium target: $sodium mg'),
                        Text('Saturated fat target: $saturatedFat g'),
                        Text('Trans fat target: $transFat g'),
                        Text('Cholesterol target: $cholesterol mg'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () async {
                if (targetCalories <= 0) return;

                await TargetSettings.setCalories(targetCalories);
                await TargetSettings.setProtein(protein);
                await TargetSettings.setCarbs(carbs);
                await TargetSettings.setFat(fat);
                await TargetSettings.setFiber(fiber);
                await TargetSettings.setSugar(sugar);
                await TargetSettings.setSodium(sodium);
                await TargetSettings.setCholesterol(cholesterol);
                await TargetSettings.setSaturatedFat(saturatedFat);
                await TargetSettings.setTransFat(transFat);

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saved as default targets')),
                  );
                }
              },
              child: const Text('Save default'),
            ),
            FilledButton(
              onPressed: () async {
                if (targetCalories <= 0) return;

                await AppDb.instance.setTargetsForDate(
                  date,
                  MacroTargets(
                    calories: targetCalories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    fiber: fiber,
                    sugar: sugar,
                    sodium: sodium,
                    cholesterol: cholesterol,
                    saturatedFat: saturatedFat,
                    transFat: transFat,
                  ),
                  source: 'calculator',
                  calculatorJson: jsonEncode({
                    'height_cm': heightCm,
                    'weight_kg': weightKg,
                    'age': age,
                    'sex': sex,
                    'activity': activity,
                    'goal': goal,
                    'bmi': bmi,
                    'bmr': bmr,
                    'tdee': tdee,
                  }),
                );

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved targets for $date')),
                  );
                }
              },
              child: const Text('Save for this date'),
            ),
          ],
        );
      },
    ),
  );
}
// ---------------- TODAY ----------------

class TodayPage extends StatefulWidget {
  final int navIndex;
  final void Function(int) onNavTap;

  const TodayPage({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends State<TodayPage> {
  String _date = _fmtDate(DateTime.now());

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_date) ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDate: initial,
    );
    if (picked != null) setState(() => _date = _fmtDate(picked));
  }

  Future<void> _showAddMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Add', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Add from My Foods'),
              onTap: () => Navigator.pop(ctx, 'foods'),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on),
              title: const Text('Quick entry (one-time)'),
              onTap: () => Navigator.pop(ctx, 'quick'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: const Text('Add from My Templates'),
              onTap: () => Navigator.pop(ctx, 'templates'),
            ),
            ListTile(
              leading: const Icon(Icons.travel_explore),
              title: const Text('Search online & log'),
              subtitle: const Text('Find nutrition from USDA database'),
              onTap: () => Navigator.pop(ctx, 'online'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case 'foods':
        await _addLogEntryFromFoods();
        break;
      case 'quick':
        await _addQuickManualEntry();
        break;
      case 'templates':
        await _addFromTemplates();
        break;
      case 'online':
        await _searchOnlineAndLog();
        break;
    }
  }

  Future<void> _addLogEntryFromFoods() async {
    Food? selected;
    final amountCtrl = TextEditingController(text: '1');
    final searchCtrl = TextEditingController();
    String selectedLabel = 'Breakfast';
    TimeOfDay selectedTime = TimeOfDay.now();

    // Phase 1: pick a food
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: StatefulBuilder(
              builder: (ctx, setInner) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Select food', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: const InputDecoration(labelText: 'Search My Foods', prefixIcon: Icon(Icons.search)),
                      onChanged: (_) => setInner(() {}),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: FutureBuilder<List<Food>>(
                        future: AppDb.instance.getUserFoods(query: searchCtrl.text.trim()),
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final list = snap.data ?? const <Food>[];
                          if (list.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('No foods found. Add foods in My Foods or import from Library.'),
                            );
                          }
                          return ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (_, i) {
                              final f = list[i];
                              return ListTile(
                                isThreeLine: true,
                                title: Text(f.name),
                                subtitle: Text(_foodListSubtitle(f)),
                                onTap: () {
                                  selected = f;
                                  Navigator.pop(ctx);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    // Nothing selected - user dismissed
    if (selected == null || !mounted) return;

    // Phase 2: enter amount, category, time
    final servings = await AppDb.instance.getFoodServings(selected!.id!);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected!.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _addLogEntryFromFoods();
                          },
                          child: const Text('Change'),
                        ),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    Text(
                      _foodListSubtitle(selected!),
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    if (servings.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Quick serving', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: servings.map((s) {
                          return ActionChip(
                            label: Text(s.name),
                            onPressed: () => setInner(() {
                              amountCtrl.text = s.grams
                                  .toStringAsFixed(s.grams == s.grams.roundToDouble() ? 0 : 1);
                            }),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountCtrl,
                      autofocus: servings.isEmpty,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount eaten',
                        suffixText: selected!.unit,
                        helperText: 'Nutrition is ${_baseLabel(selected!)}',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedLabel,
                      decoration: const InputDecoration(labelText: 'Meal category', prefixIcon: Icon(Icons.sell_outlined)),
                      items: _kMealCategories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setInner(() => selectedLabel = v ?? 'Breakfast'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Time: ${_fmtTime(selectedTime)}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: const Text('Pick'),
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                            if (picked != null) setInner(() => selectedTime = picked);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final f = selected!;
                        final amount = double.tryParse(amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                        if (amount <= 0) return;

                        await AppDb.instance.insertLog(
                          LogEntry(
                            date: _date,
                            foodId: f.id,
                            grams: amount,
                            unit: f.unit,
                            baseAmount: f.baseAmount,
                            label: selectedLabel,
                            time: _fmtTime(selectedTime),
                            foodName: f.name,
                            calories100: f.calories,
                            protein100: f.protein,
                            carbs100: f.carbs,
                            fat100: f.fat,
                            fiber100: f.fiber,
                            sugar100: f.sugar,
                            sodium100: f.sodium,
                            cholesterol100: f.cholesterol,
                            saturatedFat100: f.saturatedFat,
                            transFat100: f.transFat,
                            entryType: 'food',
                          ),
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) setState(() {});
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addQuickManualEntry() async {
  final nameCtrl = TextEditingController();
  final kcalCtrl = TextEditingController();
  final pCtrl = TextEditingController(text: '0');
  final cCtrl = TextEditingController(text: '0');
  final fCtrl = TextEditingController(text: '0');
  final fiCtrl = TextEditingController(text: '0');
  final suCtrl = TextEditingController(text: '0');
  final soCtrl = TextEditingController(text: '0');

  String selectedLabel = 'Breakfast';
  TimeOfDay selectedTime = TimeOfDay.now();

  double d(TextEditingController t) =>
      double.tryParse(t.text.trim().replaceAll(',', '.')) ?? 0;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setInner) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Quick entry',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name (e.g., Restaurant pasta)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedLabel,
                    decoration: const InputDecoration(
                      labelText: 'Label',
                      prefixIcon: Icon(Icons.sell_outlined),
                    ),
                    items: _kMealCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setInner(() => selectedLabel = v ?? 'Breakfast'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Time: ${_fmtTime(selectedTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Pick'),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setInner(() => selectedTime = picked);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: kcalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Protein (g)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: cCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Carbs (g)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: fCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Fat (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fiCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Fiber (g)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: suCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sugar (g)'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: soCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sodium (mg)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final kcal = d(kcalCtrl);
                      if (name.isEmpty || kcal <= 0) return;

                      await AppDb.instance.insertManualLog(
                        date: _date,
                        name: name,
                        calories: kcal,
                        protein: d(pCtrl),
                        carbs: d(cCtrl),
                        fat: d(fCtrl),
                        fiber: d(fiCtrl),
                        sugar: d(suCtrl),
                        sodium: d(soCtrl),
                        time: _fmtTime(selectedTime),
                        label: selectedLabel,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  Future<void> _editAndApplyTemplate({
    required MealTemplate template,
    required TimeOfDay time,
    required String label,
  }) async {
    final joined = await AppDb.instance.getMealTemplateItemsJoined(template.id!);
    if (!mounted) return;

    if (joined.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Template has no items')),
      );
      return;
    }

    final enabled = List<bool>.filled(joined.length, true);
    final controllers = joined.map((row) {
      final amt = ((row['amount'] as num?) ?? 1).toDouble();
      return TextEditingController(text: _numStr(amt));
    }).toList();

    // Load serving sizes for each food in the template
    final servings = await Future.wait(joined.map((row) {
      final foodId = (row['food_id'] as num?)?.toInt();
      if (foodId == null) return Future.value(<FoodServing>[]);
      return AppDb.instance.getFoodServings(foodId);
    }));
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            double totalKcal = 0, totalP = 0, totalC = 0, totalF = 0;
            double totalFi = 0, totalSu = 0, totalSo = 0;
            double totalChol = 0, totalSat = 0, totalTrans = 0;
            for (int i = 0; i < joined.length; i++) {
              if (!enabled[i]) continue;
              final row = joined[i];
              final amt = double.tryParse(
                    controllers[i].text.trim().replaceAll(',', '.'),
                  ) ??
                  0;
              final base = ((row['base_amount'] as num?) ?? 1).toDouble();
              final safeBase = base <= 0 ? 1.0 : base;
              final factor = amt / safeBase;
              totalKcal +=
                  (((row['calories'] as num?) ?? 0).toDouble()) * factor;
              totalP += (((row['protein'] as num?) ?? 0).toDouble()) * factor;
              totalC += (((row['carbs'] as num?) ?? 0).toDouble()) * factor;
              totalF += (((row['fat'] as num?) ?? 0).toDouble()) * factor;
              totalFi += (((row['fiber'] as num?) ?? 0).toDouble()) * factor;
              totalSu += (((row['sugar'] as num?) ?? 0).toDouble()) * factor;
              totalSo += (((row['sodium'] as num?) ?? 0).toDouble()) * factor;
              totalChol +=
                  (((row['cholesterol'] as num?) ?? 0).toDouble()) * factor;
              totalSat +=
                  (((row['saturated_fat'] as num?) ?? 0).toDouble()) * factor;
              totalTrans +=
                  (((row['trans_fat'] as num?) ?? 0).toDouble()) * factor;
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    Text(
                      '${totalKcal.round()} kcal  |  P ${_numStr(totalP)}g  |  C ${_numStr(totalC)}g  |  F ${_numStr(totalF)}g'
                      '  |  Fi ${_numStr(totalFi)}g  |  Su ${_numStr(totalSu)}g  |  Na ${_numStr(totalSo)}mg',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fatDetailLine(
                        saturatedFat: totalSat,
                        transFat: totalTrans,
                        cholesterol: totalChol,
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: joined.length,
                        itemBuilder: (_, i) {
                          final row = joined[i];
                          final foodName =
                              (row['food_name'] as String?) ?? 'Unknown';
                          final unit = (row['unit'] as String?) ?? 'g';
                          final itemServings = servings[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: enabled[i],
                                      onChanged: (v) => setInner(
                                        () => enabled[i] = v ?? true,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        foodName,
                                        style: TextStyle(
                                          color: enabled[i]
                                              ? null
                                              : Colors.black38,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: controllers[i],
                                        keyboardType: TextInputType.number,
                                        enabled: enabled[i],
                                        decoration: InputDecoration(
                                          suffixText: unit,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (_) => setInner(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                                if (enabled[i] && itemServings.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 48,
                                      bottom: 4,
                                    ),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 0,
                                      children: itemServings.map((s) {
                                        return ActionChip(
                                          labelPadding: EdgeInsets.zero,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          label: Text(
                                            '${s.name} (${_numStr(s.grams)} $unit)',
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          onPressed: () => setInner(
                                            () => controllers[i].text =
                                                _numStr(s.grams),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: totalKcal <= 0
                          ? null
                          : () async {
                              await AppDb.instance.insertManualLog(
                                date: _date,
                                name: template.name,
                                calories: totalKcal,
                                protein: totalP,
                                carbs: totalC,
                                fat: totalF,
                                fiber: totalFi,
                                sugar: totalSu,
                                sodium: totalSo,
                                cholesterol: totalChol,
                                saturatedFat: totalSat,
                                transFat: totalTrans,
                                time: _fmtTime(time),
                                label: label,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) setState(() {});
                            },
                      child: const Text('Add to Log'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addFromTemplates() async {
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedLabel = 'Breakfast';
    final result = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setInner) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Add from My Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedLabel,
                    decoration: const InputDecoration(labelText: 'Meal category', prefixIcon: Icon(Icons.sell_outlined)),
                    items: _kMealCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setInner(() => selectedLabel = v ?? 'Breakfast'),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Time: ${_fmtTime(selectedTime)}', style: const TextStyle(fontWeight: FontWeight.w600))),
                      TextButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Pick'),
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                          if (picked != null) setInner(() => selectedTime = picked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<List<TemplateWithTotals>>(
                    future: AppDb.instance.getUserMealTemplatesWithTotals(),
                    builder: (_, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final templates = snap.data ?? const <TemplateWithTotals>[];
                      if (templates.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('No templates yet. Create one in Templates screen.'),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create template'),
                                onPressed: () => Navigator.pop(ctx, 'manage'),
                              ),
                            ],
                          ),
                        );
                      }

                      return SizedBox(
                        height: 320,
                        child: ListView.builder(
                          itemCount: templates.length,
                          itemBuilder: (_, i) {
                            final row = templates[i];
                            final t = row.template;
                            final totals = row.totals;

                            return Card(
                              child: ListTile(
                                isThreeLine: true,
                                title: Text(t.name),
                                subtitle: Text(
                                  _templateListSubtitle(
                                    label: t.label,
                                    calories: totals.calories,
                                    protein: totals.protein,
                                    carbs: totals.carbs,
                                    fat: totals.fat,
                                  ),
                                ),
                                trailing: const Icon(Icons.edit_outlined),
                                onTap: () => Navigator.pop(ctx, t),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.list_alt),
                    label: const Text('Manage templates'),
                    onPressed: () => Navigator.pop(ctx, 'manage'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == 'manage') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TemplatesPage()),
      );
      if (mounted) setState(() {});
      return;
    }
    if (result is MealTemplate) {
      await _editAndApplyTemplate(
        template: result,
        time: selectedTime,
        label: selectedLabel,
      );
    }
  }

  Future<void> _searchOnlineAndLog() async {
    // Step 1: search
    final result = await showFoodSearchSheet(context);
    if (result == null || !mounted) return;

    // Step 2: enter amount, category, time and log
    final amountCtrl = TextEditingController(text: '100');
    String selectedLabel = 'Breakfast';
    TimeOfDay selectedTime = TimeOfDay.now();
    bool saveToMyFoods = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(result.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ],
                ),
                Text(result.macroSummary,
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 16),
                // Quick serving chips
                Wrap(
                  spacing: 8,
                  children: [50, 100, 150, 200].map((g) {
                    return ActionChip(
                      label: Text('${g}g'),
                      onPressed: () => setInner(() => amountCtrl.text = g.toString()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount eaten',
                    suffixText: 'g',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedLabel,
                  decoration: const InputDecoration(
                      labelText: 'Meal category',
                      prefixIcon: Icon(Icons.sell_outlined)),
                  items: _kMealCategories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setInner(() => selectedLabel = v ?? 'Breakfast'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Time: ${_fmtTime(selectedTime)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.access_time),
                      label: const Text('Pick'),
                      onPressed: () async {
                        final picked = await showTimePicker(
                            context: ctx, initialTime: selectedTime);
                        if (picked != null) setInner(() => selectedTime = picked);
                      },
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Also save to My Foods'),
                  value: saveToMyFoods,
                  onChanged: (v) => setInner(() => saveToMyFoods = v),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final grams = double.tryParse(
                            amountCtrl.text.trim().replaceAll(',', '.')) ??
                        0;
                    if (grams <= 0) return;

                    // Log as manual entry with the searched nutrition, scaled
                    final factor = grams / 100.0;
                    await AppDb.instance.insertManualLog(
                      date: _date,
                      name: result.name,
                      calories: result.calories * factor,
                      protein: result.protein * factor,
                      carbs: result.carbs * factor,
                      fat: result.fat * factor,
                      fiber: result.fiber * factor,
                      sugar: result.sugar * factor,
                      sodium: result.sodium * factor,
                      cholesterol: result.cholesterol * factor,
                      saturatedFat: result.saturatedFat * factor,
                      transFat: result.transFat * factor,
                      time: _fmtTime(selectedTime),
                      label: selectedLabel,
                    );

                    if (saveToMyFoods) {
                      await AppDb.instance.insertFood(Food(
                        name: result.name,
                        calories: result.calories,
                        protein: result.protein,
                        carbs: result.carbs,
                        fat: result.fat,
                        fiber: result.fiber,
                        sugar: result.sugar,
                        sodium: result.sodium,
                        cholesterol: result.cholesterol,
                        saturatedFat: result.saturatedFat,
                        transFat: result.transFat,
                        unit: 'g',
                        baseAmount: 100,
                        isSystem: false,
                      ));
                    }

                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Log'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BrandedAppBarTitle(title: 'Daily Log', subtitle: _date),
        actions: [
          IconButton(
            tooltip: 'Data retention',
            icon: const Icon(Icons.storage),
            onPressed: () async {
              await editRetentionDaysDialog(context);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Default targets',
            icon: const Icon(Icons.flag),
            onPressed: () async {
              await editDefaultTargetsOneDialog(context);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Targets for this date',
            icon: const Icon(Icons.edit_calendar),
            onPressed: () async {
              await editTargetsForDateOneDialog(context, _date);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Reset targets for this date',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await AppDb.instance.clearTargetsForDate(_date);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Using default targets for this date')));
            },
          ),
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.date_range)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddMenu, child: const Icon(Icons.add)),
      bottomNavigationBar: _bottomNav(widget.navIndex, widget.onNavTap),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: Future.wait([
            AppDb.instance.getTotalsForDate(_date),
            AppDb.instance.getTargetsForDate(_date),
            AppDb.instance.getLogRowsForDate(_date),
          ]),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

            final data = snap.data as List<Object?>?;
            final totals = (data?[0] as DayTotals?) ?? const DayTotals();
            final targets = (data?[1] as MacroTargets?) ?? const MacroTargets(calories: 2000, protein: 150, carbs: 200, fat: 70);
            final rows = (data?[2] as List<Map<String, Object?>>?) ?? const [];

            return ListView(
              children: [
               Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Health tools',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('BMI & calories'),
              onPressed: () async {
                await showBmiAndCalorieToolsDialog(context, _date);
                if (mounted) setState(() {});
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Edit targets'),
              onPressed: () async {
                await editTargetsForDateOneDialog(context, _date);
                if (mounted) setState(() {});
              },
            ),
          ],
        ),
      ],
    ),
  ),
),
const SizedBox(height: 12),
                _progressBarCalories(taken: totals.calories.round(), target: targets.calories, totals: totals, targets: targets),
                const SizedBox(height: 12),
                _targetsTable(totals: totals, targets: targets),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No entries yet. Tap + to add what you ate.')),
                  )
                else ..._buildCategorizedLog(
                  context,
                  rows,
                  () => setState(() {}),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------- MY FOODS ----------------

class FoodsPage extends StatefulWidget {
  final int navIndex;
  final void Function(int) onNavTap;

  const FoodsPage({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<FoodsPage> createState() => _FoodsPageState();
}

class _FoodsPageState extends State<FoodsPage> {
  String _q = '';

  static const kUnits = <String>['g', 'ml', 'tbsp', 'tsp', 'cup', 'liter', 'piece', 'slice'];

  double _computeBaseAmount(String unit) => (unit == 'g' || unit == 'ml') ? 100 : 1;

  // ── Unit converter fallback ──────────────────────────────────────────────

  /// Common density table (g per ml) used when the user falls back to the
  /// converter instead of USDA.  The user can override the density inline.
  static const _kDensityDefaults = <String, double>{
    'oil / fat (liquid)': 0.92,
    'water / juice / milk': 1.00,
    'vinegar': 1.01,
    'honey / syrup': 1.40,
    'flour (wheat)': 0.53,
    'sugar (white)': 0.85,
    'salt': 1.20,
    'other (1 g/ml)': 1.00,
  };

  /// Volume of common units in ml.
  static const _kUnitVolumeMl = <String, double>{
    'tsp': 4.93,
    'tbsp': 14.79,
    'fl oz': 29.57,
    'cup': 240.0,
    'ml': 1.0,
  };

  /// Weight units in grams (no density needed).
  static const _kUnitWeightG = <String, double>{
    'g': 1.0,
    'oz': 28.35,
  };

  Future<void> _searchAndAddServings({
    required void Function(List<FoodServing>) onServingsChanged,
    required int foodId,
    required String foodName,
    required String foodUnit,
  }) async {
    void showBlockingDialog(String message) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
    }

    Future<void> closeBlockingDialog() async {
      if (!mounted) return;
      await Future<void>.delayed(Duration.zero);
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    Future<FoodCandidate?> pickCandidate(
      List<FoodCandidate> items,
    ) {
      return showDialog<FoodCandidate?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Select matching food'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final candidate = items[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    candidate.name,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    candidate.dataType,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  onTap: () => Navigator.pop(ctx, candidate),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Back'),
            ),
            OutlinedButton(
              onPressed: () => Navigator.pop(
                ctx,
                const FoodCandidate(
                  fdcId: -1,
                  name: '__converter__',
                  dataType: '',
                ),
              ),
              child: const Text('Use converter'),
            ),
          ],
        ),
      );
    }

    Future<List<bool>?> pickPortions(
      FoodCandidate candidate,
      List<ServingPortion> portions,
    ) {
      final selected = List<bool>.filled(portions.length, false);
      return showDialog<List<bool>?>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setInner) => AlertDialog(
            title: Text('Portions for ${candidate.name}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: portions.length,
                itemBuilder: (_, i) {
                  final portion = portions[i];
                  return CheckboxListTile(
                    dense: true,
                    value: selected[i],
                    onChanged: (v) =>
                        setInner(() => selected[i] = v ?? false),
                    title: Text(
                      portion.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${portion.grams.toStringAsFixed(1)} $foodUnit',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Back'),
              ),
              FilledButton(
                onPressed: selected.contains(true)
                    ? () => Navigator.pop(ctx, List<bool>.from(selected))
                    : null,
                child: const Text('Add selected'),
              ),
            ],
          ),
        ),
      );
    }

    showBlockingDialog('Searching USDA...');
    List<FoodCandidate>? candidates;
    String? fetchError;
    try {
      candidates = await searchFoodCandidates(foodName);
    } catch (e) {
      fetchError = e.toString();
    }

    await closeBlockingDialog();
    if (!mounted) return;

    if (fetchError != null) {
      await _showServingConverter(
        onServingsChanged: onServingsChanged,
        foodId: foodId,
        foodUnit: foodUnit,
        errorMessage: 'USDA search failed: $fetchError',
      );
      return;
    }

    if (candidates == null || candidates.isEmpty) {
      await _showServingConverter(
        onServingsChanged: onServingsChanged,
        foodId: foodId,
        foodUnit: foodUnit,
        errorMessage: 'No USDA results for "$foodName".',
      );
      return;
    }

    final picked = await pickCandidate(candidates);
    if (!mounted || picked == null) return;
    if (picked.fdcId == -1) {
      await _showServingConverter(
        onServingsChanged: onServingsChanged,
        foodId: foodId,
        foodUnit: foodUnit,
      );
      return;
    }

    showBlockingDialog('Loading USDA portions...');
    fetchError = null;
    List<ServingPortion>? portions;
    try {
      portions = await fetchPortions(picked.fdcId);
    } catch (e) {
      fetchError = e.toString();
    }

    await closeBlockingDialog();
    if (!mounted) return;

    if (fetchError != null || portions == null || portions.isEmpty) {
      final msg = fetchError != null
          ? 'Failed to load USDA portions: $fetchError'
          : 'No standard portions found for "${picked.name}".';
      await _showServingConverter(
        onServingsChanged: onServingsChanged,
        foodId: foodId,
        foodUnit: foodUnit,
        errorMessage: msg,
      );
      return;
    }

    final selected = await pickPortions(picked, portions);
    if (!mounted || selected == null) return;

    for (int i = 0; i < portions.length; i++) {
      if (!selected[i]) continue;
      await AppDb.instance.addFoodServing(
        foodId: foodId,
        name: portions[i].name,
        grams: portions[i].grams,
      );
    }

    if (mounted) {
      final updated = await AppDb.instance.getFoodServings(foodId);
      onServingsChanged(updated);
    }
  }

  Future<void> _showServingConverter({
    required void Function(List<FoodServing>) onServingsChanged,
    required int foodId,
    required String foodUnit,
    String? errorMessage,
  }) async {
    String selectedVolumeUnit = 'tbsp';
    String selectedDensityKey = 'oil / fat (liquid)';
    final qtyCtrl = TextEditingController(text: '1');
    final densityCtrl = TextEditingController(
      text: _kDensityDefaults['oil / fat (liquid)']!.toString(),
    );
    final nameCtrl = TextEditingController();

    double computeGrams() {
      final qty =
          double.tryParse(qtyCtrl.text.trim().replaceAll(',', '.')) ?? 0;
      if (_kUnitWeightG.containsKey(selectedVolumeUnit)) {
        return qty * _kUnitWeightG[selectedVolumeUnit]!;
      }
      final volMl = _kUnitVolumeMl[selectedVolumeUnit] ?? 1.0;
      final density =
          double.tryParse(densityCtrl.text.trim().replaceAll(',', '.')) ??
              1.0;
      return qty * volMl * density;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final grams = computeGrams();
          final isVolumeUnit = _kUnitVolumeMl.containsKey(selectedVolumeUnit);

          return AlertDialog(
            title: const Text('Serving converter'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (errorMessage != null) ...[
                    Text(
                      errorMessage,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Unit picker
                  DropdownButtonFormField<String>(
                    value: selectedVolumeUnit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: [
                      ..._kUnitVolumeMl.keys,
                      ..._kUnitWeightG.keys,
                    ]
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setInner(() {
                      selectedVolumeUnit = v ?? 'tbsp';
                      if (!_kUnitVolumeMl.containsKey(selectedVolumeUnit)) {
                        // weight unit - no density needed
                      }
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      suffixText: selectedVolumeUnit,
                    ),
                    onChanged: (_) => setInner(() {}),
                  ),
                  if (isVolumeUnit) ...[
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedDensityKey,
                      decoration: const InputDecoration(
                        labelText: 'Food type (density)',
                      ),
                      items: _kDensityDefaults.keys
                          .map((k) =>
                              DropdownMenuItem(value: k, child: Text(k)))
                          .toList(),
                      onChanged: (v) => setInner(() {
                        selectedDensityKey = v ?? selectedDensityKey;
                        densityCtrl.text =
                            _kDensityDefaults[selectedDensityKey]!
                                .toString();
                      }),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: densityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Density (g/ml) - edit if needed',
                      ),
                      onChanged: (_) => setInner(() {}),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Estimated: ${grams.toStringAsFixed(1)} $foodUnit',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Serving name',
                      hintText:
                          '${qtyCtrl.text.trim()} $selectedVolumeUnit',
                    ),
                    onChanged: (_) => setInner(() {}),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: grams > 0
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Add serving'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || !mounted) return;
    final grams = computeGrams();
    if (grams <= 0) return;
    final name = nameCtrl.text.trim().isNotEmpty
        ? nameCtrl.text.trim()
        : '${qtyCtrl.text.trim()} $selectedVolumeUnit';
    await AppDb.instance.addFoodServing(
      foodId: foodId,
      name: name,
      grams: grams,
    );
    if (mounted) {
      final updated = await AppDb.instance.getFoodServings(foodId);
      onServingsChanged(updated);
    }
  }

  Future<void> _openFoodForm({Food? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final calsCtrl = TextEditingController(text: (existing?.calories ?? 0).toString());
    final protCtrl = TextEditingController(text: (existing?.protein ?? 0).toString());
    final carbCtrl = TextEditingController(text: (existing?.carbs ?? 0).toString());
    final fatCtrl = TextEditingController(text: (existing?.fat ?? 0).toString());
    final fiberCtrl = TextEditingController(text: (existing?.fiber ?? 0).toString());
    final sugarCtrl = TextEditingController(text: (existing?.sugar ?? 0).toString());
    final sodiumCtrl = TextEditingController(text: (existing?.sodium ?? 0).toString());
    final cholesterolCtrl = TextEditingController(
      text: (existing?.cholesterol ?? 0).toString(),
    );
    final saturatedFatCtrl = TextEditingController(
      text: (existing?.saturatedFat ?? 0).toString(),
    );
    final transFatCtrl = TextEditingController(
      text: (existing?.transFat ?? 0).toString(),
    );

    String selectedUnit = existing?.unit ?? 'g';
    List<FoodServing> servings = existing?.id != null
        ? await AppDb.instance.getFoodServings(existing!.id!)
        : [];

    double parseNum(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

    Future<void> addServing(StateSetter setInner, int foodId) async {
      final nameCtrl2 = TextEditingController();
      final gramsCtrl = TextEditingController();
      await showDialog(
        context: context,
        builder: (ctx2) => AlertDialog(
          title: const Text('Add serving size'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl2,
                decoration: const InputDecoration(labelText: 'Name (e.g. 1 tbsp, 1 egg)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: gramsCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount in $selectedUnit',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx2), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final n = nameCtrl2.text.trim();
                final g = double.tryParse(gramsCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                if (n.isEmpty || g <= 0) return;
                await AppDb.instance.addFoodServing(foodId: foodId, name: n, grams: g);
                final updated = await AppDb.instance.getFoodServings(foodId);
                setInner(() => servings = updated);
                if (ctx2.mounted) Navigator.pop(ctx2);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          final baseAmount = _computeBaseAmount(selectedUnit);
          final baseLabel = 'per ${baseAmount.toStringAsFixed(baseAmount == baseAmount.roundToDouble() ? 0 : 1)} $selectedUnit';

          return AlertDialog(
            title: Text(existing == null ? 'Add food ($baseLabel)' : 'Edit food ($baseLabel)'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.travel_explore),
                    label: const Text('Search online to fill nutrition'),
                    onPressed: () async {
                      final result = await showFoodSearchSheet(context);
                      if (result == null) return;
                      setInner(() {
                        nameCtrl.text = result.name;
                        calsCtrl.text = result.calories.toStringAsFixed(1);
                        protCtrl.text = result.protein.toStringAsFixed(1);
                        carbCtrl.text = result.carbs.toStringAsFixed(1);
                        fatCtrl.text = result.fat.toStringAsFixed(1);
                        fiberCtrl.text = result.fiber.toStringAsFixed(1);
                        sugarCtrl.text = result.sugar.toStringAsFixed(1);
                        sodiumCtrl.text = result.sodium.toStringAsFixed(0);
                        cholesterolCtrl.text =
                            result.cholesterol.toStringAsFixed(0);
                        saturatedFatCtrl.text =
                            result.saturatedFat.toStringAsFixed(1);
                        transFatCtrl.text =
                            result.transFat.toStringAsFixed(1);
                        selectedUnit = 'g';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedUnit,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      helperText: 'For g/ml values are per 100. For others values are per 1.',
                      helperMaxLines: 2,
                    ),
                    items: kUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setInner(() => selectedUnit = v ?? 'g'),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: calsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)')),
                  TextField(controller: protCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Protein (g)')),
                  TextField(controller: carbCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbs (g)')),
                  TextField(controller: fatCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fat (g)')),
                  const SizedBox(height: 10),
                  TextField(controller: fiberCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fiber (g)')),
                  TextField(controller: sugarCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sugar (g)')),
                  TextField(controller: sodiumCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sodium (mg)')),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cholesterolCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cholesterol (mg)',
                    ),
                  ),
                  TextField(
                    controller: saturatedFatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Saturated fat (g)',
                    ),
                  ),
                  TextField(
                    controller: transFatCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Trans fat (g)',
                    ),
                  ),
                  if (existing?.id != null) ...[
                    const SizedBox(height: 14),
                    const Divider(),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Serving sizes', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add'),
                          onPressed: () => addServing(setInner, existing!.id!),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.travel_explore, size: 16),
                          label: const Text('Search USDA'),
                          onPressed: () => _searchAndAddServings(
                            onServingsChanged: (updated) =>
                                setInner(() => servings = updated),
                            foodId: existing!.id!,
                            foodName: nameCtrl.text.trim().isNotEmpty
                                ? nameCtrl.text.trim()
                                : (existing.name),
                            foodUnit: selectedUnit,
                          ),
                        ),
                      ],
                    ),
                    if (servings.isEmpty)
                      const Text('No serving sizes yet.', style: TextStyle(fontSize: 12, color: Colors.black54))
                    else
                      Wrap(
                        spacing: 6,
                        children: servings.map((s) {
                          return Chip(
                            label: Text('${s.name} (${s.grams.toStringAsFixed(s.grams == s.grams.roundToDouble() ? 0 : 1)} $selectedUnit)'),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () async {
                              await AppDb.instance.deleteFoodServing(s.id!);
                              final updated = await AppDb.instance.getFoodServings(existing!.id!);
                              setInner(() => servings = updated);
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final food = Food(
                    id: existing?.id,
                    name: name,
                    calories: parseNum(calsCtrl),
                    protein: parseNum(protCtrl),
                    carbs: parseNum(carbCtrl),
                    fat: parseNum(fatCtrl),
                    fiber: parseNum(fiberCtrl),
                    sugar: parseNum(sugarCtrl),
                    sodium: parseNum(sodiumCtrl),
                    cholesterol: parseNum(cholesterolCtrl),
                    saturatedFat: parseNum(saturatedFatCtrl),
                    transFat: parseNum(transFatCtrl),
                    unit: selectedUnit,
                    baseAmount: _computeBaseAmount(selectedUnit),
                    isSystem: false,
                    category: existing?.category,
                  );

                  if (existing == null) {
                    final newId = await AppDb.instance.insertFood(food);
                    // Open again to allow adding servings
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      setState(() {});
                      await _openFoodForm(existing: Food(
                        id: newId, name: food.name, calories: food.calories,
                        protein: food.protein, carbs: food.carbs, fat: food.fat,
                        fiber: food.fiber, sugar: food.sugar, sodium: food.sodium,
                        cholesterol: food.cholesterol,
                        saturatedFat: food.saturatedFat,
                        transFat: food.transFat,
                        unit: food.unit, baseAmount: food.baseAmount,
                        isSystem: false, category: food.category,
                      ));
                    }
                    return;
                  } else {
                    await AppDb.instance.updateFood(food);
                  }

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) setState(() {});
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openTemplates() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const TemplatesPage()));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'My Foods'),
        actions: [
          IconButton(
            tooltip: 'My Templates',
            icon: const Icon(Icons.bookmarks_outlined),
            onPressed: _openTemplates,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _openFoodForm(), child: const Icon(Icons.add)),
      bottomNavigationBar: _bottomNav(widget.navIndex, widget.onNavTap),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Search My Foods', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Food>>(
                future: AppDb.instance.getUserFoods(query: _q),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final foods = snap.data ?? const <Food>[];
                  if (foods.isEmpty) return const Center(child: Text('No foods yet. Add or import from Global.'));

                  return ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (_, i) {
                      final f = foods[i];
                      return Card(
                        child: ListTile(
                          isThreeLine: true,
                          title: Text(f.name),
                          subtitle: Text(_foodListSubtitle(f)),
                          onTap: () => _openFoodForm(existing: f),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final templateNames = await AppDb.instance
                                  .getTemplateNamesUsingFood(f.id!);
                              if (!mounted) return;
                              if (templateNames.isNotEmpty) {
                                final namesPreview = templateNames.take(3).join(', ');
                                await showDialog<void>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Food used in templates'),
                                    content: Text(
                                      'Remove this food from its meal templates before deleting it.'
                                      '\n\nUsed in: $namesPreview'
                                      '${templateNames.length > 3 ? ' and ${templateNames.length - 3} more.' : '.'}',
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                              await AppDb.instance.deleteFood(f.id!);
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- LIBRARY PAGE ----------------

class GlobalPage extends StatefulWidget {
  final int navIndex;
  final void Function(int) onNavTap;

  const GlobalPage({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<GlobalPage> createState() => _GlobalPageState();
}

class _GlobalPageState extends State<GlobalPage> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(title: 'Library'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(icon: Icon(Icons.restaurant), text: 'Foods'),
            Tab(icon: Icon(Icons.bookmarks), text: 'Templates'),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(widget.navIndex, widget.onNavTap),
      body: TabBarView(
        controller: _tab,
        children: const [
          GlobalFoodsTab(),
          GlobalTemplatesTab(),
        ],
      ),
    );
  }
}

class GlobalFoodsTab extends StatefulWidget {
  const GlobalFoodsTab({super.key});

  @override
  State<GlobalFoodsTab> createState() => _GlobalFoodsTabState();
}

class _GlobalFoodsTabState extends State<GlobalFoodsTab> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Search global foods', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<Food>>(
              future: AppDb.instance.getSystemFoods(query: _q),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final foods = snap.data ?? const <Food>[];
                if (foods.isEmpty) return const Center(child: Text('No system foods found.'));

                return ListView.builder(
                  itemCount: foods.length,
                  itemBuilder: (_, i) {
                    final f = foods[i];
                    return Card(
                      child: ListTile(
                        isThreeLine: true,
                        title: Text(f.name),
                        subtitle: Text(_foodListSubtitle(f, extra: f.category ?? 'Uncategorized')),
                        trailing: FilledButton.icon(
                          icon: const Icon(Icons.download),
                          label: const Text('Add'),
                          onPressed: () async {
                            await AppDb.instance.importSystemFoodToUser(f.id!);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to My Foods')));
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class GlobalTemplatesTab extends StatefulWidget {
  const GlobalTemplatesTab({super.key});

  @override
  State<GlobalTemplatesTab> createState() => _GlobalTemplatesTabState();
}

class _GlobalTemplatesTabState extends State<GlobalTemplatesTab> {
  String _q = '';
  String _labelFilter = 'All';
  late Future<List<TemplateWithTotalsPreview>> _future;

  static const _labels = ['All', 'Breakfast', 'Lunch', 'Dinner', 'Snack'];

  @override
  void initState() {
    super.initState();
    _future = _loadTemplates();
  }

  Future<List<TemplateWithTotalsPreview>> _loadTemplates() {
    return AppDb.instance.getSystemMealTemplatesWithTotalsPreview(
      query: _q,
      label: _labelFilter == 'All' ? null : _labelFilter,
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadTemplates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search global templates',
              prefixIcon: Icon(Icons.search),
              helperText: 'Search by template name or label like Breakfast',
            ),
            onChanged: (v) {
              _q = v;
              _refresh();
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _labels.map((label) {
                final selected = _labelFilter == label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (_) {
                      _labelFilter = label;
                      _refresh();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<TemplateWithTotalsPreview>>(
              future: _future,
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snap.data ?? const <TemplateWithTotalsPreview>[];
                if (list.isEmpty) {
                  return const Center(child: Text('No global templates found.'));
                }

                final widgets = <Widget>[];
                String? currentLabel;

                for (final row in list) {
                  final t = row.template;
                  final totals = row.totals;
                  final previewText = row.itemCount > 0
                      ? row.ingredientsPreview
                      : 'No ingredients found. Reseed system templates once.';

                  if (currentLabel != t.label) {
                    currentLabel = t.label;
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 6),
                        child: Text(
                          currentLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }

                  widgets.add(
                    Card(
                      child: ListTile(
                        isThreeLine: true,
                        title: Text(
                          t.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _templateListSubtitle(
                            label: t.label,
                            calories: totals.calories,
                            protein: totals.protein,
                            carbs: totals.carbs,
                            fat: totals.fat,
                            isDefaultLabel: true,
                            ingredientsPreview: previewText,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SystemTemplatePreviewPage(
                                systemTemplateId: t.id!,
                              ),
                            ),
                          );
                          if (mounted) _refresh();
                        },
                      ),
                    ),
                  );
                }

                return ListView(children: widgets);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SystemTemplatePreviewPage extends StatefulWidget {
  final int systemTemplateId;
  const SystemTemplatePreviewPage({super.key, required this.systemTemplateId});

  @override
  State<SystemTemplatePreviewPage> createState() => _SystemTemplatePreviewPageState();
}

class _SystemTemplatePreviewPageState extends State<SystemTemplatePreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Template preview')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<SystemTemplatePreview>(
          future: AppDb.instance.getSystemTemplatePreview(widget.systemTemplateId),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final preview = snap.data!;
            final totals = preview.totals;

            return ListView(
              children: [
                Text(preview.template.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Default label: ${preview.template.label}'),
                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Totals', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text('Calories: ${totals.calories.toStringAsFixed(0)} kcal'),
                        Text('Protein: ${totals.protein.toStringAsFixed(1)} g'),
                        Text('Carbs: ${totals.carbs.toStringAsFixed(1)} g'),
                        Text('Fat: ${totals.fat.toStringAsFixed(1)} g'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Text('Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),

                ...preview.items.map((it) {
                  final amt = it.amount.toStringAsFixed(it.amount == it.amount.roundToDouble() ? 0 : 1);
                  return Card(
                    child: ListTile(
                      isThreeLine: true,
                      title: Text(it.name),
                      subtitle: Text(
                        '$amt ${it.unit}\n'
                        '${_macroLine(
                          calories: it.calories,
                          protein: it.protein,
                          carbs: it.carbs,
                          fat: it.fat,
                        )}',
                      ),
                    ),
                  );
                }).toList(),

                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Import to My Templates'),
                  onPressed: () async {
                    final labelCtrl = TextEditingController(text: preview.template.label);
                    final nameCtrl = TextEditingController(text: preview.template.name);

                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Import template'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Template name')),
                            const SizedBox(height: 10),
                            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (custom allowed)')),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
                        ],
                      ),
                    );

                    if (ok != true) return;

                    await AppDb.instance.importSystemTemplateToUser(
                      systemTemplateId: widget.systemTemplateId,
                      newLabel: labelCtrl.text.trim().isEmpty ? preview.template.label : labelCtrl.text.trim(),
                      newName: nameCtrl.text.trim().isEmpty ? preview.template.name : nameCtrl.text.trim(),
                    );

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imported to My Templates')));
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------- USER TEMPLATES ----------------

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  Future<void> _createTemplate() async {
    final nameCtrl = TextEditingController();
    final labelCtrl = TextEditingController(text: 'Breakfast');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Label (custom allowed)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );

    if (ok != true) return;
    final name = nameCtrl.text.trim();
    final label = labelCtrl.text.trim();
    if (name.isEmpty) return;

    final id = await AppDb.instance.createMealTemplate(name: name, label: label.isEmpty ? 'Breakfast' : label);

    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TemplateEditPage(templateId: id, title: name)));
    if (mounted) setState(() {});
  }

  Future<void> _duplicateTemplate(MealTemplate template) async {
    final duplicatedId = await AppDb.instance.duplicateUserMealTemplate(
      template.id!,
    );
    final duplicatedTemplate = await AppDb.instance.getMealTemplateById(
      duplicatedId,
    );
    if (!mounted) return;

    setState(() {});
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TemplateEditPage(
          templateId: duplicatedId,
          title: duplicatedTemplate?.name ?? '${template.name} (Copy)',
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Templates')),
      floatingActionButton: FloatingActionButton(onPressed: _createTemplate, child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<TemplateWithTotals>>(
          future: AppDb.instance.getUserMealTemplatesWithTotals(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final list = snap.data ?? const <TemplateWithTotals>[];
            if (list.isEmpty) return const Center(child: Text('No templates yet. Tap + to create one.'));

            return ListView.builder(
  itemCount: list.length,
  itemExtent: 92,
  itemBuilder: (_, i) {
    final row = list[i];
    final t = row.template;
    final totals = row.totals;

    return Card(
      child: ListTile(
        isThreeLine: true,
        title: Text(
          t.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _templateListSubtitle(
            label: t.label,
            calories: totals.calories,
            protein: totals.protein,
            carbs: totals.carbs,
            fat: totals.fat,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'duplicate') {
              await _duplicateTemplate(t);
              return;
            }
            if (value == 'delete') {
              await AppDb.instance.deleteMealTemplate(t.id!);
              if (mounted) setState(() {});
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem<String>(
              value: 'duplicate',
              child: Text('Duplicate'),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TemplateEditPage(templateId: t.id!, title: t.name),
            ),
          );
          if (mounted) setState(() {});
        },
      ),
    );
  },
);
          },
        ),
      ),
    );
  }
}

class TemplateEditPage extends StatefulWidget {
  final int templateId;
  final String title;

  const TemplateEditPage({
    super.key,
    required this.templateId,
    required this.title,
  });

  @override
  State<TemplateEditPage> createState() => _TemplateEditPageState();
}

class _TemplateEditPageState extends State<TemplateEditPage> {
  late String _templateTitle;
  String _templateLabel = 'Breakfast';

  @override
  void initState() {
    super.initState();
    _templateTitle = widget.title;
    _loadTemplateDetails();
  }

  Future<void> _loadTemplateDetails() async {
    final template = await AppDb.instance.getMealTemplateById(widget.templateId);
    if (!mounted || template == null) return;
    setState(() {
      _templateTitle = template.name;
      _templateLabel = template.label;
    });
  }

  Future<void> _editTemplateDetails() async {
    final nameCtrl = TextEditingController(text: _templateTitle);
    final labelCtrl = TextEditingController(text: _templateLabel);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Template name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Label (custom allowed)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    final newName = nameCtrl.text.trim();
    final newLabel = labelCtrl.text.trim().isEmpty
        ? 'Breakfast'
        : labelCtrl.text.trim();
    if (newName.isEmpty) return;
    if (newName == _templateTitle && newLabel == _templateLabel) return;

    await AppDb.instance.updateMealTemplateDetails(
      templateId: widget.templateId,
      name: newName,
      label: newLabel,
    );
    if (!mounted) return;
    setState(() {
      _templateTitle = newName;
      _templateLabel = newLabel;
    });
  }

  Future<void> _addFoodToTemplate() async {
    Food? selected;
    List<FoodServing> servings = [];
    final amountCtrl = TextEditingController(text: '1');
    final searchCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setInner) {
                final unitSuffix = selected?.unit ?? 'g';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add food',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Search My Foods',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (_) => setInner(() {}),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder<List<Food>>(
                        future: AppDb.instance.getUserFoods(
                          query: searchCtrl.text.trim(),
                        ),
                        builder: (_, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          final foods = snap.data ?? const <Food>[];
                          if (foods.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'No My Foods found. Import from Global first.',
                              ),
                            );
                          }

                          return SizedBox(
                            height: 240,
                            child: ListView.builder(
                              itemCount: foods.length,
                              itemBuilder: (_, i) {
                                final f = foods[i];
                                final isSel = selected?.id == f.id;

                                return ListTile(
                                  isThreeLine: true,
                                  title: Text(f.name),
                                  subtitle: Text(_foodListSubtitle(f)),
                                  trailing: isSel
                                      ? const Icon(Icons.check_circle)
                                      : null,
                                  onTap: () async {
                                    final srvs = f.id != null
                                        ? await AppDb.instance
                                            .getFoodServings(f.id!)
                                        : <FoodServing>[];
                                    setInner(() {
                                      selected = f;
                                      servings = srvs;
                                      amountCtrl.text = '1';
                                    });
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (selected != null && servings.isNotEmpty) ...[
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Quick serving',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: servings.map((s) {
                            return ActionChip(
                              label: Text(
                                '${s.name} (${_numStr(s.grams)} ${selected!.unit})',
                              ),
                              onPressed: () => setInner(
                                () => amountCtrl.text = _numStr(s.grams),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 6),
                      ],
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          suffixText: unitSuffix,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          final f = selected;
                          if (f == null) return;

                          final amount = double.tryParse(
                                amountCtrl.text.trim().replaceAll(',', '.'),
                              ) ??
                              0;
                          if (amount <= 0) return;

                          await AppDb.instance.addMealTemplateItem(
                            templateId: widget.templateId,
                            foodId: f.id!,
                            amount: amount,
                            unit: f.unit,
                            baseAmount: f.baseAmount,
                            sortOrder: 0,
                          );

                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) setState(() {});
                        },
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _editTemplateItem(MealTemplateItem item, Food? food) async {
    if (item.id == null) return;
    final servings = food?.id != null
        ? await AppDb.instance.getFoodServings(food!.id!)
        : <FoodServing>[];
    final amountCtrl = TextEditingController(
      text: item.amount.toStringAsFixed(
        item.amount == item.amount.roundToDouble() ? 0 : 1,
      ),
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        food?.name ?? 'Edit Food',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (servings.isNotEmpty) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Quick serving',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: servings.map((s) {
                      return ActionChip(
                        label: Text(
                          '${s.name} (${_numStr(s.grams)} ${item.unit})',
                        ),
                        onPressed: () {
                          amountCtrl.text = _numStr(s.grams);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    suffixText: item.unit,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                          amountCtrl.text.trim().replaceAll(',', '.'),
                        ) ??
                        0;
                    if (amount <= 0) return;
                    await AppDb.instance.updateMealTemplateItem(
                      itemId: item.id!,
                      amount: amount,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) setState(() {});
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, Object?>>> _loadJoinedItems() async {
    return AppDb.instance.getMealTemplateItemsJoined(widget.templateId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_templateTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_file_rename_outline),
            onPressed: _editTemplateDetails,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addFoodToTemplate,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<List<Map<String, Object?>>>(
          future: _loadJoinedItems(),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snap.hasError) {
              return Center(child: Text('Error: ${snap.error}'));
            }

            final list = snap.data ?? const [];

            if (list.isEmpty) {
              return const Center(
                child: Text('No items yet. Tap + to add foods.'),
              );
            }

            return ListView(
              children: list.map((row) {
                final it = MealTemplateItem.fromMap({
                  'id': row['id'],
                  'template_id': row['template_id'],
                  'food_id': row['food_id'],
                  'amount': row['amount'],
                  'unit': row['unit'],
                  'base_amount': row['base_amount'],
                  'sort_order': row['sort_order'],
                });

                final hasFood = (row['food_name'] as String?) != null;

                final food = hasFood
                    ? Food(
                        id: row['food_id'] as int?,
                        name: (row['food_name'] as String?) ?? 'Unknown',
                        calories: ((row['calories'] as num?) ?? 0).toDouble(),
                        protein: ((row['protein'] as num?) ?? 0).toDouble(),
                        carbs: ((row['carbs'] as num?) ?? 0).toDouble(),
                        fat: ((row['fat'] as num?) ?? 0).toDouble(),
                        fiber: ((row['fiber'] as num?) ?? 0).toDouble(),
                        sugar: ((row['sugar'] as num?) ?? 0).toDouble(),
                        sodium: ((row['sodium'] as num?) ?? 0).toDouble(),
                        cholesterol:
                            ((row['cholesterol'] as num?) ?? 0).toDouble(),
                        saturatedFat:
                            ((row['saturated_fat'] as num?) ?? 0).toDouble(),
                        transFat:
                            ((row['trans_fat'] as num?) ?? 0).toDouble(),
                        unit: (row['food_unit'] as String?) ?? 'g',
                        baseAmount:
                            ((row['food_base_amount'] as num?) ?? 100).toDouble(),
                        isSystem: false,
                        category: null,
                      )
                    : null;

                final name = food?.name ?? 'Food #${it.foodId} (missing)';
                final amountStr = it.amount.toStringAsFixed(
                  it.amount == it.amount.roundToDouble() ? 0 : 1,
                );

                final safeBase = it.baseAmount <= 0 ? 1.0 : it.baseAmount;
                final factor = it.amount / safeBase;

                final calories = (food?.calories ?? 0) * factor;
                final protein = (food?.protein ?? 0) * factor;
                final carbs = (food?.carbs ?? 0) * factor;
                final fat = (food?.fat ?? 0) * factor;

                return Card(
                  child: ListTile(
                    isThreeLine: true,
                    title: Text(name),
                    subtitle: Text(
                      '$amountStr ${it.unit}\n'
                      '${_macroLine(
                        calories: calories,
                        protein: protein,
                        carbs: carbs,
                        fat: fat,
                      )}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editTemplateItem(it, food),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            if (it.id == null) return;
                            await AppDb.instance.deleteMealTemplateItem(it.id!);
                            if (mounted) setState(() {});
                          },
                        ),
                      ],
                    ),
                    onTap: () => _editTemplateItem(it, food),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFoodToTemplate,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ---------------- HISTORY ----------------

class HistoryPage extends StatefulWidget {
  final int navIndex;
  final void Function(int) onNavTap;

  const HistoryPage({super.key, required this.navIndex, required this.onNavTap});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _date = _fmtDate(DateTime.now());

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(_date) ?? now;
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDate: initial,
    );
    if (picked != null) setState(() => _date = _fmtDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BrandedAppBarTitle(title: 'History', subtitle: _date),
        actions: [
          IconButton(
            tooltip: 'Data retention',
            icon: const Icon(Icons.storage),
            onPressed: () async {
              await editRetentionDaysDialog(context);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Default targets',
            icon: const Icon(Icons.flag),
            onPressed: () async {
              await editDefaultTargetsOneDialog(context);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Targets for this date',
            icon: const Icon(Icons.edit_calendar),
            onPressed: () async {
              await editTargetsForDateOneDialog(context, _date);
              if (mounted) setState(() {});
            },
          ),
          IconButton(
            tooltip: 'Reset targets for this date',
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await AppDb.instance.clearTargetsForDate(_date);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Using default targets for this date')));
            },
          ),
          IconButton(onPressed: _pickDate, icon: const Icon(Icons.date_range)),
        ],
      ),
      bottomNavigationBar: _bottomNav(widget.navIndex, widget.onNavTap),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: Future.wait([
            AppDb.instance.getTotalsForDate(_date),
            AppDb.instance.getTargetsForDate(_date),
            AppDb.instance.getLogRowsForDate(_date),
          ]),
          builder: (_, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));

            final data = snap.data as List<Object?>?;
            final totals = (data?[0] as DayTotals?) ?? const DayTotals();
            final targets = (data?[1] as MacroTargets?) ?? const MacroTargets(calories: 2000, protein: 150, carbs: 200, fat: 70);
            final rows = (data?[2] as List<Map<String, Object?>>?) ?? const [];

            return ListView(
              children: [
                _progressBarCalories(taken: totals.calories.round(), target: targets.calories, totals: totals, targets: targets),
                const SizedBox(height: 12),
                _targetsTable(totals: totals, targets: targets),
                const SizedBox(height: 12),
                const Text('Entries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text('No entries for this date.')),
                  )
                else
                  ...rows.map((r) {
                    final logId = r['log_id'] as int;
                    final name = (r['name'] as String?) ?? 'Unknown';
                    final subtitle = _logSubtitleFromRow(r);

                    return Card(
                      child: ListTile(
                        isThreeLine: true,
                        title: Text(name),
                        subtitle: Text(subtitle),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            await AppDb.instance.deleteLog(logId);
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------- ONLINE FOOD SEARCH ----------------

/// Shows an online food search sheet and returns the selected result, or null.
Future<FoodSearchResult?> showFoodSearchSheet(BuildContext context) {
  return showModalBottomSheet<FoodSearchResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _FoodSearchSheet(),
  );
}

class _FoodSearchSheet extends StatefulWidget {
  const _FoodSearchSheet();

  @override
  State<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends State<_FoodSearchSheet> {
  final _searchCtrl = TextEditingController();
  List<FoodSearchResult>? _results;
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _results = null; });
    try {
      final results = await searchFoodsOnline(q);
      if (mounted) setState(() { _results = results; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is FoodSearchException
              ? e.message
              : 'Search failed. Try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Search Food Online',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Text(
            'Powered by USDA FoodData Central  |  values per 100 g',
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    labelText: 'e.g. chicken breast, olive oil, egg',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _loading ? null : _search, child: const Text('Go')),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            Expanded(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))))
          else if (_results == null)
            const Expanded(child: Center(child: Text('Type a food name and tap Go.')))
          else if (_results!.isEmpty)
            const Expanded(child: Center(child: Text('No results found. Try different keywords.')))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _results!.length,
                itemBuilder: (_, i) {
                  final r = _results![i];
                  return ListTile(
                    isThreeLine: true,
                    title: Text(r.name),
                    subtitle: Text(r.macroSummary),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pop(context, r),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- UPCOMING FEATURE PAGE ----------------

class _UpcomingFeaturePage extends StatelessWidget {
  final String title;
  const _UpcomingFeaturePage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rocket_launch_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Upcoming Feature',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay tuned - this is coming soon!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyPolicyPage extends StatelessWidget {
  const _PrivacyPolicyPage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const BrandedAppBarTitle(
          title: 'Privacy Policy',
          subtitle: 'How CalorieFit handles data',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Last updated: $kPrivacyPolicyLastUpdated',
            style: textTheme.labelLarge?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _PolicySection(
            title: 'Overview',
            body:
                'CalorieFit is a local-first calorie and nutrition tracker. The app works without an account and stores its main data on your device.',
          ),
          const SizedBox(height: 12),
          _PolicySection(
            title: 'Data Stored On Device',
            body:
                'The app stores foods, meal templates, nutrition targets, history, and retention settings locally using on-device storage and SQLite.',
          ),
          const SizedBox(height: 12),
          _PolicySection(
            title: 'Internet Access',
            body:
                'Internet access is only used when you choose the optional USDA food search. Search terms are sent to the USDA FoodData Central API over the network to return food matches.',
          ),
          const SizedBox(height: 12),
          _PolicySection(
            title: 'Accounts And Sharing',
            body:
                'CalorieFit does not currently require an account. At this stage, the app does not upload your food logs or settings to a CalorieFit backend.',
          ),
          const SizedBox(height: 12),
          _PolicySection(
            title: 'Retention And Deletion',
            body:
                'You can delete local foods, templates, and log entries in the app. You can also change history retention settings or uninstall the app to remove locally stored data from the device.',
          ),
          const SizedBox(height: 12),
          _PolicySection(
            title: 'Contact',
            body:
                '$kPrivacyPolicyContactName\n$kPrivacyPolicyContactEmail',
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String body;

  const _PolicySection({
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}

