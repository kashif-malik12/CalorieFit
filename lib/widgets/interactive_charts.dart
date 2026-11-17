import 'dart:math' as math;
import 'package:flutter/material.dart';

class MacroChartData {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const MacroChartData({
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  double get totalGrams => proteinGrams + carbsGrams + fatGrams;
  double get proteinKcal => proteinGrams * 4;
  double get carbsKcal => carbsGrams * 4;
  double get fatKcal => fatGrams * 9;
  double get totalKcal => proteinKcal + carbsKcal + fatKcal;

  double get proteinPct => totalKcal > 0 ? (proteinKcal / totalKcal) * 100 : 0;
  double get carbsPct => totalKcal > 0 ? (carbsKcal / totalKcal) * 100 : 0;
  double get fatPct => totalKcal > 0 ? (fatKcal / totalKcal) * 100 : 0;
}

class MacroDonutChart extends StatelessWidget {
  final MacroChartData data;
  final double size;

  const MacroDonutChart({
    super.key,
    required this.data,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutChartPainter(
                  proteinPct: data.proteinPct,
                  carbsPct: data.carbsPct,
                  fatPct: data.fatPct,
                  isDark: isDark,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${data.totalKcal.round()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'macro kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(
              color: const Color(0xFF00897B),
              label: 'Protein',
              grams: data.proteinGrams,
              pct: data.proteinPct,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _legendItem(
              color: const Color(0xFFF57C00),
              label: 'Carbs',
              grams: data.carbsGrams,
              pct: data.carbsPct,
              theme: theme,
            ),
            const SizedBox(height: 8),
            _legendItem(
              color: const Color(0xFFE53935),
              label: 'Fat',
              grams: data.fatGrams,
              pct: data.fatPct,
              theme: theme,
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendItem({
    required Color color,
    required String label,
    required double grams,
    required double pct,
    required ThemeData theme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          '${grams.round()}g (${pct.round()}%)',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double proteinPct;
  final double carbsPct;
  final double fatPct;
  final bool isDark;

  _DonutChartPainter({
    required this.proteinPct,
    required this.carbsPct,
    required this.fatPct,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    final backgroundPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, backgroundPaint);

    final total = proteinPct + carbsPct + fatPct;
    if (total <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    double startAngle = -math.pi / 2;

    void drawSegment(double pct, Color color) {
      if (pct <= 0) return;
      final sweepAngle = (pct / 100) * 2 * math.pi;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Small gap between segments
      final adjustedSweep = sweepAngle > 0.08 ? sweepAngle - 0.04 : sweepAngle;
      canvas.drawArc(rect, startAngle + 0.02, adjustedSweep, false, paint);
      startAngle += sweepAngle;
    }

    drawSegment(proteinPct, const Color(0xFF00897B));
    drawSegment(carbsPct, const Color(0xFFF57C00));
    drawSegment(fatPct, const Color(0xFFE53935));
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.proteinPct != proteinPct ||
        oldDelegate.carbsPct != carbsPct ||
        oldDelegate.fatPct != fatPct ||
        oldDelegate.isDark != isDark;
  }
}

class WeightPoint {
  final String date;
  final double weight;
  const WeightPoint({required this.date, required this.weight});
}

class WeightTrendChart extends StatelessWidget {
  final List<WeightPoint> points;
  final double height;
  final String unit;

  const WeightTrendChart({
    super.key,
    required this.points,
    this.height = 160,
    this.unit = 'kg',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Log your weight to see progress charts',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
      );
    }

    final sorted = List<WeightPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    final minWeight = sorted.map((p) => p.weight).reduce(math.min);
    final maxWeight = sorted.map((p) => p.weight).reduce(math.max);
    final delta = sorted.last.weight - sorted.first.weight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Latest: ${sorted.last.weight.toStringAsFixed(1)} $unit',
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: delta <= 0 ? Colors.green.withAlpha(30) : Colors.amber.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Delta: ${delta >= 0 ? "+" : ""}${delta.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: delta <= 0 ? Colors.green.shade700 : Colors.amber.shade800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _WeightLineChartPainter(
              points: sorted,
              minWeight: minWeight,
              maxWeight: maxWeight,
              lineColor: theme.colorScheme.primary,
              isDark: theme.brightness == Brightness.dark,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sorted.first.date.substring(5),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
            ),
            if (sorted.length > 2)
              Text(
                sorted[sorted.length ~/ 2].date.substring(5),
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
              ),
            Text(
              sorted.last.date.substring(5),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: theme.hintColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightLineChartPainter extends CustomPainter {
  final List<WeightPoint> points;
  final double minWeight;
  final double maxWeight;
  final Color lineColor;
  final bool isDark;

  _WeightLineChartPainter({
    required this.points,
    required this.minWeight,
    required this.maxWeight,
    required this.lineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 16.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;

    final gridPaint = Paint()
      ..color = isDark ? Colors.white10 : Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw baseline and top line
    canvas.drawLine(
      Offset(padding, padding),
      Offset(size.width - padding, padding),
      gridPaint,
    );
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      gridPaint,
    );

    if (points.length == 1) {
      final p = Offset(size.width / 2, size.height / 2);
      canvas.drawCircle(p, 6, Paint()..color = lineColor);
      return;
    }

    final span = (maxWeight - minWeight).abs();
    final weightRange = span == 0 ? 1.0 : span;

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = padding + (i / (points.length - 1)) * chartWidth;
      final normalized = (points[i].weight - minWeight) / weightRange;
      final y = (size.height - padding) - (normalized * chartHeight);
      offsets.add(Offset(x, y));
    }

    // Gradient fill under the curve
    final path = Path()..moveTo(offsets.first.dx, size.height - padding);
    for (final pt in offsets) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.lineTo(offsets.last.dx, size.height - padding);
    path.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withAlpha(60),
          lineColor.withAlpha(5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);

    // Line stroke
    final strokePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (int i = 1; i < offsets.length; i++) {
      strokePath.lineTo(offsets[i].dx, offsets[i].dy);
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(strokePath, linePaint);

    // Points
    final dotPaint = Paint()..color = lineColor;
    final dotInner = Paint()..color = isDark ? Colors.black87 : Colors.white;

    for (final pt in offsets) {
      canvas.drawCircle(pt, 4.5, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInner);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightLineChartPainter oldDelegate) => true;
}

class DailyCalorieBarData {
  final String dayLabel; // e.g. "Mon"
  final double calories;
  final double target;

  const DailyCalorieBarData({
    required this.dayLabel,
    required this.calories,
    required this.target,
  });
}

class WeeklyCalorieBarChart extends StatelessWidget {
  final List<DailyCalorieBarData> days;
  final double height;

  const WeeklyCalorieBarChart({
    super.key,
    required this.days,
    this.height = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxVal = days.map((d) => math.max(d.calories, d.target)).reduce(math.max);
    final upper = maxVal > 0 ? maxVal * 1.15 : 2500.0;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final barPct = (day.calories / upper).clamp(0.0, 1.0);
          final isOver = day.target > 0 && day.calories > day.target;
          final barColor = day.calories == 0
              ? (isDark ? Colors.white12 : Colors.grey.shade300)
              : (isOver ? Colors.orange.shade600 : theme.colorScheme.primary);

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    day.calories > 0 ? '${day.calories.round()}' : '-',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isOver ? Colors.orange.shade700 : theme.hintColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: (height - 38) * barPct,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    day.dayLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
