import 'package:intl/intl.dart';
import '../data/db.dart';

class NutritionHealthReport {
  final int periodDays;
  final DateTime startDate;
  final DateTime endDate;
  final int loggedDaysCount;
  final double totalCalories;
  final double avgDailyCalories;
  final double targetCalories;
  final double avgProtein;
  final double avgCarbs;
  final double avgFat;
  final double avgFiber;
  final int totalWaterMl;
  final int avgDailyWaterMl;
  final int targetWaterMl;
  final double? startWeight;
  final double? currentWeight;
  final String weightUnit;
  final List<String> coachObservations;

  const NutritionHealthReport({
    required this.periodDays,
    required this.startDate,
    required this.endDate,
    required this.loggedDaysCount,
    required this.totalCalories,
    required this.avgDailyCalories,
    required this.targetCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.avgFiber,
    required this.totalWaterMl,
    required this.avgDailyWaterMl,
    required this.targetWaterMl,
    this.startWeight,
    this.currentWeight,
    this.weightUnit = 'kg',
    required this.coachObservations,
  });

  double get weightDelta =>
      (currentWeight != null && startWeight != null) ? (currentWeight! - startWeight!) : 0.0;

  double get loggingConsistencyPct => (loggedDaysCount / periodDays) * 100;
  double get calorieAdherencePct =>
      targetCalories > 0 ? (avgDailyCalories / targetCalories) * 100 : 0;
  double get waterAdherencePct =>
      targetWaterMl > 0 ? (avgDailyWaterMl / targetWaterMl) * 100 : 0;
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<NutritionHealthReport> generateReport({int days = 7}) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    final df = DateFormat('yyyy-MM-dd');

    double sumCalories = 0;
    double sumProtein = 0;
    double sumCarbs = 0;
    double sumFat = 0;
    double sumFiber = 0;
    int loggedDays = 0;
    int sumWater = 0;
    double lastTargetCalories = 2000;
    int lastTargetWater = 2000;

    for (int i = 0; i < days; i++) {
      final dateStr = df.format(startDate.add(Duration(days: i)));
      final totals = await AppDb.instance.getTotalsForDate(dateStr);
      final water = await AppDb.instance.getWaterLog(dateStr);
      final targets = await AppDb.instance.getTargetsForDate(dateStr);

      lastTargetCalories = targets.calories.toDouble();
      lastTargetWater = water.targetMl;

      if (totals.calories > 0) {
        loggedDays++;
        sumCalories += totals.calories;
        sumProtein += totals.protein;
        sumCarbs += totals.carbs;
        sumFat += totals.fat;
        sumFiber += totals.fiber;
      }
      sumWater += water.amountMl;
    }

    final divisor = loggedDays > 0 ? loggedDays : 1;
    final avgCal = sumCalories / (days > 0 ? days : 1);
    final avgP = sumProtein / divisor;
    final avgC = sumCarbs / divisor;
    final avgF = sumFat / divisor;
    final avgFib = sumFiber / divisor;
    final avgW = sumWater ~/ (days > 0 ? days : 1);

    // Weight logs
    final weights = await AppDb.instance.getWeightLogs(limit: 50);
    double? startWt;
    double? currWt;
    String wtUnit = 'kg';

    if (weights.isNotEmpty) {
      wtUnit = weights.first.unit;
      currWt = weights.first.weight;
      final startCutoff = df.format(startDate);
      final validWithinPeriod = weights.where((w) => w.date.compareTo(startCutoff) >= 0).toList();
      if (validWithinPeriod.isNotEmpty) {
        startWt = validWithinPeriod.last.weight;
      } else {
        startWt = weights.last.weight;
      }
    }

    // Coach Observations
    final obs = <String>[];
    if (loggedDays == days) {
      obs.add('🔥 Excellent logging streak! You logged meals every single day this period.');
    } else if (loggedDays >= (days * 0.7).round()) {
      obs.add('👍 Consistent logging habits ($loggedDays/$days days active). Keep building the momentum!');
    } else {
      obs.add('⚡ Try to log foods daily to keep your nutrition estimates accurate.');
    }

