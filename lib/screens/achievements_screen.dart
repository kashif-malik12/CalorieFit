import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final GamificationService _service = GamificationService.instance;
  UserStreakInfo? _streak;
  List<AchievementBadge> _badges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final streak = await _service.calculateStreak();
    final badges = await _service.getBadges();
    if (mounted) {
      setState(() {
        _streak = streak;
        _badges = badges;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = _badges.where((b) => b.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streaks & Achievements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Streak Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.deepOrange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepOrange.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(child: Text('🔥', style: TextStyle(fontSize: 34))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_streak?.currentStreakDays ?? 0} Day Streak!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _streak?.loggedToday == true
                                  ? 'You logged today! Keep the flame burning.'
                                  : 'Log a meal today to protect your streak!',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Badge Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Milestone Badges',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$unlockedCount of ${_badges.length} Unlocked',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grid of badges
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: _badges.length,
                  itemBuilder: (ctx, i) {
                    final badge = _badges[i];
                    return _BadgeCard(badge: badge);
                  },
                ),
              ],
            ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final AchievementBadge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: badge.isUnlocked ? theme.colorScheme.primary.withOpacity(0.4) : Colors.grey.shade300,
          width: badge.isUnlocked ? 2 : 1,
        ),
      ),
      color: badge.isUnlocked ? theme.colorScheme.primaryContainer.withOpacity(0.2) : theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: badge.isUnlocked ? theme.colorScheme.primary.withOpacity(0.12) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  badge.isUnlocked ? badge.iconEmoji : '🔒',
                  style: TextStyle(fontSize: badge.isUnlocked ? 26 : 22),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              badge.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: badge.isUnlocked ? null : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: badge.progressPercent,
              color: badge.isUnlocked ? Colors.green : theme.colorScheme.primary,
              backgroundColor: Colors.grey.shade200,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }
}
