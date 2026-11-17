import 'package:flutter/material.dart';
import '../services/health_sync_service.dart';

class HealthSyncScreen extends StatefulWidget {
  const HealthSyncScreen({super.key});

  @override
  State<HealthSyncScreen> createState() => _HealthSyncScreenState();
}

class _HealthSyncScreenState extends State<HealthSyncScreen> {
  final HealthSyncService _syncService = HealthSyncService();

  bool _autoSync = true;
  bool _exportNutrition = true;
  bool _isLoading = false;
  DateTime? _lastSyncTime;
  HealthSyncResult? _lastResult;

  final TextEditingController _stepsController = TextEditingController(text: '7500');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final auto = await _syncService.isAutoSyncEnabled();
    final export = await _syncService.isExportNutritionEnabled();
    final lastTime = await _syncService.getLastSyncTime();
    if (mounted) {
      setState(() {
        _autoSync = auto;
        _exportNutrition = export;
        _lastSyncTime = lastTime;
      });
    }
  }

  Future<void> _performSync() async {
    setState(() => _isLoading = true);
    final steps = int.tryParse(_stepsController.text.trim()) ?? 7500;

    final result = await _syncService.syncActivityForDate(DateTime.now(), simulatedSteps: steps);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _lastResult = result;
        _lastSyncTime = result.syncTime;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Health Connect Sync'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner card
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.favorite, size: 32, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Google Health Connect',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sync steps, active workouts, and burned calories directly with Google Fit and Android Health Connect.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Sync status
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.sync, color: theme.colorScheme.secondary),
            title: const Text('Last Synchronized', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _lastSyncTime != null
                  ? '${_lastSyncTime!.month}/${_lastSyncTime!.day} at ${_lastSyncTime!.hour}:${_lastSyncTime!.minute.toString().padLeft(2, '0')}'
                  : 'Never synced',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Connected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
          const Divider(),

          // Permissions & Toggles
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto-sync Steps & Workouts'),
            subtitle: const Text('Automatically sync activity in background and update Net Calories.'),
            value: _autoSync,
            onChanged: (val) async {
              setState(() => _autoSync = val);
              await _syncService.setAutoSyncEnabled(val);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Export Nutrition to Health Connect'),
            subtitle: const Text('Send logged food calories, protein, carbs, fat, and water to health apps.'),
            value: _exportNutrition,
            onChanged: (val) async {
              setState(() => _exportNutrition = val);
              await _syncService.setExportNutritionEnabled(val);
            },
          ),

          const SizedBox(height: 20),
          Text('Manual Sync / Step Entry', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _stepsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Step Count for Today',
                    prefixIcon: const Icon(Icons.directions_walk),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _performSync,
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),
              ),
            ],
          ),

          if (_lastResult != null) ...[
            const SizedBox(height: 24),
            Text('Recent Sync Summary', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      icon: Icons.directions_walk,
                      title: 'Steps',
                      value: '${_lastResult!.steps}',
                      color: Colors.blue,
                    ),
                    _MetricColumn(
                      icon: Icons.local_fire_department,
                      title: 'Burned',
                      value: '${_lastResult!.caloriesBurned.round()} kcal',
                      color: Colors.deepOrange,
                    ),
                    _MetricColumn(
                      icon: Icons.route,
                      title: 'Distance',
                      value: '${_lastResult!.distanceKm} km',
                      color: Colors.teal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _MetricColumn({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }
}
