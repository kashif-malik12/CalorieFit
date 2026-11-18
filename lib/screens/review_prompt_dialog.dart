import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_update_service.dart';

class ReviewPromptDialog extends StatefulWidget {
  const ReviewPromptDialog({super.key});

  static const _kRatedKey = 'app_reviewed_or_dismissed';

  static Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kRatedKey) ?? false);
  }

  static Future<void> markDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kRatedKey, true);
  }

  @override
  State<ReviewPromptDialog> createState() => _ReviewPromptDialogState();
}

class _ReviewPromptDialogState extends State<ReviewPromptDialog> {
  int _rating = 5;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    await ReviewPromptDialog.markDismissed();
    if (!mounted) return;
    Navigator.of(context).pop();

    if (_rating >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you so much! Opening Google Play Store... ⭐⭐⭐⭐⭐'),
        ),
      );
      await AppUpdateService.instance.openPlayStore();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your valuable feedback! We are working hard to improve.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoying CalorieFit?',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Your feedback helps us remain local-first, privacy-respecting, and fast for everyone.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
              const SizedBox(height: 16),

              // Star Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNum = index + 1;
                  return IconButton(
                    iconSize: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    icon: Icon(
                      starNum <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      setState(() => _rating = starNum);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),

              if (_rating >= 4) ...[
                Text(
                  'Glad you are loving it! A 5-star review on Google Play means the world to our small team.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Review on Google Play'),
                    onPressed: _handleAction,
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _feedbackController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'What can we improve?',
                    hintText: 'Tell us how we can make CalorieFit better for you...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _handleAction,
                    child: const Text('Submit Feedback'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ReviewPromptDialog.markDismissed();
                  Navigator.of(context).pop();
                },
                child: Text('Maybe Later', style: TextStyle(color: theme.hintColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
