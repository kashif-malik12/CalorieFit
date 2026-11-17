import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../data/db.dart';
import '../data/models.dart';
import '../settings/target_settings.dart';

class TdeeCalculationResult {
  final double bmr;
  final double tdee;
  final double targetCalories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  const TdeeCalculationResult({
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  static TdeeCalculationResult calculate({
    required bool isMale,
    required int age,
    required double heightCm,
    required double weightKg,
    required double activityMultiplier,
    required String goal, // 'lose', 'maintain', 'gain'
  }) {
    // Mifflin-St Jeor Equation
    final s = isMale ? 5.0 : -161.0;
    final bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + s;
    final tdee = bmr * activityMultiplier;

    double targetCalories = tdee;
    if (goal == 'lose') {
      targetCalories = tdee - 500;
    } else if (goal == 'gain') {
      targetCalories = tdee + 300;
    }

    if (targetCalories < 1200) targetCalories = 1200;

    // Macro Split: Protein ~2g per kg, Fat ~25% total kcal, Carbs remainder
    final proteinGrams = (weightKg * 2.0).clamp(60.0, 250.0);
    final proteinKcal = proteinGrams * 4.0;

    final fatKcal = targetCalories * 0.25;
    final fatGrams = (fatKcal / 9.0).clamp(30.0, 150.0);

    final carbsKcal = (targetCalories - proteinKcal - fatKcal).clamp(0.0, targetCalories);
    final carbsGrams = (carbsKcal / 4.0).clamp(50.0, 500.0);

    return TdeeCalculationResult(
      bmr: double.parse(bmr.toStringAsFixed(0)),
      tdee: double.parse(tdee.toStringAsFixed(0)),
      targetCalories: double.parse(targetCalories.toStringAsFixed(0)),
      proteinGrams: double.parse(proteinGrams.toStringAsFixed(0)),
      carbsGrams: double.parse(carbsGrams.toStringAsFixed(0)),
      fatGrams: double.parse(fatGrams.toStringAsFixed(0)),
    );
  }
}

class OnboardingWizardScreen extends StatefulWidget {
  final VoidCallback onFinished;

  const OnboardingWizardScreen({super.key, required this.onFinished});

  static const String prefKeyCompleted = 'onboarding_wizard_completed';

  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyCompleted) ?? false;
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyCompleted, true);
  }

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Goal
  String _selectedGoal = 'lose'; // 'lose', 'maintain', 'gain'

  // Step 2: Biometrics
  bool _isMale = true;
  final TextEditingController _ageCtrl = TextEditingController(text: '28');
  final TextEditingController _heightCtrl = TextEditingController(text: '175');
  final TextEditingController _weightCtrl = TextEditingController(text: '75');

  // Step 3: Activity Level
  double _activityMultiplier = 1.375; // Light activity

  // Step 4: Result
  TdeeCalculationResult? _result;

  @override
  void dispose() {
    _pageController.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  void _computePlan() {
    final age = int.tryParse(_ageCtrl.text) ?? 25;
    final height = double.tryParse(_heightCtrl.text) ?? 170.0;
    final weight = double.tryParse(_weightCtrl.text) ?? 70.0;

    final res = TdeeCalculationResult.calculate(
      isMale: _isMale,
      age: age,
      heightCm: height,
      weightKg: weight,
      activityMultiplier: _activityMultiplier,
      goal: _selectedGoal,
    );

    setState(() => _result = res);
  }

  void _nextPage() {
    if (_currentStep == 2) {
      _computePlan();
    }
    if (_currentStep < 3) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  Future<void> _saveAndFinish() async {
    if (_result != null) {
      await TargetSettings.setCalories(_result!.targetCalories.round());
      await TargetSettings.setProtein(_result!.proteinGrams.round());
      await TargetSettings.setCarbs(_result!.carbsGrams.round());
      await TargetSettings.setFat(_result!.fatGrams.round());
    }
    await OnboardingWizardScreen.markCompleted();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CalorieFit Setup Wizard'),
        actions: [
          TextButton(
            onPressed: () async {
              await OnboardingWizardScreen.markCompleted();
              widget.onFinished();
            },
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: theme.colorScheme.surfaceVariant,
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentStep = i),
              children: [
                _buildGoalStep(theme),
                _buildBiometricsStep(theme),
                _buildActivityStep(theme),
                _buildResultStep(theme),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: _currentStep == 3 ? _saveAndFinish : _nextPage,
                  child: Text(_currentStep == 3 ? 'Apply & Get Started' : 'Continue'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('What is your primary fitness goal?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('We will personalize your daily calorie and macronutrient targets based on your choice.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        _GoalCard(
          title: '🔥 Fat Loss & Toning',
          subtitle: 'Create a healthy 500 kcal deficit to lose body fat gradually and sustainably.',
          selected: _selectedGoal == 'lose',
          onTap: () => setState(() => _selectedGoal = 'lose'),
        ),
        const SizedBox(height: 14),
        _GoalCard(
          title: '⚖️ Weight Maintenance & Health',
          subtitle: 'Eat at your exact maintenance energy level to optimize vitality and performance.',
          selected: _selectedGoal == 'maintain',
          onTap: () => setState(() => _selectedGoal = 'maintain'),
        ),
        const SizedBox(height: 14),
        _GoalCard(
          title: '💪 Lean Muscle Gain & Strength',
          subtitle: 'A lean 300 kcal surplus combined with high protein for muscle hypertrophy.',
          selected: _selectedGoal == 'gain',
          onTap: () => setState(() => _selectedGoal = 'gain'),
        ),
      ],
    );
  }

  Widget _buildBiometricsStep(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('Tell us about yourself', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Used exclusively on your device for accurate Basal Metabolic Rate (BMR) math.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Male 👨')),
                selected: _isMale,
                onSelected: (s) => setState(() => _isMale = true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Female 👩')),
                selected: !_isMale,
                onSelected: (s) => setState(() => _isMale = false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Age (years)',
            prefixIcon: const Icon(Icons.cake_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _heightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Height (cm)',
            prefixIcon: const Icon(Icons.height),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Current Weight (kg)',
            prefixIcon: const Icon(Icons.monitor_weight_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStep(ThemeData theme) {
    final activities = [
      {'title': 'Sedentary', 'desc': 'Desk job, minimal daily movement', 'val': 1.2},
      {'title': 'Lightly Active', 'desc': 'Light walking or exercise 1-3 days/week', 'val': 1.375},
      {'title': 'Moderately Active', 'desc': 'Moderate workouts or sports 3-5 days/week', 'val': 1.55},
      {'title': 'Very Active', 'desc': 'Heavy training or physical labor 6-7 days/week', 'val': 1.725},
      {'title': 'Athlete / Heavy Labor', 'desc': 'Intense training twice daily or athletic sport', 'val': 1.9},
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('How active are you daily?', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Your activity level multiplies your resting metabolic rate.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        ...activities.map((a) {
          final isSel = _activityMultiplier == a['val'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => setState(() => _activityMultiplier = a['val'] as double),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSel ? theme.colorScheme.primary : Colors.grey.shade300,
                    width: isSel ? 2 : 1,
                  ),
                  color: isSel ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSel ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSel ? theme.colorScheme.primary : Colors.grey,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(a['desc'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultStep(ThemeData theme) {
    if (_result == null) return const SizedBox.shrink();
    final res = _result!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        Text('Your Personalized Nutrition Plan 🎉', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Calculated via the scientifically validated Mifflin-St Jeor formula.', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 20),

        Card(
          elevation: 0,
          color: theme.colorScheme.primaryContainer.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Daily Calorie Budget', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 6),
                Text(
                  '${res.targetCalories.round()} kcal',
                  style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 8),
                Text('BMR: ${res.bmr.round()} kcal | TDEE: ${res.tdee.round()} kcal', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Recommended Macro Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _MacroPill(title: 'Protein', grams: '${res.proteinGrams.round()}g', color: Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _MacroPill(title: 'Carbs', grams: '${res.carbsGrams.round()}g', color: Colors.amber.shade800)),
            const SizedBox(width: 8),
            Expanded(child: _MacroPill(title: 'Fat', grams: '${res.fatGrams.round()}g', color: Colors.purple)),
          ],
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String title;
  final String grams;
  final Color color;

  const _MacroPill({required this.title, required this.grams, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(grams, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }
}
