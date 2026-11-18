import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/db.dart';
import '../data/models.dart';

class ModernCalorieDashboard extends StatefulWidget {
  final int takenCalories;
  final int targetCalories;
  final double burnedCalories;
  final DayTotals totals;
  final MacroTargets targets;
  final VoidCallback onEditTargets;

  const ModernCalorieDashboard({
    super.key,
    required this.takenCalories,
    required this.targetCalories,
    this.burnedCalories = 0.0,
    required this.totals,
    required this.targets,
    required this.onEditTargets,
  });

  @override
  State<ModernCalorieDashboard> createState() => _ModernCalorieDashboardState();
}

class _ModernCalorieDashboardState extends State<ModernCalorieDashboard> {
  bool _showMicros = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = widget.targetCalories <= 0 ? 2000 : widget.targetCalories;
    final eaten = widget.takenCalories;
    final burned = widget.burnedCalories.round();
    final net = eaten - burned;
    final remaining = target - net;
    final progress = (net / target).clamp(0.0, 1.0);
    final isOver = remaining < 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header row with Target Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'Daily Energy Budget',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onEditTargets,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Goal',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hero Ring & Quick Stats
          Row(
            children: [
              // Circular Gauge
              SizedBox(
                width: 128,
                height: 128,
                child: CustomPaint(
                  painter: _CalorieGaugePainter(
                    progress: progress,
                    progressColor: isOver ? Colors.deepOrange : theme.colorScheme.primary,
                    bgColor: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${remaining.abs()}',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isOver ? Colors.deepOrange : theme.colorScheme.primary,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          isOver ? 'kcal over' : 'kcal left',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOver ? Colors.deepOrange : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Budget Breakdown column
              Expanded(
                child: Column(
                  children: [
                    _BudgetRow(
                      icon: Icons.flag_outlined,
                      label: 'Goal',
                      value: '$target kcal',
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 8),
                    _BudgetRow(
                      icon: Icons.restaurant,
                      label: 'Food Eaten',
                      value: '$eaten kcal',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _BudgetRow(
                      icon: Icons.local_fire_department,
                      label: 'Exercise Burn',
                      value: '-$burned kcal',
                      color: Colors.deepOrange,
                    ),
                    const Divider(height: 16),
                    _BudgetRow(
                      icon: Icons.pie_chart,
                      label: 'Net Calories',
                      value: '$net kcal',
                      color: isOver ? Colors.deepOrange : Colors.teal,
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3-Macro Row (Protein, Carbs, Fat)
          Row(
            children: [
              Expanded(
                child: _MacroPillCard(
                  name: 'Protein',
                  current: widget.totals.protein,
                  target: widget.targets.protein.toDouble(),
                  color: const Color(0xFF2563EB), // Modern Royal Blue
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPillCard(
                  name: 'Carbs',
                  current: widget.totals.carbs,
                  target: widget.targets.carbs.toDouble(),
                  color: const Color(0xFFD97706), // Modern Amber
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroPillCard(
                  name: 'Fat',
                  current: widget.totals.fat,
                  target: widget.targets.fat.toDouble(),
                  color: const Color(0xFF9333EA), // Modern Purple
                ),
              ),
            ],
          ),

          // Collapsible Micronutrients Bar
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _showMicros = !_showMicros),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showMicros ? 'Hide Micronutrients' : 'Detailed Micronutrients (Fiber, Sodium, Sat. Fat)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(_showMicros ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: theme.colorScheme.primary),
                ],
              ),
            ),
          ),

          if (_showMicros) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _MicroRow(
                    label: 'Dietary Fiber',
                    value: '${widget.totals.fiber.toStringAsFixed(1)}g',
                    target: '${widget.targets.fiber}g',
                    isOk: widget.totals.fiber >= widget.targets.fiber,
                  ),
                  const SizedBox(height: 6),
                  _MicroRow(
                    label: 'Sodium Limit',
                    value: '${widget.totals.sodium.round()}mg',
                    target: 'max ${widget.targets.sodium}mg',
                    isOk: widget.totals.sodium <= widget.targets.sodium,
                  ),
                  const SizedBox(height: 6),
                  _MicroRow(
                    label: 'Added Sugar',
                    value: '${widget.totals.sugar.toStringAsFixed(1)}g',
                    target: 'max ${widget.targets.sugar}g',
                    isOk: widget.totals.sugar <= widget.targets.sugar,
                  ),
                  const SizedBox(height: 6),
                  _MicroRow(
                    label: 'Saturated Fat',
                    value: '${widget.totals.saturatedFat.toStringAsFixed(1)}g',
                    target: 'max ${widget.targets.saturatedFat}g',
                    isOk: widget.totals.saturatedFat <= widget.targets.saturatedFat,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalorieGaugePainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color bgColor;

  const _CalorieGaugePainter({
    required this.progress,
    required this.progressColor,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 11.0;

    // Background track
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieGaugePainter old) =>
      old.progress != progress || old.progressColor != progressColor || old.bgColor != bgColor;
}

class _BudgetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _BudgetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isBold ? Colors.black87 : Colors.grey.shade600,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? color : Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _MacroPillCard extends StatelessWidget {
  final String name;
  final double current;
  final double target;
  final Color color;

  const _MacroPillCard({
    required this.name,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final safeTarget = target <= 0 ? 1.0 : target;
    final ratio = (current / safeTarget).clamp(0.0, 1.0);
    final curStr = current.toStringAsFixed(current == current.roundToDouble() ? 0 : 1);
    final tgtStr = target.toStringAsFixed(target == target.roundToDouble() ? 0 : 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              color: color,
              backgroundColor: color.withOpacity(0.15),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$curStr / $tgtStr g',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MicroRow extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final bool isOk;

  const _MicroRow({
    required this.label,
    required this.value,
    required this.target,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        Row(
          children: [
            Text('$value ($target)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(isOk ? Icons.check_circle : Icons.warning_amber, size: 14, color: isOk ? Colors.green : Colors.deepOrange),
          ],
        ),
      ],
    );
  }
}
