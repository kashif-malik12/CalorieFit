import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'food_scanner_screen.dart';
import 'ai_meal_estimator_screen.dart';
import 'barcode_scanner_screen.dart';
import 'recipe_builder_screen.dart';
import 'grocery_list_screen.dart';
import 'meal_photo_journal_screen.dart';
import 'exercise_screen.dart';
import 'health_sync_screen.dart';
import 'health_export_dialog.dart';
import 'achievements_screen.dart';
import 'app_lock_screen.dart';
import 'widget_settings_screen.dart';
import 'onboarding_wizard_screen.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../services/app_update_service.dart';

class HealthHubScreen extends StatelessWidget {
  final VoidCallback? onRefreshDiary;

  const HealthHubScreen({super.key, this.onRefreshDiary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Fitness Hub'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, const Color(0xFF13505E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(child: Text('⚡', style: TextStyle(fontSize: 26))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Power Tools & Integrations',
                        style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'AI estimation, recipes, grocery prep, and health sync all in one place.',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 1: Smart Nutrition
          Text('SMART NUTRITION & FOOD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          // Primary Camera Scanner Feature Card
          _HubCard(
            icon: Icons.camera_alt,
            iconColor: Colors.teal,
            title: 'Camera Food Scanner',
            subtitle: 'Snap a photo of your plate to auto-calculate calories, macros, and portion sizes.',
            badge: 'AI CAMERA',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodScannerScreen(
                    date: todayStr,
                    onLogged: () => onRefreshDiary?.call(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _HubCard(
                  icon: Icons.auto_awesome,
                  iconColor: Colors.purple,
                  title: 'AI Meal Estimator',
                  subtitle: 'Natural language & photo calories',
                  badge: 'AI Smart',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiMealEstimatorScreen(
                          date: todayStr,
                          onLogged: () => onRefreshDiary?.call(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  icon: Icons.soup_kitchen_outlined,
                  iconColor: Colors.deepPurple,
                  title: 'Recipe Builder',
                  subtitle: 'Custom meals & portions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeBuilderScreen(
                          onSaved: () => onRefreshDiary?.call(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _HubCard(
                  icon: Icons.shopping_cart_outlined,
                  iconColor: Colors.green,
                  title: 'Smart Grocery List',
                  subtitle: 'Auto-categorized shopping',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GroceryListScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  icon: Icons.photo_library_outlined,
                  iconColor: Colors.teal,
                  title: 'Photo Meal Journal',
                  subtitle: 'Visual timeline & meals',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MealPhotoJournalScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 2: Health, Movement & Goals
          Text('ACTIVITY, HEALTH & DEVICES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _HubCard(
                  icon: Icons.fitness_center_outlined,
                  iconColor: Colors.orange,
                  title: 'Workout & Burns',
                  subtitle: 'Track METs & Net Calories',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseScreen(
                          date: todayStr,
                          onUpdated: () => onRefreshDiary?.call(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  icon: Icons.favorite_outline,
                  iconColor: Colors.pink,
                  title: 'Health Connect',
                  subtitle: 'Sync steps & workouts',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HealthSyncScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _HubCard(
                  icon: Icons.calculate_outlined,
                  iconColor: Colors.teal,
                  title: 'TDEE & Target Wizard',
                  subtitle: 'Mifflin-St Jeor planner',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OnboardingWizardScreen(
                          onFinished: () {
                            Navigator.pop(context);
                            onRefreshDiary?.call();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  icon: Icons.widgets_outlined,
                  iconColor: Colors.indigo,
                  title: 'Home Widgets',
                  subtitle: 'Glanceable calorie bars',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WidgetSettingsScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 3: Privacy & Records
          Text('CLINICAL EXPORT & SECURITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade600, letterSpacing: 0.5)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _HubCard(
                  icon: Icons.description_outlined,
                  iconColor: Colors.deepOrange,
                  title: 'Doctor CSV Export',
                  subtitle: 'Medical nutrition report',
                  onTap: () => HealthExportDialog.show(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HubCard(
                  icon: Icons.lock_outline,
                  iconColor: Colors.indigo,
                  title: 'Privacy PIN Lock',
                  subtitle: 'Secure your diet logs',
                  onTap: () => PrivacyLockSettingsDialog.show(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _HubCard(
            icon: Icons.emoji_events_outlined,
            iconColor: Colors.amber.shade700,
            title: 'Achievements & Milestone Streaks',
            subtitle: 'Keep your daily logging streaks alive and unlock 8 health badges',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AchievementsScreen()),
              );
            },
          ),
          const SizedBox(height: 12),
          _HubCard(
            icon: Icons.system_update_alt_rounded,
            iconColor: Colors.blueAccent,
            title: 'Check for Updates',
            subtitle: 'Current: v${AppUpdateService.currentVersion} • Tap to check Google Play for new releases',
            badge: 'Play Store',
            onTap: () => AppUpdateService.instance.manualCheckForUpdates(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(color: iconColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
