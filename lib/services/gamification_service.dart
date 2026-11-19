import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/models.dart';

class AchievementBadge {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final bool isUnlocked;
  final double progressPercent; // 0.0 to 1.0

  const AchievementBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.isUnlocked,
    required this.progressPercent,
  });
}

class UserStreakInfo {
  final int currentStreakDays;
  final int bestStreakDays;
  final bool loggedToday;

  const UserStreakInfo({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.loggedToday,
  });
}

class StreakChallengeInfo {
  final int currentStreakDays;
  final int bestStreakDays;
  final int targetGoalDays;
  final bool loggedToday;
  final double progressPercent;
  final int daysRemaining;
  final bool isCompleted;

  const StreakChallengeInfo({
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.targetGoalDays,
    required this.loggedToday,
    required this.progressPercent,
    required this.daysRemaining,
    required this.isCompleted,
  });
}

class GamificationService {
  final AppDb db;

  GamificationService({AppDb? db}) : db = db ?? AppDb.instance;
  static final GamificationService instance = GamificationService();

  static const String _kStreakTargetDaysKey = 'caloriefit_streak_target_days';

  /// Gets the user's selected streak challenge goal (default: 10 days)
  Future<int> getStreakTargetDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kStreakTargetDaysKey) ?? 10;
  }

  /// Sets the user's selected streak challenge goal (e.g. 1, 3, 7, 10, 14, 30 days)
  Future<void> setStreakTargetDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kStreakTargetDaysKey, days > 0 ? days : 1);
  }

  /// Returns aggregated streak and challenge target status
  Future<StreakChallengeInfo> getStreakChallengeInfo({UserStreakInfo? streakOverride}) async {
    final streak = streakOverride ?? await calculateStreak();
    final target = await getStreakTargetDays();
    final progress = target > 0 ? (streak.currentStreakDays / target).clamp(0.0, 1.0) : 0.0;
    final remaining = (target - streak.currentStreakDays).clamp(0, 9999);
    final completed = streak.currentStreakDays >= target;

    return StreakChallengeInfo(
      currentStreakDays: streak.currentStreakDays,
      bestStreakDays: streak.bestStreakDays,
      targetGoalDays: target,
      loggedToday: streak.loggedToday,
      progressPercent: progress,
      daysRemaining: remaining,
      isCompleted: completed,
    );
  }

  /// Calculates the current consecutive day logging streak.
  Future<UserStreakInfo> calculateStreak() async {
    final now = DateTime.now();
    int currentStreak = 0;
    bool loggedToday = false;

    // Check today first
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todayTotals = await db.getTotalsForDate(todayStr);
    if (todayTotals.calories > 0) {
      currentStreak++;
      loggedToday = true;
    }

    // Walk backwards through days
    int checkDays = loggedToday ? 1 : 1;
    while (checkDays < 365) {
      final prevDate = now.subtract(Duration(days: checkDays));
      final dateStr = DateFormat('yyyy-MM-dd').format(prevDate);
      final totals = await db.getTotalsForDate(dateStr);

      if (totals.calories > 0) {
        currentStreak++;
        checkDays++;
      } else {
        // Break in streak
        break;
      }
    }

    return UserStreakInfo(
      currentStreakDays: currentStreak,
      bestStreakDays: currentStreak > 7 ? currentStreak : 7,
      loggedToday: loggedToday,
    );
  }

  /// Evaluates and returns all milestone achievement badges.
  Future<List<AchievementBadge>> getBadges() async {
    final streak = await calculateStreak();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    final todayTotals = await db.getTotalsForDate(todayStr);
    final todayWater = await db.getWaterLog(todayStr);
    final todaySteps = await db.getTotalStepsForDate(todayStr);
    final fastingHistory = await db.getRecentFastingSessions(limit: 20);

    final completedFasts = fastingHistory.where((f) => f.isCompleted).length;

    return [
      AchievementBadge(
        id: 'first_step',
        title: 'First Step',
        description: 'Log your very first meal in CalorieFit',
        iconEmoji: '🌱',
        isUnlocked: todayTotals.calories > 0 || streak.currentStreakDays > 0,
        progressPercent: (todayTotals.calories > 0 || streak.currentStreakDays > 0) ? 1.0 : 0.0,
      ),
      AchievementBadge(
        id: 'streak_3',
        title: '3-Day Momentum',
        description: 'Log your meals for 3 consecutive days',
        iconEmoji: '🔥',
        isUnlocked: streak.currentStreakDays >= 3,
        progressPercent: (streak.currentStreakDays / 3.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'streak_7',
        title: '7-Day Champion',
        description: 'Maintain a 1-week continuous logging streak',
        iconEmoji: '🏆',
        isUnlocked: streak.currentStreakDays >= 7,
        progressPercent: (streak.currentStreakDays / 7.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'streak_10',
        title: '10-Day Streak Master',
        description: 'Complete the 10-day consistency challenge',
        iconEmoji: '🚀',
        isUnlocked: streak.currentStreakDays >= 10,
        progressPercent: (streak.currentStreakDays / 10.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'streak_30',
        title: '30-Day Legend',
        description: 'Achieve a 1-month daily logging transformation',
        iconEmoji: '👑',
        isUnlocked: streak.currentStreakDays >= 30,
        progressPercent: (streak.currentStreakDays / 30.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'hydration_hero',
        title: 'Hydration Hero',
        description: 'Drink at least 2,000ml of water in a single day',
        iconEmoji: '💧',
        isUnlocked: todayWater.amountMl >= 2000,
        progressPercent: (todayWater.amountMl / 2000.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'fasting_pro',
        title: 'Fasting Warrior',
        description: 'Complete 3 intermittent fasting windows',
        iconEmoji: '⏳',
        isUnlocked: completedFasts >= 3,
        progressPercent: (completedFasts / 3.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'step_machine',
        title: '10K Steps Club',
        description: 'Reach 10,000 steps logged in a single day',
        iconEmoji: '👟',
        isUnlocked: todaySteps >= 10000,
        progressPercent: (todaySteps / 10000.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'macro_master',
        title: 'Protein Master',
        description: 'Hit over 100g of high-quality protein',
        iconEmoji: '🥩',
        isUnlocked: todayTotals.protein >= 100,
        progressPercent: (todayTotals.protein / 100.0).clamp(0.0, 1.0),
      ),
      AchievementBadge(
        id: 'fiber_guardian',
        title: 'Fiber Guardian',
        description: 'Achieve the recommended 25g daily dietary fiber',
        iconEmoji: '🌾',
        isUnlocked: todayTotals.fiber >= 25,
        progressPercent: (todayTotals.fiber / 25.0).clamp(0.0, 1.0),
      ),
    ];
  }
}
