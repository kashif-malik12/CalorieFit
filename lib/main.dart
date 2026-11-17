// lib/main.dart

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common/sqflite.dart' as common;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'data/db.dart';
import 'data/models.dart';
import 'services/food_search.dart';
import 'services/auth_service.dart';
import 'services/theme_service.dart';
import 'services/barcode_service.dart';
import 'services/reminder_service.dart';
import 'screens/analytics_screen.dart';
import 'screens/report_screen.dart';
import 'screens/reminders_dialog.dart';
import 'screens/backup_sync_dialog.dart';
import 'screens/barcode_scanner_screen.dart';
import 'screens/fasting_screen.dart';
import 'screens/exercise_screen.dart';
import 'screens/recipe_builder_screen.dart';
import 'screens/review_prompt_dialog.dart';
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
  await ThemeService.init();

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
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.themeModeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'CalorieFit',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: kBrandPrimary,
            brightness: Brightness.light,
            scaffoldBackgroundColor: kBrandSurface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: kBrandPrimary,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: kBrandPrimary,
            brightness: Brightness.dark,
            appBarTheme: const AppBarTheme(
              surfaceTintColor: Colors.transparent,
            ),
          ),
          home: const InitGate(),
        );
      },
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
              FutureBuilder<AppUser>(
                future: AuthService.instance.getCurrentUser(),
                builder: (ctx, snap) {
                  final user = snap.data ?? const AppUser(id: '', name: 'Guest User', email: '');
                  final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C';

                  return DrawerHeader(
                    margin: EdgeInsets.zero,
                    decoration: const BoxDecoration(
                      color: kBrandPrimary,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white,
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  color: kBrandPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    user.isLoggedIn
                                        ? (user.isAdmin ? 'Admin' : 'Member')
                                        : 'Guest (tap Login)',
                                    style: TextStyle(
                                      color: user.isAdmin ? Colors.amberAccent : Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CalorieFit',
                              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            InkWell(
                              onTap: () {
                                _showLoginDialog(context, () => setState(() {}));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user.isLoggedIn ? 'Account' : 'Login',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Ask Question'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AskQuestionPage(),
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
                      builder: (_) => const _UpcomingFeaturePage(
                        title: 'Join Group Classes',
                        description: 'Interactive live group fitness and nutrition classes are in development. Stay tuned!',
                      ),
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
                      builder: (_) => const _UpcomingFeaturePage(
                        title: 'Find Personal Coach',
                        description: 'Connect with certified personal coaches & dieticians right inside CalorieFit soon. Stay tuned!',
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.scale_outlined),
                title: const Text('Tbsp to Grams Converter'),
                onTap: () {
                  Navigator.pop(context);
                  _showTbspConverterDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.water_drop_outlined, color: Colors.blue),
                title: const Text('Water Tracker'),
                onTap: () {
                  Navigator.pop(context);
                  _showWaterTrackerDialog(context, () => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.monitor_weight_outlined, color: Colors.purple),
                title: const Text('Weight Tracker'),
                onTap: () {
                  Navigator.pop(context);
                  _showWeightTrackerDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.calculate_outlined, color: Colors.teal),
                title: const Text('Goal & TDEE Wizard'),
                onTap: () {
                  Navigator.pop(context);
                  _showGoalWizardDialog(context, () => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.blueAccent),
                title: const Text('Analytics & Visual Charts'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_outlined, color: Colors.teal),
                title: const Text('Health & Nutrition Report'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
                title: const Text('Daily Reminders & Nudges'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const RemindersDialog(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
                title: const Text('Scan / Barcode Lookup'),
                onTap: () {
                  Navigator.pop(context);
                  _openBarcodeScanner(context, () => setState(() {}));
                },
              ),
              ListTile(
                leading: const Icon(Icons.cloud_sync_outlined, color: Colors.cyan),
                title: const Text('Backup & Cloud Sync'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => BackupSyncDialog(
                      onDataRestored: () => setState(() {}),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.file_download_outlined, color: Colors.indigo),
                title: const Text('Export Data (CSV)'),
                onTap: () {
                  Navigator.pop(context);
                  _showExportCsvDialog(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.teal),
                title: const Text('Intermittent Fasting'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FastingScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.fitness_center_outlined, color: Colors.orange),
                title: const Text('Activity & Exercise Burn'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseScreen(
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        onUpdated: () => setState(() {}),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.soup_kitchen_outlined, color: Colors.deepPurple),
                title: const Text('Recipe & Meal Builder'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeBuilderScreen(
                        onSaved: () => setState(() {}),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rate_outlined, color: Colors.amber),
                title: const Text('Rate CalorieFit ⭐'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => const ReviewPromptDialog(),
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
              const Divider(),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.themeModeNotifier,
                builder: (ctx, mode, _) {
                  final isDark = mode == ThemeMode.dark;
                  return SwitchListTile(
                    secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                    title: const Text('Dark Mode'),
                    value: isDark,
                    onChanged: (val) {
                      ThemeService.setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    },
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
      NavigationDestination(icon: Icon(Icons.menu_book), label: 'Booklet'),
    ],
  );
}

const _kMealCategories = [
  'Breakfast',
  'Morning Snack',
  'Lunch',
  'Afternoon Snack',
  'Dinner',
  'Evening Snack',
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
    _microLine(
      fiber: f.fiber,
      sugar: f.sugar,
      sodium: f.sodium,
    ),
    _fatDetailLine(
      saturatedFat: f.saturatedFat,
      transFat: f.transFat,
      cholesterol: f.cholesterol,
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
  required double fiber,
  required double sugar,
  required double sodium,
  required double cholesterol,
  required double saturatedFat,
  required double transFat,
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

  Widget compactNutrientItem({
    required String label,
    required double value,
    required double targetVal,
    required Color color,
    String unit = 'g',
  }) {
    final safeT = targetVal <= 0 ? 1.0 : targetVal;
    final p = (value / safeT).clamp(0.0, 1.0);
    final valStr = value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
    final tgtStr = targetVal.toStringAsFixed(targetVal == targetVal.roundToDouble() ? 0 : 0);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$valStr/$tgtStr$unit',
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: p,
                minHeight: 4,
                color: color,
                backgroundColor: color.withValues(alpha: 0.2),
              ),
            ),
          ],
        ),
      ),
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
            child: LinearProgressIndicator(value: progress, minHeight: 8),
          ),
          const SizedBox(height: 12),
          // Compact row 1: Protein, Carbs, Fat
          Row(
            children: [
              compactNutrientItem(
                label: 'Protein',
                value: totals.protein,
                targetVal: targets.protein.toDouble(),
                color: const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              compactNutrientItem(
                label: 'Carbs',
                value: totals.carbs,
                targetVal: targets.carbs.toDouble(),
                color: const Color(0xFF2196F3),
              ),
              const SizedBox(width: 8),
              compactNutrientItem(
                label: 'Fat',
                value: totals.fat,
                targetVal: targets.fat.toDouble(),
                color: const Color(0xFFFF9800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Compact row 2: Fiber, Sugar, Sodium
          Row(
            children: [
              compactNutrientItem(
                label: 'Fiber',
                value: totals.fiber,
                targetVal: targets.fiber.toDouble(),
                color: const Color(0xFF8BC34A),
              ),
              const SizedBox(width: 8),
              compactNutrientItem(
                label: 'Sugar',
                value: totals.sugar,
                targetVal: targets.sugar.toDouble(),
                color: const Color(0xFFE91E63),
              ),
              const SizedBox(width: 8),
              compactNutrientItem(
                label: 'Sodium',
                value: totals.sodium,
                targetVal: targets.sodium.toDouble(),
                color: const Color(0xFF9C27B0),
                unit: 'mg',
              ),
            ],
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
  // Group rows by label; rows are categorized and sorted chronologically by time
  final Map<String, List<Map<String, Object?>>> grouped = {};
  for (final r in rows) {
    var label = (r['label'] as String?)?.trim();
    if (label == 'Post Dinner Snack') label = 'Evening Snack';
    final key = (label != null && label.isNotEmpty) ? label : 'Other';
    grouped.putIfAbsent(key, () => []).add(r);
  }

  final result = <Widget>[];

  void addSection(String cat) {
    final entries = grouped[cat];
    if (entries == null || entries.isEmpty) return;

    // Sort entries chronologically by time
    entries.sort((a, b) {
      final timeA = (a['time'] as String?)?.trim() ?? '';
      final timeB = (b['time'] as String?)?.trim() ?? '';
      if (timeA.isEmpty && timeB.isEmpty) {
        final idA = (a['log_id'] as int?) ?? 0;
        final idB = (b['log_id'] as int?) ?? 0;
        return idA.compareTo(idB);
      }
      if (timeA.isEmpty) return 1;
      if (timeB.isEmpty) return -1;
      return timeA.compareTo(timeB);
    });

    double catKcal = 0;
    for (final r in entries) {
      final entryType = (r['entry_type'] as String?) ?? 'food';
      if (entryType == 'manual') {
        catKcal += ((r['calories'] as num?) ?? 0).toDouble();
      } else {
        final grams = ((r['grams'] as num?) ?? 0).toDouble();
        final base = ((r['base_amount'] as num?) ?? 100).toDouble();
        final cal100 = ((r['calories'] as num?) ?? 0).toDouble();
        catKcal += (cal100 * (grams / (base <= 0 ? 1 : base)));
      }
    }

    result.add(Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Text(
            cat,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
          ),
          if (catKcal > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${catKcal.round()} kcal',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ),
          ],
          const SizedBox(width: 8),
          const Expanded(child: Divider(thickness: 1)),
        ],
      ),
    ));

    for (final r in entries) {
      final logId = r['log_id'] as int;
      final name = (r['name'] as String?) ?? 'Unknown';
      final subtitle = _logSubtitleFromRow(r);
      final timeStr = (r['time'] as String?)?.trim() ?? '';
      final notesStr = (r['notes'] as String?)?.trim() ?? '';

      result.add(Card(
        child: ListTile(
          isThreeLine: true,
          title: Row(
            children: [
              Expanded(
                child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (timeStr.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 12, color: Theme.of(context).colorScheme.onPrimaryContainer),
                      const SizedBox(width: 3),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle),
              if (notesStr.isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 13, color: Colors.teal),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        notesStr,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: Colors.teal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: Colors.green),
              title: const Text('Scan / Barcode Lookup'),
              subtitle: const Text('Lookup packaged food by barcode'),
              onTap: () => Navigator.pop(ctx, 'barcode'),
            ),
            ListTile(
              leading: const Icon(Icons.soup_kitchen_outlined, color: Colors.deepPurple),
              title: const Text('Create Recipe / Dish'),
              subtitle: const Text('Combine foods into custom meal'),
              onTap: () => Navigator.pop(ctx, 'recipe'),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center_outlined, color: Colors.orange),
              title: const Text('Log Workout / Activity'),
              subtitle: const Text('Track calories burned and steps'),
              onTap: () => Navigator.pop(ctx, 'exercise'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_all, color: Colors.blue),
              title: const Text("Copy yesterday's meals"),
              subtitle: const Text('Duplicate yesterday into today'),
              onTap: () => Navigator.pop(ctx, 'copy_yesterday'),
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
      case 'barcode':
        await _openBarcodeScanner(context, () => setState(() {}));
        break;
      case 'recipe':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeBuilderScreen(
              onSaved: () => setState(() {}),
            ),
          ),
        );
        break;
      case 'exercise':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseScreen(
              date: _date,
              onUpdated: () => setState(() {}),
            ),
          ),
        );
        break;
      case 'copy_yesterday':
        await _copyYesterdayMeals();
        break;
    }
  }

  Future<void> _copyYesterdayMeals() async {
    final now = DateTime.tryParse(_date) ?? DateTime.now();
    final yesterdayStr = _fmtDate(now.subtract(const Duration(days: 1)));
    final count = await AppDb.instance.copyEntriesFromDate(
      sourceDate: yesterdayStr,
      targetDate: _date,
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count > 0
              ? 'Copied $count meal entries from yesterday ($yesterdayStr)!'
              : 'No entries found for yesterday ($yesterdayStr)',
        ),
      ),
    );
  }

  Future<void> _addLogEntryFromFoods() async {
    Food? selected;
    List<FoodServing> servings = [];
    final amountCtrl = TextEditingController(text: '1');
    final searchCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedLabel = 'Breakfast';
    TimeOfDay selectedTime = TimeOfDay.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setInner) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                              selected == null ? 'Select food from My Foods' : selected!.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (selected != null)
                            TextButton.icon(
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Change'),
                              onPressed: () => setInner(() {
                                selected = null;
                                servings = [];
                              }),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (selected == null) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Search My Foods',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (_) => setInner(() {}),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 320,
                          child: FutureBuilder<List<Food>>(
                            future: AppDb.instance.getUserFoods(query: searchCtrl.text.trim()),
                            builder: (ctx, snap) {
                              if (snap.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final list = snap.data ?? const <Food>[];
                              if (list.isEmpty) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Text('No foods found. Add foods in My Foods or import from Booklet.'),
                                  ),
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
                                    onTap: () async {
                                      final srvs = f.id != null
                                          ? await AppDb.instance.getFoodServings(f.id!)
                                          : <FoodServing>[];
                                      setInner(() {
                                        selected = f;
                                        servings = srvs;
                                        amountCtrl.text = '1';
                                      });
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ] else ...[
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
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount eaten',
                            suffixText: selected!.unit,
                            helperText: 'Nutrition is ${_baseLabel(selected!)}',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedLabel,
                          decoration: const InputDecoration(
                            labelText: 'Meal category',
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
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
                        const SizedBox(height: 10),
                        TextField(
                          controller: notesCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            prefixIcon: Icon(Icons.note_alt_outlined),
                            hintText: 'e.g. post-workout, felt great',
                          ),
                        ),
                        const SizedBox(height: 14),
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
                                notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                              ),
                            );

                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                          child: const Text('Add to Log'),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addQuickManualEntry() async {
  final nameCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
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
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: Icon(Icons.note_alt_outlined),
                    ),
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
                        notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
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

    String currentLabel = label;
    TimeOfDay currentTime = time;

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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: currentLabel,
                            decoration: const InputDecoration(
                              labelText: 'Meal category',
                              prefixIcon: Icon(Icons.sell_outlined),
                              isDense: true,
                            ),
                            items: _kMealCategories
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setInner(() => currentLabel = v ?? 'Breakfast'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(_fmtTime(currentTime)),
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: currentTime);
                            if (picked != null) setInner(() => currentTime = picked);
                          },
                        ),
                      ],
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
                                time: _fmtTime(currentTime),
                                label: currentLabel,
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
                                    fiber: totals.fiber,
                                    sugar: totals.sugar,
                                    sodium: totals.sodium,
                                    cholesterol: totals.cholesterol,
                                    saturatedFat: totals.saturatedFat,
                                    transFat: totals.transFat,
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
          IconButton(
            tooltip: 'Visual Analytics & Charts',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
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
                FutureBuilder<ReminderSettings>(
                  future: ReminderService.instance.loadSettings(),
                  builder: (_, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final notice = ReminderService.instance.getNextReminderNotice(snap.data!);
                    if (notice == null) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notice,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                          InkWell(
                            onTap: () async {
                              await showDialog(context: context, builder: (_) => const RemindersDialog());
                              if (mounted) setState(() {});
                            },
                            child: const Text('Edit', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
               Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Health tools',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            FutureBuilder<int>(
              future: AppDb.instance.getStreakCount(),
              builder: (_, snap) {
                final streak = snap.data ?? 0;
                if (streak <= 0) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '$streak Day${streak == 1 ? "" : "s"} Streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.bar_chart, color: Colors.blueAccent),
              label: const Text('Charts & Trends'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.assignment_outlined, color: Colors.teal),
              label: const Text('Health Report'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.notifications_active_outlined, color: Colors.orange),
              label: const Text('Reminders'),
              onPressed: () async {
                await showDialog(context: context, builder: (_) => const RemindersDialog());
                if (mounted) setState(() {});
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.timer_outlined, color: Colors.teal),
              label: const Text('Fasting Timer'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FastingScreen()),
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.fitness_center_outlined, color: Colors.orange),
              label: const Text('Activity & Workouts'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseScreen(
                      date: _date,
                      onUpdated: () => setState(() {}),
                    ),
                  ),
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.soup_kitchen_outlined, color: Colors.deepPurple),
              label: const Text('Recipe Builder'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeBuilderScreen(
                      onSaved: () => setState(() {}),
                    ),
                  ),
                );
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.monitor_weight_outlined),
              label: const Text('BMI & calories'),
              onPressed: () async {
                await showBmiAndCalorieToolsDialog(context, _date);
                if (mounted) setState(() {});
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.calculate_outlined, color: Colors.teal),
              label: const Text('Goal & TDEE Wizard'),
              onPressed: () => _showGoalWizardDialog(context, () => setState(() {})),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.monitor_weight, color: Colors.purple),
              label: const Text('Weight Tracker'),
              onPressed: () => _showWeightTrackerDialog(context),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.insights, color: Colors.indigo),
              label: const Text('Weekly Overview'),
              onPressed: () => _showWeeklySummaryDialog(context, _date),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Edit targets'),
              onPressed: () async {
                await editTargetsForDateOneDialog(context, _date);
                if (mounted) setState(() {});
              },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.scale_outlined),
              label: const Text('Tbsp converter'),
              onPressed: () => _showTbspConverterDialog(context),
            ),
          ],
        ),
      ],
    ),
  ),
),
const SizedBox(height: 12),
_buildWaterTrackerCard(context, _date, () => setState(() {})),
const SizedBox(height: 12),
FutureBuilder<double>(
  future: AppDb.instance.getTotalExerciseCaloriesForDate(_date),
  builder: (_, snap) {
    final burned = snap.data ?? 0.0;
    if (burned <= 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${burned.round()} kcal burned in workouts today',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  'Net Calories: ${(totals.calories - burned).round()} kcal',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ExerciseScreen(date: _date, onUpdated: () => setState(() {})),
                ),
              );
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  },
),
                _progressBarCalories(taken: totals.calories.round(), target: targets.calories, totals: totals, targets: targets),
                const SizedBox(height: 12),
                _targetsTable(totals: totals, targets: targets),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Text('No entries yet. Tap + to add what you ate.'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.copy_all, color: Colors.blue),
                          label: const Text("Copy yesterday's meals"),
                          onPressed: _copyYesterdayMeals,
                        ),
                      ],
                    ),
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
  bool _favoritesOnly = false;

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
            tooltip: 'Scan Barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _showBarcodeLookupDialog(context, () => setState(() {})),
          ),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Search My Foods', prefixIcon: Icon(Icons.search)),
                    onChanged: (v) => setState(() => _q = v),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: Icon(
                    Icons.star,
                    size: 16,
                    color: _favoritesOnly ? Colors.amber : Colors.grey,
                  ),
                  label: const Text('Favorites'),
                  selected: _favoritesOnly,
                  onSelected: (val) => setState(() => _favoritesOnly = val),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<Food>>(
                future: AppDb.instance.getUserFoods(query: _q, favoritesOnly: _favoritesOnly),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final foods = snap.data ?? const <Food>[];
                  if (foods.isEmpty) {
                    return Center(
                      child: Text(
                        _favoritesOnly
                            ? 'No favorite foods yet. Tap the star icon on any food to favorite it!'
                            : 'No foods yet. Add or import from Booklet.',
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: foods.length,
                    itemBuilder: (_, i) {
                      final f = foods[i];
                      return Card(
                        child: ListTile(
                          isThreeLine: true,
                          leading: IconButton(
                            icon: Icon(
                              f.isFavorite ? Icons.star : Icons.star_border,
                              color: f.isFavorite ? Colors.amber : Colors.grey,
                            ),
                            tooltip: f.isFavorite ? 'Remove favorite' : 'Add to favorites',
                            onPressed: () async {
                              await AppDb.instance.toggleFoodFavorite(f.id!, !f.isFavorite);
                              setState(() {});
                            },
                          ),
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

// ---------------- BOOKLET PAGE ----------------

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
        title: const BrandedAppBarTitle(title: 'Booklet'),
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
            decoration: const InputDecoration(labelText: 'Search booklet foods', prefixIcon: Icon(Icons.search)),
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
              labelText: 'Search booklet templates',
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
                  return const Center(child: Text('No booklet templates found.'));
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
                            fiber: totals.fiber,
                            sugar: totals.sugar,
                            sodium: totals.sodium,
                            cholesterol: totals.cholesterol,
                            saturatedFat: totals.saturatedFat,
                            transFat: totals.transFat,
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
            fiber: totals.fiber,
            sugar: totals.sugar,
            sodium: totals.sodium,
            cholesterol: totals.cholesterol,
            saturatedFat: totals.saturatedFat,
            transFat: totals.transFat,
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
                          Expanded(
                            child: Text(
                              selected == null ? 'Add food to template' : selected!.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (selected != null)
                            TextButton.icon(
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Change'),
                              onPressed: () => setInner(() {
                                selected = null;
                                servings = [];
                              }),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (selected == null) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
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
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Text(
                                    'No My Foods found. Import from Booklet first.',
                                  ),
                                ),
                              );
                            }

                            return SizedBox(
                              height: 280,
                              child: ListView.builder(
                                itemCount: foods.length,
                                itemBuilder: (_, i) {
                                  final f = foods[i];
                                  return ListTile(
                                    isThreeLine: true,
                                    title: Text(f.name),
                                    subtitle: Text(_foodListSubtitle(f)),
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
                      ] else ...[
                        Text(
                          _foodListSubtitle(selected!),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                                  '${s.name} (${_numStr(s.grams)} ${selected!.unit})',
                                ),
                                onPressed: () => setInner(
                                  () => amountCtrl.text = _numStr(s.grams),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        TextField(
                          controller: amountCtrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            suffixText: unitSuffix,
                            helperText: 'Nutrition is ${_baseLabel(selected!)}',
                          ),
                        ),
                        const SizedBox(height: 14),
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
                          child: const Text('Add to Template'),
                        ),
                      ],
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
    Food? currentFood = food;
    var servings = currentFood?.id != null
        ? await AppDb.instance.getFoodServings(currentFood!.id!)
        : <FoodServing>[];
    final amountCtrl = TextEditingController(
      text: item.amount.toStringAsFixed(
        item.amount == item.amount.roundToDouble() ? 0 : 1,
      ),
    );
    bool isPickingFood = false;
    final searchCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isPickingFood ? 'Change food' : (currentFood?.name ?? 'Edit Food'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!isPickingFood && currentFood != null)
                            TextButton.icon(
                              icon: const Icon(Icons.swap_horiz, size: 18),
                              label: const Text('Change food'),
                              onPressed: () => setInner(() => isPickingFood = true),
                            ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      if (isPickingFood) ...[
                        TextField(
                          controller: searchCtrl,
                          autofocus: true,
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
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('No foods found.')),
                              );
                            }
                            return SizedBox(
                              height: 240,
                              child: ListView.builder(
                                itemCount: foods.length,
                                itemBuilder: (_, i) {
                                  final f = foods[i];
                                  return ListTile(
                                    title: Text(f.name),
                                    subtitle: Text(_foodListSubtitle(f)),
                                    onTap: () async {
                                      final srvs = f.id != null
                                          ? await AppDb.instance.getFoodServings(f.id!)
                                          : <FoodServing>[];
                                      setInner(() {
                                        currentFood = f;
                                        servings = srvs;
                                        isPickingFood = false;
                                        amountCtrl.text = '1';
                                      });
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        if (currentFood != null)
                          Text(
                            _foodListSubtitle(currentFood!),
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                                  '${s.name} (${_numStr(s.grams)} ${currentFood?.unit ?? item.unit})',
                                ),
                                onPressed: () {
                                  setInner(() => amountCtrl.text = _numStr(s.grams));
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: amountCtrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Amount',
                            suffixText: currentFood?.unit ?? item.unit,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                              foodId: currentFood?.id,
                              unit: currentFood?.unit,
                              baseAmount: currentFood?.baseAmount,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) setState(() {});
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
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
                final fiber = (food?.fiber ?? 0) * factor;
                final sugar = (food?.sugar ?? 0) * factor;
                final sodium = (food?.sodium ?? 0) * factor;
                final cholesterol = (food?.cholesterol ?? 0) * factor;
                final saturatedFat = (food?.saturatedFat ?? 0) * factor;
                final transFat = (food?.transFat ?? 0) * factor;

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
                      )}\n'
                      '${_microLine(
                        fiber: fiber,
                        sugar: sugar,
                        sodium: sodium,
                      )}\n'
                      '${_fatDetailLine(
                        saturatedFat: saturatedFat,
                        transFat: transFat,
                        cholesterol: cholesterol,
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
          IconButton(
            tooltip: 'Visual Analytics & Charts',
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
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
  final String? description;
  const _UpcomingFeaturePage({required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                description ?? 'Stay tuned - this is coming soon!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
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

// ---------------- LOGIN & PROFILE DIALOG ----------------

Future<void> _showLoginDialog(BuildContext context, VoidCallback onUpdated) async {
  final user = AuthService.currentUser;
  final nameCtrl = TextEditingController(text: user.isLoggedIn ? user.name : '');
  bool isAdmin = user.isAdmin;

  await showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(user.isLoggedIn ? 'Account Profile' : 'Login / Register'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (user.isLoggedIn) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: user.isAdmin ? Colors.orange : Colors.teal,
                        child: Icon(
                          user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Role: ${user.isAdmin ? "Coach / Admin" : "Member"}\nUser ID: ${user.userId}',
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: user.isLoggedIn ? 'Display Name' : 'Enter your name or nickname',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.shuffle),
                        tooltip: 'Generate random name',
                        onPressed: () {
                          nameCtrl.text = AuthService.getRandomName();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Admin / Coach mode', style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Allows answering community questions with certified badge',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: isAdmin,
                    onChanged: (val) {
                      setDialogState(() => isAdmin = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              if (user.isLoggedIn)
                TextButton(
                  onPressed: () async {
                    await AuthService.logout();
                    if (ctx.mounted) Navigator.pop(ctx);
                    onUpdated();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Log Out'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;
                  await AuthService.login(name: name, isAdmin: isAdmin);
                  if (ctx.mounted) Navigator.pop(ctx);
                  onUpdated();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Profile saved: $name')),
                    );
                  }
                },
                child: Text(user.isLoggedIn ? 'Update' : 'Log In'),
              ),
            ],
          );
        },
      );
    },
  );
}

// ---------------- TBSP TO GRAMS CONVERTER ----------------

void _showTbspConverterDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _TbspToGramsConverterSheet(),
  );
}

class _TbspToGramsConverterSheet extends StatefulWidget {
  const _TbspToGramsConverterSheet();

  @override
  State<_TbspToGramsConverterSheet> createState() => _TbspToGramsConverterSheetState();
}

class _TbspDensityItem {
  final String name;
  final double gramsPerTbsp;
  final String icon;
  const _TbspDensityItem(this.name, this.gramsPerTbsp, this.icon);
}

class _TbspToGramsConverterSheetState extends State<_TbspToGramsConverterSheet> {
  static const List<_TbspDensityItem> _items = [
    _TbspDensityItem('Olive Oil', 13.5, '🫒'),
    _TbspDensityItem('Water / Milk', 15.0, '💧'),
    _TbspDensityItem('Butter / Ghee (melted)', 14.2, '🧈'),
    _TbspDensityItem('Honey / Maple Syrup', 21.0, '🍯'),
    _TbspDensityItem('Peanut Butter', 16.0, '🥜'),
    _TbspDensityItem('Granulated Sugar', 12.5, '🍬'),
    _TbspDensityItem('All-Purpose Flour', 8.0, '🌾'),
    _TbspDensityItem('Greek Yogurt', 15.0, '🥣'),
    _TbspDensityItem('Soy Sauce', 16.0, '🍶'),
  ];

  _TbspDensityItem _selected = _items[0];
  final TextEditingController _tbspCtrl = TextEditingController(text: '1');
  final TextEditingController _gramsCtrl = TextEditingController(text: '13.5');
  bool _isUpdating = false;

  void _onTbspChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    final tbsp = double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    final grams = tbsp * _selected.gramsPerTbsp;
    _gramsCtrl.text = grams == grams.roundToDouble()
        ? grams.toStringAsFixed(0)
        : grams.toStringAsFixed(1);
    _isUpdating = false;
  }

  void _onGramsChanged(String val) {
    if (_isUpdating) return;
    _isUpdating = true;
    final grams = double.tryParse(val.trim().replaceAll(',', '.')) ?? 0.0;
    final tbsp = _selected.gramsPerTbsp > 0 ? grams / _selected.gramsPerTbsp : 0.0;
    _tbspCtrl.text = tbsp == tbsp.roundToDouble()
        ? tbsp.toStringAsFixed(0)
        : tbsp.toStringAsFixed(2);
    _isUpdating = false;
  }

  void _applyTbspPreset(double tbsp) {
    _tbspCtrl.text = tbsp == tbsp.roundToDouble()
        ? tbsp.toStringAsFixed(0)
        : tbsp.toStringAsFixed(1);
    _onTbspChanged(_tbspCtrl.text);
    setState(() {});
  }

  @override
  void dispose() {
    _tbspCtrl.dispose();
    _gramsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.scale, color: Colors.teal),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Tbsp to Grams Converter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_TbspDensityItem>(
              value: _selected,
              decoration: const InputDecoration(
                labelText: 'Ingredient Density',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _items.map((item) {
                return DropdownMenuItem<_TbspDensityItem>(
                  value: item,
                  child: Text('${item.icon} ${item.name} (${item.gramsPerTbsp}g / tbsp)'),
                );
              }).toList(),
              onChanged: (item) {
                if (item != null) {
                  setState(() {
                    _selected = item;
                  });
                  _onTbspChanged(_tbspCtrl.text);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tbspCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Tablespoons (tbsp)',
                      border: OutlineInputBorder(),
                      suffixText: 'tbsp',
                    ),
                    onChanged: _onTbspChanged,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(Icons.swap_horiz, color: Colors.grey),
                ),
                Expanded(
                  child: TextField(
                    controller: _gramsCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Grams (g)',
                      border: OutlineInputBorder(),
                      suffixText: 'g',
                    ),
                    onChanged: _onGramsChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  label: const Text('0.5 tbsp'),
                  onPressed: () => _applyTbspPreset(0.5),
                ),
                ActionChip(
                  label: const Text('1 tbsp'),
                  onPressed: () => _applyTbspPreset(1.0),
                ),
                ActionChip(
                  label: const Text('1.5 tbsp'),
                  onPressed: () => _applyTbspPreset(1.5),
                ),
                ActionChip(
                  label: const Text('2 tbsp'),
                  onPressed: () => _applyTbspPreset(2.0),
                ),
                ActionChip(
                  label: const Text('3 tbsp'),
                  onPressed: () => _applyTbspPreset(3.0),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '1 tbsp of ${_selected.name} ≈ ${_selected.gramsPerTbsp} grams.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- ASK QUESTION MODULE ----------------

class AskQuestionPage extends StatefulWidget {
  const AskQuestionPage({super.key});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  int _unreadCount = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final user = AuthService.currentUser;
    final questions = await AppDb.instance.getQuestionsWithReplies();
    int unread = 0;
    if (user.userId.isNotEmpty) {
      unread = await AppDb.instance.getUnreadNotificationCount(user.userId);
    }
    if (mounted) {
      setState(() {
        _questions = questions;
        _unreadCount = unread;
        _isLoading = false;
      });
    }
  }

  Future<void> _showAskDialog() async {
    final user = AuthService.currentUser;
    final questionCtrl = TextEditingController();
    bool useRandomName = !user.isLoggedIn;
    String randomName = AuthService.getRandomName();

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final authorName = useRandomName ? randomName : (user.isLoggedIn ? user.name : 'Anonymous');
            return AlertDialog(
              title: const Text('Ask a Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: questionCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type your question about nutrition, calorie deficit, exercises, or healthy foods...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Posting As:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(user.isLoggedIn ? 'My name (${user.name})' : 'Login / My name'),
                      subtitle: !user.isLoggedIn ? const Text('Tap to set your profile name', style: TextStyle(fontSize: 11)) : null,
                      value: false,
                      groupValue: useRandomName,
                      onChanged: (val) {
                        if (!user.isLoggedIn) {
                          _showLoginDialog(context, () {
                            setDialogState(() {});
                          });
                        } else {
                          setDialogState(() => useRandomName = false);
                        }
                      },
                    ),
                    RadioListTile<bool>(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(child: Text('Random name ($randomName)')),
                          IconButton(
                            icon: const Icon(Icons.shuffle, size: 18),
                            tooltip: 'Generate new random nickname',
                            onPressed: () {
                              setDialogState(() {
                                randomName = AuthService.getRandomName();
                              });
                            },
                          ),
                        ],
                      ),
                      value: true,
                      groupValue: useRandomName,
                      onChanged: (val) {
                        setDialogState(() => useRandomName = true);
                      },
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
                  onPressed: () async {
                    final qText = questionCtrl.text.trim();
                    if (qText.isEmpty) return;
                    await AppDb.instance.insertQuestion(
                      userId: user.userId,
                      authorName: authorName,
                      isRandomName: useRandomName,
                      question: qText,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Question submitted publicly!')),
                      );
                    }
                  },
                  child: const Text('Post Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showReplyDialog(int questionId, String questionText, String targetUserId) async {
    final user = AuthService.currentUser;
    final replyCtrl = TextEditingController();
    bool asAdmin = user.isAdmin;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Reply to Question'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        questionText,
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: replyCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Write reply...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reply as Certified Coach / Admin', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Adds verified coach checkmark to response', style: TextStyle(fontSize: 11)),
                      value: asAdmin,
                      onChanged: (val) {
                        setDialogState(() => asAdmin = val);
                      },
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
                  onPressed: () async {
                    final replyText = replyCtrl.text.trim();
                    if (replyText.isEmpty) return;
                    await AppDb.instance.insertQuestionReply(
                      questionId: questionId,
                      replyText: replyText,
                      adminName: asAdmin ? '${user.name} (Coach)' : user.name,
                      targetUserId: targetUserId,
                      questionPreview: questionText,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reply posted!')),
                      );
                    }
                  },
                  child: const Text('Send Reply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showNotificationsSheet() async {
    final user = AuthService.currentUser;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _QuestionNotificationsSheet(
        userId: user.userId,
        onChanged: _loadData,
      ),
    );
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Q&A'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: 'Notifications',
                onPressed: _showNotificationsSheet,
              ),
              if (_unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'No questions yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ask the community or an admin coach any fitness question!',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.add_comment),
                        label: const Text('Ask a Question'),
                        onPressed: _showAskDialog,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _questions.length,
                  itemBuilder: (ctx, i) {
                    final q = _questions[i];
                    final qId = q['id'] as int;
                    final authorName = q['author_name'] as String? ?? 'Anonymous';
                    final targetUserId = q['user_id'] as String? ?? '';
                    final questionText = q['question'] as String? ?? '';
                    final createdAt = q['created_at'] as String? ?? '';
                    final replies = (q['replies'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        authorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        createdAt,
                                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.reply, size: 16),
                                  label: const Text('Reply'),
                                  onPressed: () => _showReplyDialog(qId, questionText, targetUserId),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              questionText,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            if (replies.isNotEmpty) ...[
                              const Divider(height: 24),
                              Text(
                                'Replies (${replies.length})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...replies.map((r) {
                                final rAuthor = (r['admin_name'] ?? r['author_name']) as String? ?? 'Coach';
                                final rText = (r['reply_text'] ?? r['reply']) as String? ?? '';
                                final rIsAdmin = rAuthor.contains('(Coach)') ||
                                    rAuthor.contains('(Admin)') ||
                                    (r['is_admin'] as int? ?? 1) == 1;
                                final rDate = r['created_at'] as String? ?? '';

                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: rIsAdmin
                                        ? Colors.teal.withValues(alpha: 0.08)
                                        : Colors.grey.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: rIsAdmin
                                        ? Border.all(color: Colors.teal.withValues(alpha: 0.3))
                                        : null,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            rAuthor,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (rIsAdmin) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.teal,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.verified, size: 12, color: Colors.white),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'COACH / ADMIN',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            rDate,
                                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(rText, style: const TextStyle(fontSize: 14)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_comment),
        label: const Text('Ask Question'),
        onPressed: _showAskDialog,
      ),
    );
  }
}

class _QuestionNotificationsSheet extends StatefulWidget {
  final String userId;
  final VoidCallback onChanged;

  const _QuestionNotificationsSheet({
    required this.userId,
    required this.onChanged,
  });

  @override
  State<_QuestionNotificationsSheet> createState() => _QuestionNotificationsSheetState();
}

class _QuestionNotificationsSheetState extends State<_QuestionNotificationsSheet> {
  List<Map<String, Object?>> _notifs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifs();
  }

  Future<void> _loadNotifs() async {
    setState(() => _isLoading = true);
    final list = await AppDb.instance.getNotificationsForUser(widget.userId);
    if (mounted) {
      setState(() {
        _notifs = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.teal),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Question Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_notifs.any((n) => (n['is_read'] as int? ?? 0) == 0))
                TextButton(
                  onPressed: () async {
                    await AppDb.instance.markAllNotificationsAsRead(widget.userId);
                    widget.onChanged();
                    await _loadNotifs();
                  },
                  child: const Text('Mark all read'),
                ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_notifs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _notifs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final n = _notifs[i];
                  final nId = n['id'] as int;
                  final msg = n['message'] as String? ?? '';
                  final date = n['created_at'] as String? ?? '';
                  final isRead = (n['is_read'] as int? ?? 0) == 1;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: isRead ? Colors.grey[200] : Colors.teal.withValues(alpha: 0.2),
                      child: Icon(
                        isRead ? Icons.mark_email_read : Icons.mark_email_unread,
                        color: isRead ? Colors.grey : Colors.teal,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      msg,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(date, style: const TextStyle(fontSize: 11)),
                    trailing: isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.check, size: 18),
                            tooltip: 'Mark as read',
                            onPressed: () async {
                              await AppDb.instance.markNotificationAsRead(nId);
                              widget.onChanged();
                              await _loadNotifs();
                            },
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- WATER INTAKE WIDGETS & DIALOGS ----------------

Widget _buildWaterTrackerCard(BuildContext context, String date, VoidCallback onUpdated) {
  return FutureBuilder<WaterLog>(
    future: AppDb.instance.getWaterLog(date),
    builder: (ctx, snap) {
      final water = snap.data ?? WaterLog(date: date, amountMl: 0, targetMl: 2000);
      final pct = water.targetMl > 0 ? (water.amountMl / water.targetMl).clamp(0.0, 1.0) : 0.0;
      final glasses = (water.amountMl / 250).floor();
      final targetGlasses = (water.targetMl / 250).ceil();

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Water Tracker',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '${water.amountMl} / ${water.targetMl} ml',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    tooltip: 'Set water target',
                    onPressed: () => _showSetWaterTargetDialog(context, date, water.targetMl, onUpdated),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 10,
                  backgroundColor: Colors.blue.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(pct * 100).toInt()}% • $glasses of $targetGlasses glasses',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove, size: 16),
                        tooltip: '-250 ml',
                        onPressed: water.amountMl <= 0
                            ? null
                            : () async {
                                await AppDb.instance.updateWaterAmount(date, -250);
                                onUpdated();
                              },
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('+250 ml'),
                        onPressed: () async {
                          await AppDb.instance.updateWaterAmount(date, 250);
                          onUpdated();
                        },
                      ),
                      const SizedBox(width: 6),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.local_drink, size: 16),
                        label: const Text('+500 ml'),
                        onPressed: () async {
                          await AppDb.instance.updateWaterAmount(date, 500);
                          onUpdated();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showSetWaterTargetDialog(BuildContext context, String date, int currentTarget, VoidCallback onUpdated) async {
  final ctrl = TextEditingController(text: currentTarget.toString());
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Daily Water Target'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Target in ml',
              suffixText: 'ml',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [1500, 2000, 2500, 3000].map((ml) {
              return ActionChip(
                label: Text('$ml ml'),
                onPressed: () => ctrl.text = ml.toString(),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            final target = int.tryParse(ctrl.text.trim()) ?? 2000;
            if (target > 0) {
              await AppDb.instance.setWaterTarget(date, target);
              if (ctx.mounted) Navigator.pop(ctx);
              onUpdated();
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

void _showWaterTrackerDialog(BuildContext context, VoidCallback onUpdated) {
  final nowStr = _fmtDate(DateTime.now());
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop, color: Colors.blue, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Daily Water Intake',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ],
          ),
          const SizedBox(height: 16),
          _buildWaterTrackerCard(ctx, nowStr, onUpdated),
          const SizedBox(height: 16),
          const Text(
            'Drinking enough water aids digestion, boosts metabolism, and keeps hunger signals in check during your calorie deficit.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    ),
  );
}

// ---------------- WEIGHT TRACKER ----------------

void _showWeightTrackerDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _WeightTrackerSheet(),
  );
}

class _WeightTrackerSheet extends StatefulWidget {
  const _WeightTrackerSheet();

  @override
  State<_WeightTrackerSheet> createState() => _WeightTrackerSheetState();
}

class _WeightTrackerSheetState extends State<_WeightTrackerSheet> {
  final _weightCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _unit = 'kg';
  final String _date = _fmtDate(DateTime.now());
  List<WeightLog> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final logs = await AppDb.instance.getWeightLogs();
    if (mounted) {
      setState(() {
        _logs = logs;
        _isLoading = false;
        if (logs.isNotEmpty && _weightCtrl.text.isEmpty) {
          _unit = logs.first.unit;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WeightLog? latest = _logs.isNotEmpty ? _logs.first : null;
    WeightLog? previous = _logs.length > 1 ? _logs[1] : null;
    double? diff;
    if (latest != null && previous != null) {
      diff = latest.weight - previous.weight;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.monitor_weight, color: Colors.purple, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Weight Tracker',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            if (latest != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Latest Weight', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text(
                          '${latest.weight} ${latest.unit}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                        ),
                        Text(latest.date, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                    if (diff != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: diff <= 0 ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(diff <= 0 ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: diff <= 0 ? Colors.green : Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              '${diff.abs().toStringAsFixed(1)} ${latest.unit}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: diff <= 0 ? Colors.green[800] : Colors.orange[800]),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('Log Today\'s Weight', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      border: const OutlineInputBorder(),
                      suffixText: _unit,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                    items: const [
                      DropdownMenuItem(value: 'kg', child: Text('kg')),
                      DropdownMenuItem(value: 'lbs', child: Text('lbs')),
                    ],
                    onChanged: (v) => setState(() => _unit = v ?? 'kg'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (e.g. morning, fasting)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Save Weight Entry'),
              onPressed: () async {
                final w = double.tryParse(_weightCtrl.text.trim().replaceAll(',', '.')) ?? 0;
                if (w <= 0) return;
                await AppDb.instance.insertWeightLog(
                  date: _date,
                  weight: w,
                  unit: _unit,
                  notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                );
                _weightCtrl.clear();
                _notesCtrl.clear();
                await _loadLogs();
              },
            ),
            const SizedBox(height: 16),
            const Text('History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_logs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No weight logs yet. Log your first weight above!')),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _logs.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final item = _logs[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${item.weight} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${item.date}${item.notes != null ? " • ${item.notes}" : ""}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          if (item.id != null) {
                            await AppDb.instance.deleteWeightLog(item.id!);
                            await _loadLogs();
                          }
                        },
                      ),
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

// ---------------- GOAL & TDEE WIZARD ----------------

void _showGoalWizardDialog(BuildContext context, VoidCallback onUpdated) {
  showDialog(
    context: context,
    builder: (ctx) => _GoalWizardDialog(onUpdated: onUpdated),
  );
}

class _GoalWizardDialog extends StatefulWidget {
  final VoidCallback onUpdated;
  const _GoalWizardDialog({required this.onUpdated});

  @override
  State<_GoalWizardDialog> createState() => _GoalWizardDialogState();
}

class _GoalWizardDialogState extends State<_GoalWizardDialog> {
  String _gender = 'male';
  final _ageCtrl = TextEditingController(text: '28');
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '75');
  double _activityMultiplier = 1.375; // Lightly active
  String _goal = 'cut'; // cut, maintain, bulk

  int _calcKcal = 2000;
  int _calcProtein = 150;
  int _calcCarbs = 200;
  int _calcFat = 65;

  @override
  void initState() {
    super.initState();
    _recalculate();
  }

  void _recalculate() {
    final age = double.tryParse(_ageCtrl.text.trim()) ?? 28;
    final height = double.tryParse(_heightCtrl.text.trim()) ?? 175;
    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 75;

    // Mifflin-St Jeor equation
    double bmr;
    if (_gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    final tdee = bmr * _activityMultiplier;
    double targetKcal = tdee;
    if (_goal == 'cut') {
      targetKcal = tdee - 500;
    } else if (_goal == 'bulk') {
      targetKcal = tdee + 350;
    }
    targetKcal = targetKcal.clamp(1200, 5000);

    final pGrams = (weight * 2.0).clamp(60, 300);
    final fatKcal = targetKcal * 0.25;
    final fGrams = (fatKcal / 9).clamp(30, 150);
    final carbKcal = targetKcal - (pGrams * 4) - fatKcal;
    final cGrams = (carbKcal / 4).clamp(50, 600);

    setState(() {
      _calcKcal = targetKcal.round();
      _calcProtein = pGrams.round();
      _calcFat = fGrams.round();
      _calcCarbs = cGrams.round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.calculate, color: Colors.teal),
          SizedBox(width: 8),
          Text('Goal & TDEE Wizard', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'male', label: Text('Male')),
                ButtonSegment(value: 'female', label: Text('Female')),
              ],
              selected: {_gender},
              onSelectionChanged: (s) {
                setState(() => _gender = s.first);
                _recalculate();
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age (yrs)', border: OutlineInputBorder()),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                    onChanged: (_) => _recalculate(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<double>(
              value: _activityMultiplier,
              decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 1.2, child: Text('Sedentary (desk job)')),
                DropdownMenuItem(value: 1.375, child: Text('Light (1-3 days/wk)')),
                DropdownMenuItem(value: 1.55, child: Text('Moderate (3-5 days/wk)')),
                DropdownMenuItem(value: 1.725, child: Text('Very Active (6-7 days/wk)')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _activityMultiplier = v);
                  _recalculate();
                }
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _goal,
              decoration: const InputDecoration(labelText: 'Fitness Goal', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'cut', child: Text('Weight Loss / Cut (-500 kcal)')),
                DropdownMenuItem(value: 'maintain', child: Text('Maintain Weight (TDEE)')),
                DropdownMenuItem(value: 'bulk', child: Text('Muscle Gain / Bulk (+350 kcal)')),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() => _goal = v);
                  _recalculate();
                }
              },
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Text('Recommended Targets', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[800])),
                  const SizedBox(height: 4),
                  Text('$_calcKcal kcal / day', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Protein: ${_calcProtein}g • Carbs: ${_calcCarbs}g • Fat: ${_calcFat}g',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () async {
            await TargetSettings.setCalories(_calcKcal);
            await TargetSettings.setProtein(_calcProtein);
            await TargetSettings.setCarbs(_calcCarbs);
            await TargetSettings.setFat(_calcFat);
            if (context.mounted) Navigator.pop(context);
            widget.onUpdated();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calculated targets saved as your Default Targets!')),
              );
            }
          },
          child: const Text('Apply as Default'),
        ),
      ],
    );
  }
}

// ---------------- WEEKLY OVERVIEW SUMMARY ----------------

Future<void> _showWeeklySummaryDialog(BuildContext context, String date) async {
  final summary = await AppDb.instance.getWeeklySummary(date);
  if (!context.mounted) return;

  double totalKcal = 0;
  double totalP = 0;
  double totalC = 0;
  double totalF = 0;
  for (final d in summary) {
    totalKcal += (d['calories'] as num?)?.toDouble() ?? 0;
    totalP += (d['protein'] as num?)?.toDouble() ?? 0;
    totalC += (d['carbs'] as num?)?.toDouble() ?? 0;
    totalF += (d['fat'] as num?)?.toDouble() ?? 0;
  }
  final avgKcal = (totalKcal / 7).round();
  final avgP = (totalP / 7).round();
  final avgC = (totalC / 7).round();
  final avgF = (totalF / 7).round();

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.insights, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Weekly Overview'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text('7-Day Daily Average', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text('$avgKcal kcal', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 2),
                  Text('P: ${avgP}g • C: ${avgC}g • F: ${avgF}g', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...summary.map((day) {
              final dStr = day['date'] as String;
              final taken = day['calories'] as int;
              final target = day['targetCalories'] as int;
              final pct = target > 0 ? (taken / target).clamp(0.0, 1.5) : 0.0;
              final isOver = taken > target;

              final dt = DateTime.tryParse(dStr) ?? DateTime.now();
              final dayName = DateFormat('E, MMM d').format(dt);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dayName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          '$taken / $target kcal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOver ? Colors.orange[800] : Colors.teal[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct > 1.0 ? 1.0 : pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(isOver ? Colors.orange : Colors.teal),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

// ---------------- BARCODE SCANNER & LOOKUP ----------------

Future<void> _openBarcodeScanner(BuildContext context, VoidCallback onUpdated) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BarcodeScannerScreen(
        onAddProduct: (product, grams, mealCategory) async {
          final f = product.toFood();
          final newId = await AppDb.instance.insertFood(f);
          final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
          final timeStr = DateFormat('HH:mm').format(DateTime.now());
          await AppDb.instance.insertLog(
            LogEntry(
              date: todayStr,
              foodId: newId,
              grams: grams,
              unit: 'g',
              baseAmount: 100,
              label: mealCategory,
              time: timeStr,
              foodName: f.name,
              calories100: f.calories,
              protein100: f.protein,
              carbs100: f.carbs,
              fat100: f.fat,
              fiber100: f.fiber,
              sugar100: f.sugar,
              sodium100: f.sodium,
            ),
          );
          onUpdated();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logged ${grams.round()}g of "${product.name}" ($mealCategory)!')),
            );
          }
        },
      ),
    ),
  );
  onUpdated();
}

Future<void> _showBarcodeLookupDialog(BuildContext context, VoidCallback onUpdated) async {
  final barcodeCtrl = TextEditingController();
  OpenFoodProduct? foundProduct;
  bool isSearching = false;
  String? errorMsg;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.green),
              SizedBox(width: 8),
              Text('Barcode Lookup'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Open Camera Scanner View'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _openBarcodeScanner(context, onUpdated);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Enter product barcode',
                    hintText: 'e.g. 3017620422003',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () async {
                        final code = barcodeCtrl.text.trim();
                        if (code.isEmpty) return;
                        setDialogState(() {
                          isSearching = true;
                          errorMsg = null;
                        });
                        final p = await BarcodeService.fetchProduct(code);
                        setDialogState(() {
                          isSearching = false;
                          foundProduct = p;
                          if (p == null) {
                            errorMsg = 'Product not found in Open Food database. Check code and try again.';
                          }
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Try sample barcodes:', style: TextStyle(fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Nutella'),
                      onPressed: () async {
                        barcodeCtrl.text = '3017620422003';
                        setDialogState(() {
                          isSearching = true;
                          errorMsg = null;
                        });
                        final p = await BarcodeService.fetchProduct(barcodeCtrl.text);
                        setDialogState(() {
                          isSearching = false;
                          foundProduct = p;
                        });
                      },
                    ),
                    ActionChip(
                      label: const Text('Coca-Cola'),
                      onPressed: () async {
                        barcodeCtrl.text = '5449000000996';
                        setDialogState(() {
                          isSearching = true;
                          errorMsg = null;
                        });
                        final p = await BarcodeService.fetchProduct(barcodeCtrl.text);
                        setDialogState(() {
                          isSearching = false;
                          foundProduct = p;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (isSearching)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (errorMsg != null)
                  Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13))
                else if (foundProduct != null) ...[
                  Card(
                    color: Colors.green.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(foundProduct!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          if (foundProduct!.brand.isNotEmpty)
                            Text('Brand: ${foundProduct!.brand}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          const Divider(),
                          Text(
                            'Per 100g: ${foundProduct!.calories.round()} kcal • '
                            'P: ${foundProduct!.protein}g • C: ${foundProduct!.carbs}g • F: ${foundProduct!.fat}g',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          Text(
                            'Fiber: ${foundProduct!.fiber}g • Sugar: ${foundProduct!.sugar}g • Sodium: ${foundProduct!.sodium.round()}mg',
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            if (foundProduct != null) ...[
              FilledButton.tonal(
                onPressed: () async {
                  await AppDb.instance.insertFood(foundProduct!.toFood());
                  if (ctx.mounted) Navigator.pop(ctx);
                  onUpdated();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved "${foundProduct!.name}" to My Foods!')),
                    );
                  }
                },
                child: const Text('Save to My Foods'),
              ),
              FilledButton(
                onPressed: () async {
                  final f = foundProduct!.toFood();
                  final newId = await AppDb.instance.insertFood(f);
                  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await AppDb.instance.insertLog(
                    LogEntry(
                      date: todayStr,
                      foodId: newId,
                      grams: 100,
                      unit: 'g',
                      baseAmount: 100,
                      label: 'Snack',
                      foodName: f.name,
                      calories100: f.calories,
                      protein100: f.protein,
                      carbs100: f.carbs,
                      fat100: f.fat,
                      fiber100: f.fiber,
                      sugar100: f.sugar,
                      sodium100: f.sodium,
                      entryType: 'food',
                    ),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  onUpdated();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Logged 100g of "${f.name}" to today!')),
                    );
                  }
                },
                child: const Text('Log 100g Now'),
              ),
            ],
          ],
        );
      },
    ),
  );
}

// ---------------- EXPORT DATA (CSV) ----------------

Future<void> _showExportCsvDialog(BuildContext context) async {
  showDialog(
    context: context,
    builder: (ctx) => const _ExportCsvDialog(),
  );
}

class _ExportCsvDialog extends StatefulWidget {
  const _ExportCsvDialog();

  @override
  State<_ExportCsvDialog> createState() => _ExportCsvDialogState();
}

class _ExportCsvDialogState extends State<_ExportCsvDialog> {
  String _csvData = '';
  int _entryCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateCsv();
  }

  Future<void> _generateCsv() async {
    setState(() => _isLoading = true);
    final d = await AppDb.instance.db;
    final rows = await d.query('log_entries', orderBy: 'date DESC, time ASC');

    final buffer = StringBuffer();
    buffer.writeln('Date,Time,Category,Food Name,Amount,Unit,Calories,Protein(g),Carbs(g),Fat(g),Fiber(g),Sugar(g),Sodium(mg),Notes');

    for (final r in rows) {
      final date = (r['date'] as String?) ?? '';
      final time = (r['time'] as String?) ?? '';
      final label = (r['label'] as String?) ?? 'Other';
      final entryType = (r['entry_type'] as String?) ?? 'food';
      final name = ((entryType == 'manual' ? r['manual_name'] : r['food_name']) as String?) ?? 'Unknown';
      final cleanName = '"${name.replaceAll('"', '""')}"';
      final amount = (r['grams'] as num?)?.toDouble() ?? 0;
      final unit = (r['unit'] as String?) ?? 'g';
      final base = (r['base_amount'] as num?)?.toDouble() ?? 100;
      final factor = base > 0 ? (amount / base) : 1.0;

      double kcal, p, c, f, fi, su, so;
      if (entryType == 'manual') {
        kcal = (r['manual_kcal'] as num?)?.toDouble() ?? 0;
        p = (r['manual_protein'] as num?)?.toDouble() ?? 0;
        c = (r['manual_carbs'] as num?)?.toDouble() ?? 0;
        f = (r['manual_fat'] as num?)?.toDouble() ?? 0;
        fi = (r['manual_fiber'] as num?)?.toDouble() ?? 0;
        su = (r['manual_sugar'] as num?)?.toDouble() ?? 0;
        so = (r['manual_sodium'] as num?)?.toDouble() ?? 0;
      } else {
        kcal = ((r['calories_100'] as num?)?.toDouble() ?? 0) * factor;
        p = ((r['protein_100'] as num?)?.toDouble() ?? 0) * factor;
        c = ((r['carbs_100'] as num?)?.toDouble() ?? 0) * factor;
        f = ((r['fat_100'] as num?)?.toDouble() ?? 0) * factor;
        fi = ((r['fiber_100'] as num?)?.toDouble() ?? 0) * factor;
        su = ((r['sugar_100'] as num?)?.toDouble() ?? 0) * factor;
        so = ((r['sodium_100'] as num?)?.toDouble() ?? 0) * factor;
      }

      final rawNotes = (r['notes'] as String?) ?? '';
      final cleanNotes = '"${rawNotes.replaceAll('"', '""')}"';

      buffer.writeln('$date,$time,$label,$cleanName,$amount,$unit,${kcal.round()},${p.toStringAsFixed(1)},${c.toStringAsFixed(1)},${f.toStringAsFixed(1)},${fi.toStringAsFixed(1)},${su.toStringAsFixed(1)},${so.round()},$cleanNotes');
    }

    if (mounted) {
      setState(() {
        _csvData = buffer.toString();
        _entryCount = rows.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.file_download, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Export Data (CSV)'),
        ],
      ),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Generated CSV containing $_entryCount log entries.', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('You can copy this data and paste it into Excel, Google Sheets, or share with your nutritionist:'),
                  const SizedBox(height: 10),
                  Container(
                    height: 160,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _csvData.isEmpty ? 'No data' : _csvData,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton.icon(
          icon: const Icon(Icons.copy),
          label: const Text('Copy to Clipboard'),
          onPressed: _csvData.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: _csvData));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('CSV copied to clipboard!')),
                    );
                    Navigator.pop(context);
                  }
                },
        ),
      ],
    );
  }
}

