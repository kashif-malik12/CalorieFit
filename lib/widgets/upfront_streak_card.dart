import 'package:flutter/material.dart';
import '../services/gamification_service.dart';

class UpfrontStreakCard extends StatefulWidget {
  final VoidCallback? onStreakUpdated;
  final VoidCallback? onOpenAchievements;

  const UpfrontStreakCard({
    super.key,
    this.onStreakUpdated,
    this.onOpenAchievements,
  });

  @override
  State<UpfrontStreakCard> createState() => _UpfrontStreakCardState();
}

class _UpfrontStreakCardState extends State<UpfrontStreakCard> {
  StreakChallengeInfo? _info;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _streakGoals = [
    {
      'days': 1,
      'title': '1-Day Kickstart',
      'icon': '⚡',
      'subtitle': 'Build momentum today',
    },
    {
      'days': 3,
      'title': '3-Day Habit',
      'icon': '🌟',
      'subtitle': 'Establish daily rhythm',
    },
    {
      'days': 7,
      'title': '7-Day Champion',
      'icon': '🔥',
      'subtitle': 'One full week discipline',
    },
    {
      'days': 10,
      'title': '10-Day Challenge',
      'icon': '🚀',
      'subtitle': 'Proven consistency goal',
    },
    {
      'days': 14,
      'title': '14-Day Momentum',
      'icon': '💎',
      'subtitle': 'Two weeks transformation',
    },
    {
      'days': 30,
      'title': '30-Day Master',
      'icon': '👑',
      'subtitle': 'Complete lifestyle shift',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadStreakInfo();
  }

  Future<void> _loadStreakInfo() async {
    try {
      final info = await GamificationService.instance.getStreakChallengeInfo();
      if (mounted) {
        setState(() {
          _info = info;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setGoal(int days) async {
    await GamificationService.instance.setStreakTargetDays(days);
    await _loadStreakInfo();
    widget.onStreakUpdated?.call();
  }

  void _showGoalPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final currentTarget = _info?.targetGoalDays ?? 10;
        final customCtrl = TextEditingController(text: currentTarget.toString());

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        'Choose Your Streak Goal',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pick how many consecutive days you want to commit to logging meals:',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),

                  // Preset options
                  ..._streakGoals.map((g) {
                    final days = g['days'] as int;
                    final isSelected = currentTarget == days;

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? Colors.orange : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      color: isSelected ? Colors.orange.withOpacity(0.08) : Colors.white,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.orange : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              g['icon'] as String,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        title: Text(
                          g['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.deepOrange : Colors.black87,
                          ),
                        ),
                        subtitle: Text(g['subtitle'] as String, style: const TextStyle(fontSize: 12)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.orange)
                            : Text(
                                '$days Days',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                              ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _setGoal(days);
                        },
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  // Custom days input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Custom Streak Goal (Days)',
                            hintText: 'e.g. 21, 60, 100',
                            prefixIcon: const Icon(Icons.edit_calendar, color: Colors.orange),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final parsed = int.tryParse(customCtrl.text.trim()) ?? 10;
                          Navigator.pop(ctx);
                          await _setGoal(parsed);
                        },
                        child: const Text('Set Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final info = _info ??
        const StreakChallengeInfo(
          currentStreakDays: 0,
          bestStreakDays: 0,
          targetGoalDays: 10,
          loggedToday: false,
          progressPercent: 0.0,
          daysRemaining: 10,
          isCompleted: false,
        );

    final current = info.currentStreakDays;
    final target = info.targetGoalDays;
    final hasStarted = current > 0;
    final pct = (info.progressPercent * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('🔥', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 8),
                const Text(
                  'STREAK CHALLENGE',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                // Goal selector pill
                InkWell(
                  onTap: () => _showGoalPicker(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Goal: $target Days',
                          style: const TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, color: Colors.orangeAccent, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Counter & Status Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Flame Badge Avatar
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hasStarted
                          ? [Colors.deepOrange, Colors.orangeAccent]
                          : [Colors.grey.shade700, Colors.grey.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: hasStarted
                        ? [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 20)),
                        Text(
                          '$current',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Streak Headline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasStarted
                            ? '$current Day${current == 1 ? '' : 's'} Active Streak!'
                            : 'Start $target-Day Streak!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        info.isCompleted
                            ? '🎉 Challenge Complete! You crushed $target days.'
                            : (hasStarted
                                ? '${info.daysRemaining} day${info.daysRemaining == 1 ? '' : 's'} left to hit your $target-day goal ($pct%)'
                                : 'Log meals today to light your Day 1 flame'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Milestone Day Bubbles (Visualizer)
          _buildDayMilestones(current, target),
          const SizedBox(height: 10),

          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: info.progressPercent,
                minHeight: 7,
                backgroundColor: Colors.white.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Footer Status & Quick Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                // Protection Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: info.loggedToday
                        ? Colors.green.withOpacity(0.2)
                        : Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: info.loggedToday
                          ? Colors.green.withOpacity(0.5)
                          : Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        info.loggedToday ? Icons.shield : Icons.hourglass_top,
                        size: 13,
                        color: info.loggedToday ? Colors.greenAccent : Colors.amberAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        info.loggedToday ? 'Streak Protected' : 'Log Meal Today',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: info.loggedToday ? Colors.greenAccent : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Achievements Shortcut
                InkWell(
                  onTap: widget.onOpenAchievements,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🏆 Badges',
                        style: TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right, size: 14, color: Colors.orangeAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayMilestones(int currentStreak, int targetGoal) {
    // Show up to 7-10 day visual bubbles based on target
    final displayDays = targetGoal <= 7 ? targetGoal : (targetGoal <= 14 ? 7 : 7);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(displayDays, (idx) {
          final dayNum = idx + 1;
          final isCompleted = dayNum <= currentStreak;
          final isCurrent = dayNum == currentStreak;
          final isFinal = dayNum == displayDays;

          Color bgColor = Colors.white.withOpacity(0.08);
          Widget iconWidget = Text(
            '$dayNum',
            style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6)),
          );

          if (isCompleted) {
            bgColor = Colors.orange.shade700;
            iconWidget = const Icon(Icons.check, size: 14, color: Colors.white);
          } else if (isCurrent) {
            bgColor = Colors.deepOrange;
            iconWidget = const Text('🔥', style: TextStyle(fontSize: 12));
          } else if (isFinal) {
            bgColor = Colors.amber.shade900.withOpacity(0.4);
            iconWidget = const Text('🏆', style: TextStyle(fontSize: 12));
          }

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? Colors.orangeAccent
                          : (isCurrent ? Colors.deepOrangeAccent : Colors.white.withOpacity(0.15)),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Center(child: iconWidget),
                ),
                const SizedBox(height: 4),
                Text(
                  'D$dayNum',
                  style: TextStyle(
                    fontSize: 9,
                    color: isCompleted || isCurrent ? Colors.orangeAccent : Colors.white38,
                    fontWeight: isCompleted || isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
