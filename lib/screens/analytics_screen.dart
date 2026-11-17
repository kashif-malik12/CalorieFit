import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../widgets/interactive_charts.dart';
import 'report_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  List<DailyCalorieBarData> _weeklyBars = [];
  MacroChartData _macroData = const MacroChartData(proteinGrams: 0, carbsGrams: 0, fatGrams: 0);
  List<WeightPoint> _weightPoints = [];
  String _weightUnit = 'kg';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    final now = DateTime.now();
    final df = DateFormat('yyyy-MM-dd');
    final dayFormat = DateFormat('E');

    // 1. Last 7 Days Caloric Intake
    final bars = <DailyCalorieBarData>[];
    double sumProtein = 0;
    double sumCarbs = 0;
    double sumFat = 0;

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = df.format(date);
      final totals = await AppDb.instance.getTotalsForDate(dateStr);
      final targets = await AppDb.instance.getTargetsForDate(dateStr);

      bars.add(DailyCalorieBarData(
        dayLabel: dayFormat.format(date),
        calories: totals.calories,
        target: targets.calories.toDouble(),
      ));

      sumProtein += totals.protein;
      sumCarbs += totals.carbs;
      sumFat += totals.fat;
    }

    // 2. Weight logs (last 30)
    final weights = await AppDb.instance.getWeightLogs(limit: 30);
    final points = weights.reversed.map((w) {
      return WeightPoint(date: w.date, weight: w.weight);
    }).toList();

    String unit = 'kg';
    if (weights.isNotEmpty) {
      unit = weights.first.unit;
    }

    if (!mounted) return;
    setState(() {
      _weeklyBars = bars;
      _macroData = MacroChartData(
        proteinGrams: sumProtein / 7,
        carbsGrams: sumCarbs / 7,
        fatGrams: sumFat / 7,
      );
      _weightPoints = points;
      _weightUnit = unit;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Visual Charts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'View Full Report',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReportScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Weekly Calorie Bar Chart Card
                    Card(
                      elevation: 2,
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
                                  '7-Day Caloric Intake',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'vs Target',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            WeeklyCalorieBarChart(days: _weeklyBars),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Macro Distribution Donut Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Macronutrient Ratio (Weekly Avg)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            MacroDonutChart(data: _macroData),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weight Trend Line Chart Card
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Body Weight Trend',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            WeightTrendChart(
                              points: _weightPoints,
                              unit: _weightUnit,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Full Report Banner Button
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: theme.colorScheme.primary.withAlpha(50)),
                      ),
                      tileColor: theme.colorScheme.primaryContainer.withAlpha(40),
                      leading: Icon(Icons.assignment, color: theme.colorScheme.primary),
                      title: const Text('Detailed Health & Nutrition Report'),
                      subtitle: const Text('View coach insights, adherence rates, and copy report'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