    if (avgCal > 0 && lastTargetCalories > 0) {
      final diff = avgCal - lastTargetCalories;
      if (diff.abs() <= 150) {
        obs.add('🎯 Spot-on calorie control! Your average intake was within 150 kcal of target.');
      } else if (diff < -150) {
        obs.add('📉 Operating at a calorie deficit of ${(-diff).round()} kcal below daily target.');
      } else {
        obs.add('📈 Average daily intake exceeded goal by ${diff.round()} kcal.');
      }
    }

    if (avgP >= 100) {
      obs.add('💪 High protein intake (~${avgP.round()}g/day) supports lean muscle preservation and recovery.');
    }

    if (avgW >= lastTargetWater) {
      obs.add('💧 Hydration goal met! You averaged ${(avgW / 1000).toStringAsFixed(1)}L water daily.');
    } else {
      obs.add('💧 Hydration under target (${(avgW / 1000).toStringAsFixed(1)}L / ${(lastTargetWater / 1000).toStringAsFixed(1)}L). Try drinking a glass upon waking.');
    }

    return NutritionHealthReport(
      periodDays: days,
      startDate: startDate,
      endDate: now,
      loggedDaysCount: loggedDays,
      totalCalories: sumCalories,
      avgDailyCalories: avgCal,
      targetCalories: lastTargetCalories,
      avgProtein: avgP,
      avgCarbs: avgC,
      avgFat: avgF,
      avgFiber: avgFib,
      totalWaterMl: sumWater,
      avgDailyWaterMl: avgW,
      targetWaterMl: lastTargetWater,
      startWeight: startWt,
      currentWeight: currWt,
      weightUnit: wtUnit,
      coachObservations: obs,
    );
  }

  String exportAsPlainText(NutritionHealthReport r) {
    final df = DateFormat('MMM dd, yyyy');
    final buffer = StringBuffer();
    buffer.writeln('==============================================');
    buffer.writeln('CALORIEFIT HEALTH & NUTRITION PROGRESS REPORT');
    buffer.writeln('Period: ${df.format(r.startDate)} - ${df.format(r.endDate)} (${r.periodDays} Days)');
    buffer.writeln('==============================================\n');

    buffer.writeln('1. SUMMARY & ADHERENCE');
    buffer.writeln('• Days Logged: ${r.loggedDaysCount} / ${r.periodDays} (${r.loggingConsistencyPct.toStringAsFixed(0)}%)');
    buffer.writeln('• Total Calories Logged: ${r.totalCalories.round()} kcal');
    buffer.writeln('• Average Daily Calories: ${r.avgDailyCalories.round()} kcal (Target: ${r.targetCalories.round()} kcal)');
    buffer.writeln('');

    buffer.writeln('2. MACRONUTRIENT AVERAGES');
    buffer.writeln('• Protein: ${r.avgProtein.toStringAsFixed(1)}g');
    buffer.writeln('• Carbohydrates: ${r.avgCarbs.toStringAsFixed(1)}g');
    buffer.writeln('• Healthy Fats: ${r.avgFat.toStringAsFixed(1)}g');
    buffer.writeln('• Dietary Fiber: ${r.avgFiber.toStringAsFixed(1)}g');
    buffer.writeln('');

    buffer.writeln('3. HYDRATION');
    buffer.writeln('• Total Water Logged: ${(r.totalWaterMl / 1000).toStringAsFixed(1)} Liters');
    buffer.writeln('• Daily Average: ${(r.avgDailyWaterMl / 1000).toStringAsFixed(1)} L (Target: ${(r.targetWaterMl / 1000).toStringAsFixed(1)} L)');
    buffer.writeln('');

    if (r.currentWeight != null) {
      buffer.writeln('4. BODY WEIGHT PROGRESSION');
      if (r.startWeight != null) {
        buffer.writeln('• Start: ${r.startWeight!.toStringAsFixed(1)} ${r.weightUnit}');
      }
      buffer.writeln('• Current: ${r.currentWeight!.toStringAsFixed(1)} ${r.weightUnit}');
      buffer.writeln('• Net Change: ${r.weightDelta >= 0 ? "+" : ""}${r.weightDelta.toStringAsFixed(1)} ${r.weightUnit}');
      buffer.writeln('');
    }

    buffer.writeln('5. COACH OBSERVATIONS & INSIGHTS');
    for (final note in r.coachObservations) {
      buffer.writeln('• $note');
    }
    buffer.writeln('\nGenerated by CalorieFit - Local First Nutrition');
    return buffer.toString();
  }
}
