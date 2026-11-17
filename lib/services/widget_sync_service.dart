import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/models.dart';

class WidgetSyncService {
  static const String _prefKeyWidgetPayload = 'home_widget_payload';
  final AppDb db;

  WidgetSyncService({AppDb? db}) : db = db ?? AppDb.instance;

  /// Computes full snapshot of today's health data for home-screen widgets.
  Future<Map<String, dynamic>> updateWidgetData() async {
    final now = DateTime.now();
    final dateStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final targets = await db.getTargetsForDate(dateStr);
    final totals = await db.getTotalsForDate(dateStr);
    final waterLog = await db.getWaterLog(dateStr);
    final exercises = await db.getExerciseLogsForDate(dateStr);
    final activeFast = await db.getActiveFastingSession();

    final totalWaterMl = waterLog.amountMl.toDouble();

    double totalBurned = 0;
    for (final e in exercises) {
      totalBurned += e.caloriesBurned;
    }

    final netCalories = totals.calories - totalBurned;
    final remainingCalories = targets.calories - netCalories;

    String fastStatus = 'IDLE';
    double fastProgress = 0.0;
    int remainingMinutes = 0;

    if (activeFast != null && activeFast.isActive) {
      fastStatus = 'FASTING';
      fastProgress = (activeFast.progressPercent * 100).clamp(0, 100);
      remainingMinutes = activeFast.remaining.inMinutes;
    }

    final payload = {
      'date': dateStr,
      'updatedAt': now.toIso8601String(),
      'calorieBudget': targets.calories,
      'calorieConsumed': totals.calories,
      'calorieBurned': totalBurned,
      'netCalories': netCalories,
      'remainingCalories': remainingCalories,
      'proteinGrams': totals.protein,
      'proteinTarget': targets.protein,
      'carbsGrams': totals.carbs,
      'carbsTarget': targets.carbs,
      'fatGrams': totals.fat,
      'fatTarget': targets.fat,
      'waterMl': totalWaterMl,
      'waterGlasses': (totalWaterMl / 250).floor(),
      'fastStatus': fastStatus,
      'fastProgressPercent': fastProgress,
      'fastRemainingMinutes': remainingMinutes,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyWidgetPayload, jsonEncode(payload));
    return payload;
  }

  Future<Map<String, dynamic>?> getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKeyWidgetPayload);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Quick-action helper to log 250ml water directly from widget or quick-action
  Future<void> quickLogWater([double amountMl = 250]) async {
    final now = DateTime.now();
    final dateStr = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    await db.updateWaterAmount(dateStr, amountMl.round());
    await updateWidgetData();
  }
}
