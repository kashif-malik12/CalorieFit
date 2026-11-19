import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../data/models.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  FastingSession? _activeSession;
  List<FastingSession> _history = [];
  bool _isLoading = true;
  Timer? _ticker;

  String _selectedProtocol = '16:8';
  double _targetHours = 16.0;

  final Map<String, double> _protocols = {
    '14:10 Gentle': 14.0,
    '16:8 LeanGains': 16.0,
    '18:6 Intermediate': 18.0,
    '20:4 Warrior': 20.0,
    '24h Circadian': 24.0,
  };

  @override
  void initState() {
    super.initState();
    _loadFastingData();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_activeSession != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadFastingData() async {
    setState(() => _isLoading = true);
    try {
      final active = await AppDb.instance.getActiveFastingSession();
      final hist = await AppDb.instance.getRecentFastingSessions(limit: 15);
      if (!mounted) return;
      setState(() {
        _activeSession = active;
        _history = hist;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startFast() async {
    await AppDb.instance.startFastingSession(
      protocol: _selectedProtocol,
      targetHours: _targetHours,
    );
    await _loadFastingData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Started $_selectedProtocol fasting window! Stay hydrated 💧')),
    );
  }

  Future<void> _endFast() async {
    final active = _activeSession;
    if (active?.id == null) return;

    final isTargetMet = active!.elapsed.inMinutes >= (active.targetHours * 60);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Fasting Session?'),
        content: Text(
          isTargetMet
              ? 'Awesome job! You reached your goal of ${active.targetHours.round()} hours!'
              : 'You have fasted for ${_formatDuration(active.elapsed)}. End session now?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Continue Fasting')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('End Fast')),
        ],
      ),
    );

    if (confirm == true) {
      await AppDb.instance.endFastingSession(active.id!, isCompleted: isTargetMet);
      await _loadFastingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fasting session recorded successfully!')),
      );
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _fastingStageDescription(Duration d) {
    final hours = d.inMinutes / 60;
    if (hours < 4) {
      return '🟢 Blood Sugar Normalizing (Digesting meal)';
    } else if (hours < 8) {
      return '🟡 Blood Sugar Drops (Insulin levels decrease)';
    } else if (hours < 12) {
      return '🟠 Glycogen Depletion (Body shifts toward fat burning)';
    } else if (hours < 16) {
      return '🔥 Active Ketosis (Fat burning stage unlocked)';
    } else {
      return '✨ Autophagy & Cellular Repair Phase';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFasting = _activeSession != null;
    final df = DateFormat('MMM dd, HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Intermittent Fasting'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fasting Timer Card
                  Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            isFasting ? 'YOU ARE FASTING' : 'READY TO FAST',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: isFasting ? Colors.teal : theme.hintColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Circular Progress Ring
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 190,
                                  height: 190,
                                  child: CircularProgressIndicator(
                                    value: isFasting ? _activeSession!.progressPercent : 0.0,
                                    strokeWidth: 14,
                                    backgroundColor: theme.colorScheme.primary.withAlpha(25),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isFasting && _activeSession!.progressPercent >= 1.0
                                          ? Colors.green
                                          : theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isFasting ? Icons.timer : Icons.hourglass_empty,
                                      color: theme.colorScheme.primary,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      isFasting ? _formatDuration(_activeSession!.elapsed) : '00:00:00',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    Text(
                                      isFasting
                                          ? 'Goal: ${_activeSession!.targetHours.round()} hrs (${(_activeSession!.progressPercent * 100).round()}%)'
                                          : 'Select Goal Below',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Fasting stage / status
                          if (isFasting) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withAlpha(50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _fastingStageDescription(_activeSession!.elapsed),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Started: ${df.format(_activeSession!.startTime)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.stop_circle_outlined),
                                label: const Text('End Fast & Log Session'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _endFast,
                              ),
                            ),
                          ] else ...[
                            // Protocol selector chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _protocols.entries.map((e) {
                                final isSelected = _selectedProtocol == e.key;
                                return ChoiceChip(
                                  label: Text(e.key),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) {
                                      setState(() {
                                        _selectedProtocol = e.key;
                                        _targetHours = e.value;
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.play_arrow),
                                label: Text('Start Fast ($_targetHours hrs)'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: _startFast,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Fasting Sessions',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_history.length} logged',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_history.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No completed fasts yet. Start your first session above!',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ),
                    )
                  else
                    ..._history.map((s) {
                      final reached = s.isCompleted || s.elapsed.inMinutes >= (s.targetHours * 60);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: reached ? Colors.green.withAlpha(30) : Colors.amber.withAlpha(30),
                            child: Icon(
                              reached ? Icons.check : Icons.hourglass_top,
                              color: reached ? Colors.green : Colors.amber.shade800,
                            ),
                          ),
                          title: Text(
                            '${s.protocol} (${(s.elapsed.inMinutes / 60).toStringAsFixed(1)} hrs fasted)',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${df.format(s.startTime)} • Goal: ${s.targetHours.round()}h',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: reached ? Colors.green.withAlpha(20) : Colors.grey.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              reached ? 'Goal Met' : 'Ended Early',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: reached ? Colors.green.shade700 : theme.hintColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
