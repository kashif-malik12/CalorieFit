import 'package:flutter/material.dart';
import '../services/reminder_service.dart';

class RemindersDialog extends StatefulWidget {
  const RemindersDialog({super.key});

  @override
  State<RemindersDialog> createState() => _RemindersDialogState();
}

class _RemindersDialogState extends State<RemindersDialog> {
  bool _isLoading = true;
  late ReminderSettings _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = await ReminderService.instance.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _isLoading = false;
    });
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required Function(TimeOfDay) onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      onSelected(picked);
      setState(() {});
    }
  }

  Future<void> _save() async {
    await ReminderService.instance.saveSettings(_settings);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder preferences saved successfully!')),
    );
  }

  String _formatTime(TimeOfDay t) {
    final hr = t.hour.toString().padLeft(2, '0');
    final mn = t.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading reminders...'),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.notifications_active, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Reminders',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Meal prompts and water reminders',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Daily Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Receive scheduled nudges to log your meals'),
                value: _settings.enabled,
                onChanged: (val) {
                  setState(() {
                    _settings = _settings.copyWith(enabled: val);
                  });
                },
              ),
              const Divider(height: 20),

              if (_settings.enabled) ...[
                // Breakfast
                _reminderRow(
                  label: 'Breakfast Reminder',
                  enabled: _settings.breakfastEnabled,
                  time: _settings.breakfastTime,
                  onToggle: (v) => setState(() => _settings = _settings.copyWith(breakfastEnabled: v)),
                  onPickTime: () => _pickTime(
                    initialTime: _settings.breakfastTime,
                    onSelected: (t) => _settings = _settings.copyWith(breakfastTime: t),
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 8),

                // Lunch
                _reminderRow(
                  label: 'Lunch Reminder',
                  enabled: _settings.lunchEnabled,
                  time: _settings.lunchTime,
                  onToggle: (v) => setState(() => _settings = _settings.copyWith(lunchEnabled: v)),
                  onPickTime: () => _pickTime(
                    initialTime: _settings.lunchTime,
                    onSelected: (t) => _settings = _settings.copyWith(lunchTime: t),
                  ),
                  theme: theme,
                ),
                const SizedBox(height: 8),

                // Dinner
                _reminderRow(
                  label: 'Dinner Reminder',
                  enabled: _settings.dinnerEnabled,
                  time: _settings.dinnerTime,
                  onToggle: (v) => setState(() => _settings = _settings.copyWith(dinnerEnabled: v)),
                  onPickTime: () => _pickTime(
                    initialTime: _settings.dinnerTime,
                    onSelected: (t) => _settings = _settings.copyWith(dinnerTime: t),
                  ),
                  theme: theme,
                ),
                const Divider(height: 24),

                // Water Reminders
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hydration Nudges 💧', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Remind every ${_settings.waterIntervalHours} hours (9:00 - 21:00)'),
                  value: _settings.waterEnabled,
                  onChanged: (val) {
                    setState(() {
                      _settings = _settings.copyWith(waterEnabled: val);
                    });
                  },
                ),
                if (_settings.waterEnabled) ...[
                  Row(
                    children: [
                      const Text('Interval: ', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      DropdownButton<int>(
                        value: _settings.waterIntervalHours,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Every 1 hour')),
                          DropdownMenuItem(value: 2, child: Text('Every 2 hours')),
                          DropdownMenuItem(value: 3, child: Text('Every 3 hours')),
                          DropdownMenuItem(value: 4, child: Text('Every 4 hours')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _settings = _settings.copyWith(waterIntervalHours: val));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reminderRow({
    required String label,
    required bool enabled,
    required TimeOfDay time,
    required ValueChanged<bool> onToggle,
    required VoidCallback onPickTime,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Checkbox(
          value: enabled,
          onChanged: (v) => onToggle(v ?? false),
        ),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: enabled ? null : theme.disabledColor,
            ),
          ),
        ),
        OutlinedButton(
          onPressed: enabled ? onPickTime : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            minimumSize: Size.zero,
          ),
          child: Text(_formatTime(time)),
        ),
      ],
    );
  }
}
