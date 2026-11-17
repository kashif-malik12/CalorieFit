import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calorie_fit/data/models.dart';
import 'package:calorie_fit/services/reminder_service.dart';
import 'package:calorie_fit/services/ai_nutrition_estimator.dart';
import 'package:calorie_fit/services/report_service.dart';
import 'package:calorie_fit/services/open_food_facts_service.dart';
import 'package:calorie_fit/services/health_sync_service.dart';
import 'package:calorie_fit/services/app_localization.dart';
import 'package:calorie_fit/widgets/interactive_charts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Interactive Charts Tests', () {
    test('MacroChartData calculates calories and ratios correctly', () {
      const data = MacroChartData(
        proteinGrams: 100, // 400 kcal
        carbsGrams: 150,   // 600 kcal
        fatGrams: 50,      // 450 kcal
      );

      expect(data.totalGrams, 300);
      expect(data.proteinKcal, 400);
      expect(data.carbsKcal, 600);
      expect(data.fatKcal, 450);
      expect(data.totalKcal, 1450);

      // 400 / 1450 ≈ 27.58%
      expect(data.proteinPct, closeTo(27.58, 0.1));
      // 600 / 1450 ≈ 41.38%
      expect(data.carbsPct, closeTo(41.38, 0.1));
      // 450 / 1450 ≈ 31.03%
      expect(data.fatPct, closeTo(31.03, 0.1));
    });
  });

  group('ReminderService Tests', () {
    test('Calculates next reminder based on schedule', () {
      const s = ReminderSettings(
        enabled: true,
        breakfastEnabled: true,
        breakfastTime: TimeOfDay(hour: 8, minute: 30),
        lunchEnabled: true,
        lunchTime: TimeOfDay(hour: 13, minute: 0),
        dinnerEnabled: true,
        dinnerTime: TimeOfDay(hour: 19, minute: 30),
        waterEnabled: false,
      );

      // Test before breakfast (7:00 AM)
      final earlyMorning = DateTime(2026, 11, 17, 7, 0);
      final earlyNotice = ReminderService.instance.getNextReminderNotice(s, nowOverride: earlyMorning);
      expect(earlyNotice, contains('Breakfast Log (Morning) at 08:30'));

      // Test midday (10:00 AM)
      final midDay = DateTime(2026, 11, 17, 10, 0);
      final midNotice = ReminderService.instance.getNextReminderNotice(s, nowOverride: midDay);
      expect(midNotice, contains('Lunch Log (Midday) at 13:00'));

      // Test afternoon (15:00)
      final afternoon = DateTime(2026, 11, 17, 15, 0);
      final aftNotice = ReminderService.instance.getNextReminderNotice(s, nowOverride: afternoon);
      expect(aftNotice, contains('Dinner Log (Evening) at 19:30'));

      // Test late night (21:00) -> next reminder tomorrow morning
      final lateNight = DateTime(2026, 11, 17, 21, 0);
      final lateNotice = ReminderService.instance.getNextReminderNotice(s, nowOverride: lateNight);
      expect(lateNotice, contains('Next reminder tomorrow: Breakfast Log (Morning) at 08:30'));
    });

    test('Returns null when disabled', () {
      const s = ReminderSettings(enabled: false);
      final notice = ReminderService.instance.getNextReminderNotice(s);
      expect(notice, isNull);
    });
  });

  group('ReportService Tests', () {
    test('NutritionHealthReport exports formatted summary text correctly', () {
      final now = DateTime(2026, 11, 17);
      final report = NutritionHealthReport(
        periodDays: 7,
        startDate: now.subtract(const Duration(days: 6)),
        endDate: now,
        loggedDaysCount: 6,
        totalCalories: 13200,
        avgDailyCalories: 1885.7,
        targetCalories: 2000,
        avgProtein: 145.2,
        avgCarbs: 180.0,
        avgFat: 62.5,
        avgFiber: 28.0,
        totalWaterMl: 15400,
        avgDailyWaterMl: 2200,
        targetWaterMl: 2000,
        startWeight: 75.5,
        currentWeight: 74.8,
        weightUnit: 'kg',
        coachObservations: [
          'Excellent logging streak!',
          'Hydration goal met!',
        ],
      );

      expect(report.weightDelta, closeTo(-0.7, 0.05));
      expect(report.loggingConsistencyPct, closeTo(85.7, 0.1));

      final text = ReportService.instance.exportAsPlainText(report);
      expect(text, contains('CALORIEFIT HEALTH & NUTRITION PROGRESS REPORT'));
      expect(text, contains('Days Logged: 6 / 7'));
      expect(text, contains('Protein: 145.2g'));
      expect(text, contains('Hydration goal met!'));
      expect(text, contains('Net Change: -0.7 kg'));
    });
  });

  group('Fasting and Exercise Tests', () {
    test('FastingSession progress and remaining time calculations', () {
      final start = DateTime.now().subtract(const Duration(hours: 8));
      final session = FastingSession(
        protocol: '16:8',
        targetHours: 16.0,
        startTime: start,
      );

      expect(session.isActive, isTrue);
      expect(session.elapsed.inHours, closeTo(8, 1));
      // 8 / 16 = 50%
      expect(session.progressPercent, closeTo(0.5, 0.05));
      expect(session.remaining.inHours, closeTo(8, 1));
    });

    test('ExerciseLog serialization and calculation', () {
      const exercise = ExerciseLog(
        date: '2026-11-17',
        activityName: 'Running',
        durationMinutes: 45,
        caloriesBurned: 450,
        steps: 5200,
      );

      final map = exercise.toMap();
      expect(map['activity_name'], 'Running');
      expect(map['duration_minutes'], 45);
      expect(map['calories_burned'], 450.0);
      expect(map['steps'], 5200);

      final restored = ExerciseLog.fromMap(map);
      expect(restored.activityName, 'Running');
      expect(restored.caloriesBurned, 450.0);
    });
  });

  group('AI Meal Nutrition Estimator Tests', () {
    test('Estimates nutrition from natural language meal description', () async {
      final meal = await AiNutritionEstimator.instance.estimateMeal('2 eggs with 1 toast and avocado');

      expect(meal.items.isNotEmpty, isTrue);
      expect(meal.totalCalories, greaterThan(200));
      expect(meal.totalProtein, greaterThan(10));
      expect(meal.totalCarbs, greaterThan(5));
      expect(meal.totalFat, greaterThan(10));
      expect(meal.confidence, isIn(['High', 'Estimated']));
    });
  });

  group('Open Food Facts Service Tests', () {
    test('Parses raw product json to CalorieFit Food model', () {
      final service = OpenFoodFactsService();
      final mockJson = {
        'product_name': 'Organic Rolled Oats',
        'brands': 'Bob\'s Red Mill',
        'categories': 'Breakfast Cereals',
        'nutriments': {
          'energy-kcal_100g': 375.0,
          'proteins_100g': 13.0,
          'carbohydrates_100g': 68.0,
          'fat_100g': 6.5,
          'fiber_100g': 10.0,
          'sugars_100g': 1.0,
          'sodium_100g': 0.005,
          'saturated-fat_100g': 1.0,
        }
      };

      final food = service.parseProductToFood(mockJson);
      expect(food, isNotNull);
      expect(food!.name, contains('Organic Rolled Oats'));
      expect(food.name, contains('Bob\'s Red Mill'));
      expect(food.calories, 375.0);
      expect(food.protein, 13.0);
      expect(food.carbs, 68.0);
      expect(food.fat, 6.5);
      expect(food.fiber, 10.0);
      expect(food.sodium, 5.0); // 0.005 * 1000 mg
    });
  });

  group('Health Sync Service Tests', () {
    test('Calculates burned calories and distance accurately from step counts', () {
      final service = HealthSyncService();

      final calories = service.calculateCaloriesFromSteps(10000, weightKg: 70.0);
      expect(calories, closeTo(400.0, 1.0));

      final distanceKm = service.calculateDistanceKm(10000);
      expect(distanceKm, closeTo(7.62, 0.1));
    });
  });

  group('App Localization Tests', () {
    test('Translates keys and detects RTL direction properly', () async {
      SharedPreferences.setMockInitialValues({});
      await AppLocalization.setLanguage(AppLanguage.en);
      expect(AppLocalization.tr('calories'), 'Calories');
      expect(AppLocalization.tr('water'), 'Water');
      expect(AppLocalization.current.isRtl, isFalse);

      await AppLocalization.setLanguage(AppLanguage.es);
      expect(AppLocalization.tr('calories'), 'Calorías');
      expect(AppLocalization.tr('water'), 'Agua');
      expect(AppLocalization.current.isRtl, isFalse);

      await AppLocalization.setLanguage(AppLanguage.ur);
      expect(AppLocalization.tr('calories'), 'کیلوریز');
      expect(AppLocalization.tr('water'), 'پانی');
      expect(AppLocalization.current.isRtl, isTrue);

      await AppLocalization.setLanguage(AppLanguage.ar);
      expect(AppLocalization.tr('calories'), 'السعرات الحرارية');
      expect(AppLocalization.current.isRtl, isTrue);

      // Reset to English
      await AppLocalization.setLanguage(AppLanguage.en);
    });
  });
}
