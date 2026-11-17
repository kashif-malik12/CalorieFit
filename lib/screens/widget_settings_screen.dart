import 'package:flutter/material.dart';
import '../services/widget_sync_service.dart';

class WidgetSettingsScreen extends StatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  State<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends State<WidgetSettingsScreen> {
  final WidgetSyncService _widgetService = WidgetSyncService();
  Map<String, dynamic>? _widgetData;
  int _selectedStyle = 0; // 0: Ring & Net Calories, 1: Macro Split, 2: Fasting Companion

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final data = await _widgetService.updateWidgetData();
    if (mounted) {
      setState(() => _widgetData = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen Widgets'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Widget Live Preview',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep your macros, calorie budget, and fasting status on your Android home screen at a glance.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          // Widget Preview Card
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: _widgetData == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSelectedWidgetView(theme),
            ),
          ),

          const SizedBox(height: 24),
          Text('Choose Widget Style', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Net Calories'), icon: Icon(Icons.pie_chart_outline)),
              ButtonSegment(value: 1, label: Text('Macro Split'), icon: Icon(Icons.bar_chart)),
              ButtonSegment(value: 2, label: Text('Fasting Timer'), icon: Icon(Icons.timer_outlined)),
            ],
            selected: {_selectedStyle},
            onSelectionChanged: (set) => setState(() => _selectedStyle = set.first),
          ),

          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: theme.colorScheme.secondary),
                      const SizedBox(width: 8),
                      Text('How to Add to Home Screen', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Long-press any empty space on your Android Home Screen.\n'
                      '2. Tap "Widgets" from the popup menu.\n'
                      '3. Scroll to "CalorieFit" and drag the widget onto your screen.\n'
                      '4. Tap the widget anytime to instantly log water, view your fast, or add food.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              await _widgetService.quickLogWater(250);
              await _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulated Widget Quick Action: Logged +250ml Water!')),
                );
              }
            },
            icon: const Icon(Icons.local_drink),
            label: const Text('Test Quick Action: +250ml Water'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedWidgetView(ThemeData theme) {
    final d = _widgetData!;
    final remaining = ((d['remainingCalories'] as num?) ?? 0).round();
    final consumed = ((d['calorieConsumed'] as num?) ?? 0).round();
    final burned = ((d['calorieBurned'] as num?) ?? 0).round();
    final net = ((d['netCalories'] as num?) ?? 0).round();
    final budget = ((d['calorieBudget'] as num?) ?? 2000).round();

    if (_selectedStyle == 0) {
      // Net Calories & Ring
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 6),
                  const Text('CalorieFit Daily', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('💧 ${d['waterGlasses']} glasses', style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$remaining',
                      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                    const Text('Calories Remaining', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Food: $consumed', style: const TextStyle(fontSize: 11)),
                  Text('Burn: -$burned', style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
                  Text('Net: $net / $budget', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      );
    } else if (_selectedStyle == 1) {
      // Macro Split
      final p = ((d['proteinGrams'] as num?) ?? 0).round();
      final pTarget = ((d['proteinTarget'] as num?) ?? 140).round();
      final c = ((d['carbsGrams'] as num?) ?? 0).round();
      final cTarget = ((d['carbsTarget'] as num?) ?? 200).round();
      final f = ((d['fatGrams'] as num?) ?? 0).round();
      final fTarget = ((d['fatTarget'] as num?) ?? 65).round();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Macros Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          _MacroBarRow(label: 'Protein', current: p, target: pTarget, color: Colors.blue),
          const SizedBox(height: 6),
          _MacroBarRow(label: 'Carbs', current: c, target: cTarget, color: Colors.amber.shade800),
          const SizedBox(height: 6),
          _MacroBarRow(label: 'Fat', current: f, target: fTarget, color: Colors.purple),
        ],
      );
    } else {
      // Fasting Companion
      final isFasting = d['fastStatus'] == 'FASTING';
      final percent = ((d['fastProgressPercent'] as num?) ?? 0).round();
      final remainingMins = ((d['fastRemainingMinutes'] as num?) ?? 0).toInt();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fasting Companion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isFasting ? Colors.teal.withOpacity(0.12) : Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isFasting ? 'FASTING' : 'EATING WINDOW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isFasting ? Colors.teal : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircularProgressIndicator(
                value: isFasting ? (percent / 100) : 0,
                backgroundColor: Colors.grey.shade200,
                color: Colors.teal,
                strokeWidth: 6,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFasting ? '$percent% Complete' : 'Ready to start',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      isFasting ? '${(remainingMins / 60).toStringAsFixed(1)}h remaining' : 'Select a preset to fast',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }
}

class _MacroBarRow extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _MacroBarRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$current / $target g', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 3),
        LinearProgressIndicator(
          value: ratio,
          color: color,
          backgroundColor: color.withOpacity(0.15),
          minHeight: 6,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
