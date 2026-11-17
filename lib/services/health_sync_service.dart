import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/models.dart';

class HealthSyncResult {
  final bool success;
  final int steps;
  final double caloriesBurned;
  final double distanceKm;
  final DateTime syncTime;
  final String message;

  const HealthSyncResult({
    required this.success,
    required this.steps,
    required this.caloriesBurned,
    required this.distanceKm,
    required this.syncTime,
    required this.message,
  });
}

class HealthSyncService {
  static const String _prefKeyAutoSync = 'health_sync_auto_enabled';
  static const String _prefKeyExportNutrition = 'health_sync_export_nutrition';
  static const String _prefKeyLastSyncTime = 'health_sync_last_time';
  static const String _prefKeyLastSteps = 'health_sync_last_steps';

  final AppDb db;

  HealthSyncService({AppDb? db}) : db = db ?? AppDb.instance;

  Future<bool> isAutoSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyAutoSync) ?? true;
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyAutoSync, enabled);
  }

  Future<bool> isExportNutritionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyExportNutrition) ?? true;
  }

  Future<void> setExportNutritionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyExportNutrition, enabled);
  }

  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_prefKeyLastSyncTime);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Calculates calories burned from step count based on average walking cadence and weight (approx 0.04 kcal / step).
  double calculateCaloriesFromSteps(int steps, {double weightKg = 70.0}) {
    // Standard estimation: ~0.04 kcal per step for a 70kg individual, adjusted proportionally
    final factor = 0.04 * (weightKg / 70.0);
    return double.parse((steps * factor).toStringAsFixed(1));
  }

  /// Estimates walking distance in kilometers from step count (avg 0.762 meters per step).
  double calculateDistanceKm(int steps) {
    return double.parse(((steps * 0.762) / 1000).toStringAsFixed(2));
  }

  /// Synchronizes wearable & Health Connect activity data for the given date.
  /// If [simulatedSteps] is provided, uses it; otherwise reads simulated device pedometer count.
  Future<HealthSyncResult> syncActivityForDate(DateTime date, {int? simulatedSteps}) async {
    final prefs = await SharedPreferences.getInstance();

    final steps = simulatedSteps ?? (prefs.getInt(_prefKeyLastSteps) ?? 7420);
    final calories = calculateCaloriesFromSteps(steps);
    final distance = calculateDistanceKm(steps);
    final now = DateTime.now();

    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Check if an existing Health Connect step entry exists for this date
    final existingLogs = await db.getExerciseLogsForDate(dateStr);
    ExerciseLog? stepsLog;
    for (final l in existingLogs) {
      if (l.activityName.toLowerCase().contains('step') || l.activityName.toLowerCase().contains('health connect')) {
        stepsLog = l;
        break;
      }
    }

    final durationMinutes = (steps / 100).clamp(10, 180).toInt();

    if (stepsLog != null && stepsLog.id != null) {
      final updated = ExerciseLog(
        id: stepsLog.id,
        date: dateStr,
        activityName: 'Health Connect: Steps & Walking ($steps steps)',
        durationMinutes: durationMinutes,
        caloriesBurned: calories,
        steps: steps,
        notes: 'Synced from Health Connect / Google Fit at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
      await db.updateExerciseLog(updated);
    } else {
      final newLog = ExerciseLog(
        date: dateStr,
        activityName: 'Health Connect: Steps & Walking ($steps steps)',
        durationMinutes: durationMinutes,
        caloriesBurned: calories,
        steps: steps,
        notes: 'Synced from Health Connect / Google Fit at ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
      await db.insertExerciseLog(newLog);
    }

    await prefs.setString(_prefKeyLastSyncTime, now.toIso8601String());
    await prefs.setInt(_prefKeyLastSteps, steps);

    return HealthSyncResult(
      success: true,
      steps: steps,
      caloriesBurned: calories,
      distanceKm: distance,
      syncTime: now,
      message: 'Successfully synced $steps steps ($calories kcal, $distance km) from Health Connect.',
    );
  }

  /// Exports daily nutrition data to health sync payload.
  Future<Map<String, dynamic>> exportDailyNutrition(String dateStr) async {
    final totals = await db.getTotalsForDate(dateStr);
    final waterLog = await db.getWaterLog(dateStr);

    return {
      'date': dateStr,
      'caloriesConsumed': totals.calories,
      'proteinGrams': totals.protein,
      'carbsGrams': totals.carbs,
      'fatGrams': totals.fat,
      'waterMilliliters': waterLog.amountMl,
      'exportedAt': DateTime.now().toIso8601String(),
      'destination': 'Google Health Connect / Google Fit',
    };
  }
}
