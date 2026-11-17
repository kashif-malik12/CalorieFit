import 'package:flutter/material.dart';
import '../data/db.dart';
import '../data/models.dart';

class ExerciseScreen extends StatefulWidget {
  final String date;
  final VoidCallback onUpdated;

  const ExerciseScreen({
    super.key,
    required this.date,
    required this.onUpdated,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  List<ExerciseLog> _logs = [];
  bool _isLoading = true;

  final TextEditingController _activityController = TextEditingController(text: 'Running');
  final TextEditingController _durationController = TextEditingController(text: '30');
  final TextEditingController _caloriesController = TextEditingController(text: '300');
  final TextEditingController _stepsController = TextEditingController(text: '3500');

  final List<Map<String, dynamic>> _activityPresets = [
    {'name': 'Running', 'rate': 10.0, 'icon': Icons.directions_run},
    {'name': 'Brisk Walking', 'rate': 4.5, 'icon': Icons.directions_walk},
    {'name': 'Cycling', 'rate': 8.0, 'icon': Icons.directions_bike},
    {'name': 'Gym / Weights', 'rate': 6.0, 'icon': Icons.fitness_center},
    {'name': 'Swimming', 'rate': 9.0, 'icon': Icons.pool},
    {'name': 'HIIT / Cardio', 'rate': 11.0, 'icon': Icons.flash_on},
  ];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _activityController.dispose();
    _durationController.dispose();
    _caloriesController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final list = await AppDb.instance.getExerciseLogsForDate(widget.date);
    if (!mounted) return;
    setState(() {
      _logs = list;
      _isLoading = false;
    });
  }

  void _selectPreset(String name, double burnRatePerMin) {
    _activityController.text = name;
    final mins = int.tryParse(_durationController.text) ?? 30;
    _caloriesController.text = (mins * burnRatePerMin).round().toString();
    if (name.contains('Walk') || name.contains('Run')) {
      _stepsController.text = (mins * (name.contains('Run') ? 140 : 100)).toString();
    } else {
      _stepsController.text = '0';
    }
    setState(() {});
  }

  Future<void> _saveExercise() async {
    final activity = _activityController.text.trim();
    if (activity.isEmpty) return;
    final mins = int.tryParse(_durationController.text) ?? 30;
    final cals = double.tryParse(_caloriesController.text) ?? 200.0;
    final steps = int.tryParse(_stepsController.text) ?? 0;

    await AppDb.instance.insertExerciseLog(ExerciseLog(
      date: widget.date,
      activityName: activity,
      durationMinutes: mins,
      caloriesBurned: cals,
      steps: steps,
    ));

    widget.onUpdated();
    await _loadLogs();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged $activity (-${cals.round()} kcal)!')),
    );
  }

  Future<void> _deleteLog(int id) async {
    await AppDb.instance.deleteExerciseLog(id);
    widget.onUpdated();
    await _loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCaloriesBurned = _logs.fold(0.0, (sum, item) => sum + item.caloriesBurned);
    final totalSteps = _logs.fold(0, (sum, item) => sum + item.steps);

    return Scaffold(
      appBar: AppBar(
        title: Text('Activity & Workouts (${widget.date})'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem(
                            'Calories Burned',
                            '${totalCaloriesBurned.round()} kcal',
                            Icons.local_fire_department,
                            Colors.orange,
                            theme,
                          ),
                          _statItem(
                            'Activity Steps',
                            '$totalSteps',
                            Icons.directions_walk,
                            Colors.blue,
                            theme,
                          ),
                          _statItem(
                            'Activities',
                            '${_logs.length}',
                            Icons.sports,
                            Colors.purple,
                            theme,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Add Workout Form
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Log an Exercise or Activity',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // Quick presets
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _activityPresets.map((p) {
                              final isSelected = _activityController.text == p['name'];
                              return ActionChip(
                                avatar: Icon(p['icon'] as IconData, size: 16),
                                label: Text(p['name'] as String),
                                backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
                                onPressed: () => _selectPreset(p['name'] as String, p['rate'] as double),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _activityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Activity Name',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Minutes',
                                    suffixText: 'm',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    final mins = int.tryParse(val) ?? 0;
                                    final preset = _activityPresets.firstWhere(
                                      (p) => p['name'] == _activityController.text,
                                      orElse: () => {'rate': 7.0},
                                    );
                                    _caloriesController.text = (mins * (preset['rate'] as double)).round().toString();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _caloriesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Burned kcal',
                                    suffixText: 'kcal',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _stepsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Steps (Optional)',
                                    suffixText: 'steps',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Activity to Today'),
                              onPressed: _saveExercise,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's Activity Log
                  Text(
                    "Today's Logged Workouts",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (_logs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No workouts logged for this day.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ),
                    )
                  else
                    ..._logs.map((log) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.orange.withAlpha(30),
                              child: const Icon(Icons.fitness_center, color: Colors.orange),
                            ),
                            title: Text(log.activityName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${log.durationMinutes} mins • ${log.steps} steps'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '-${log.caloriesBurned.round()} kcal',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 14,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                  onPressed: () => _deleteLog(log.id!),
                                ),
                              ],
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withAlpha(25),
          radius: 20,
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      ],
    );
  }
}
