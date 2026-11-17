import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/report_service.dart';
import '../widgets/interactive_charts.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedDays = 7;
  bool _isLoading = true;
  NutritionHealthReport? _report;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final report = await ReportService.instance.generateReport(days: _selectedDays);
    if (!mounted) return;
    setState(() {
      _report = report;
      _isLoading = false;
    });
  }

  void _copyToClipboard() {
    final report = _report;
    if (report == null) return;
    final text = ReportService.instance.exportAsPlainText(report);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard! Ready to share with coach or friends.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('MMM dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Nutrition Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all),
            tooltip: 'Copy Report',
            onPressed: _report != null ? _copyToClipboard : null,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _report == null
              ? const Center(child: Text('Could not generate report'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time Filter Chips
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('7 Days'),
                            selected: _selectedDays == 7,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedDays = 7);
                                _loadReport();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('14 Days'),
                            selected: _selectedDays == 14,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedDays = 14);
                                _loadReport();
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('30 Days'),
                            selected: _selectedDays == 30,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedDays = 30);
                                _loadReport();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Header Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${df.format(_report!.startDate)} - ${df.format(_report!.endDate)}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withAlpha(25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_report!.loggedDaysCount}/${_report!.periodDays} Days Active',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _metricColumn(
                                    'Daily Avg',
                                    '${_report!.avgDailyCalories.round()} kcal',
                                    'Goal: ${_report!.targetCalories.round()}',
                                    theme,
                                  ),
                                  _metricColumn(
                                    'Water Avg',
                                    '${(_report!.avgDailyWaterMl / 1000).toStringAsFixed(1)} L',
                                    'Goal: ${(_report!.targetWaterMl / 1000).toStringAsFixed(1)} L',
                                    theme,
                                  ),
                                  if (_report!.currentWeight != null)
                                    _metricColumn(
                                      'Weight',
                                      '${_report!.currentWeight!.toStringAsFixed(1)} ${_report!.weightUnit}',
                                      'Delta: ${_report!.weightDelta >= 0 ? "+" : ""}${_report!.weightDelta.toStringAsFixed(1)}',
                                      theme,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Macro Distribution Donut Chart
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Average Daily Macronutrients',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              MacroDonutChart(
                                data: MacroChartData(
                                  proteinGrams: _report!.avgProtein,
                                  carbsGrams: _report!.avgCarbs,
                                  fatGrams: _report!.avgFat,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  'Dietary Fiber Average: ${_report!.avgFiber.toStringAsFixed(1)}g / day',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Coach Observations Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.lightbulb, color: Colors.amber, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Coach Insights & Observations',
                                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._report!.coachObservations.map((obs) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Expanded(
                                          child: Text(
                                            obs,
                                            style: const TextStyle(fontSize: 13, height: 1.3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Share Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.share),
                          label: const Text('Copy & Share Full Report'),
                          onPressed: _copyToClipboard,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _metricColumn(String title, String value, String sub, ThemeData theme) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 11, color: theme.hintColor)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 11, color: theme.hintColor)),
      ],
    );
  }
}
