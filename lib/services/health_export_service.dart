import 'package:intl/intl.dart';
import '../data/db.dart';

class HealthExportService {
  final AppDb db;

  HealthExportService({AppDb? db}) : db = db ?? AppDb.instance;

  static final HealthExportService instance = HealthExportService();

  /// Generates a structured CSV table for the past [days] days.
  Future<String> generateCsvExport({int days = 14}) async {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Target Calories,Consumed Calories,Burned Calories,Net Calories,Steps,Protein (g),Carbs (g),Fat (g),Water (ml),Fasting Protocol,Fasting Hours');

    final now = DateTime.now();
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final targets = await db.getTargetsForDate(dateStr);
      final totals = await db.getTotalsForDate(dateStr);
      final water = await db.getWaterLog(dateStr);
      final burned = await db.getTotalExerciseCaloriesForDate(dateStr);
      final steps = await db.getTotalStepsForDate(dateStr);
      final fastSessions = await db.getRecentFastingSessions(limit: 50);

      String fastingProtocol = 'None';
      double fastingHours = 0.0;
      for (final f in fastSessions) {
        if (DateFormat('yyyy-MM-dd').format(f.startTime) == dateStr) {
          fastingProtocol = f.protocol;
          fastingHours = f.elapsed.inMinutes / 60.0;
          break;
        }
      }

      final netCalories = totals.calories - burned;

      buffer.writeln([
        dateStr,
        targets.calories.round(),
        totals.calories.round(),
        burned.round(),
        netCalories.round(),
        steps,
        totals.protein.toStringAsFixed(1),
        totals.carbs.toStringAsFixed(1),
        totals.fat.toStringAsFixed(1),
        water.amountMl,
        fastingProtocol,
        fastingHours.toStringAsFixed(1),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Generates a human-readable medical & dietetic summary report.
  Future<String> generateMedicalSummary({int days = 14}) async {
    final now = DateTime.now();
    final buffer = StringBuffer();
    buffer.writeln('====================================================');
    buffer.writeln('      CALORIEFIT CLINICAL & NUTRITION EXPORT');
    buffer.writeln('====================================================');
    buffer.writeln('Export Date: ${DateFormat('yyyy-MM-dd HH:mm').format(now)}');
    buffer.writeln('Coverage Window: Last $days Days');
    buffer.writeln('----------------------------------------------------');

    double sumCalories = 0;
    double sumProtein = 0;
    double sumCarbs = 0;
    double sumFat = 0;
    int sumSteps = 0;
    int sumWater = 0;
    int activeDays = 0;

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final totals = await db.getTotalsForDate(dateStr);
      final water = await db.getWaterLog(dateStr);
      final steps = await db.getTotalStepsForDate(dateStr);

      if (totals.calories > 0) {
        activeDays++;
        sumCalories += totals.calories;
        sumProtein += totals.protein;
        sumCarbs += totals.carbs;
        sumFat += totals.fat;
      }
      sumSteps += steps;
      sumWater += water.amountMl;
    }

    final avgCal = activeDays > 0 ? (sumCalories / activeDays).round() : 0;
    final avgP = activeDays > 0 ? (sumProtein / activeDays).toStringAsFixed(1) : '0';
    final avgC = activeDays > 0 ? (sumCarbs / activeDays).toStringAsFixed(1) : '0';
    final avgF = activeDays > 0 ? (sumFat / activeDays).toStringAsFixed(1) : '0';
    final avgSteps = (sumSteps / days).round();
    final avgWater = (sumWater / days).round();

    buffer.writeln('COMPLIANCE & DIARY CONSISTENCY:');
    buffer.writeln('  - Days Logged: $activeDays of $days days (${((activeDays / days) * 100).round()}%)');
    buffer.writeln('  - Average Daily Intake: $avgCal kcal');
    buffer.writeln('  - Average Daily Protein: ${avgP}g');
    buffer.writeln('  - Average Daily Carbs: ${avgC}g');
    buffer.writeln('  - Average Daily Fat: ${avgF}g');
    buffer.writeln('  - Average Daily Steps: $avgSteps steps');
    buffer.writeln('  - Average Hydration: ${avgWater} ml');
    buffer.writeln('----------------------------------------------------');
    buffer.writeln('Note: All data generated directly from CalorieFit local SQLite database.');
    buffer.writeln('====================================================');

    return buffer.toString();
  }
}
