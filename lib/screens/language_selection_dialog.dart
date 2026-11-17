import 'package:flutter/material.dart';
import '../services/app_localization.dart';

class LanguageSelectionDialog extends StatelessWidget {
  const LanguageSelectionDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const LanguageSelectionDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = AppLocalization.current;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.language, color: Colors.teal),
          SizedBox(width: 8),
          Text('Select Language'),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppLanguage.values.length,
          itemBuilder: (ctx, i) {
            final lang = AppLanguage.values[i];
            final isSelected = lang == current;
            return ListTile(
              leading: Text(
                _getFlagEmoji(lang.code),
                style: const TextStyle(fontSize: 22),
              ),
              title: Text(
                lang.nativeName,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(lang.englishName),
              trailing: isSelected ? const Icon(Icons.check, color: Colors.teal) : null,
              onTap: () async {
                await AppLocalization.setLanguage(lang);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getFlagEmoji(String code) {
    switch (code) {
      case 'es':
        return '🇪🇸';
      case 'fr':
        return '🇫🇷';
      case 'de':
        return '🇩🇪';
      case 'ur':
        return '🇵🇰';
      case 'ar':
        return '🇸🇦';
      case 'hi':
        return '🇮🇳';
      case 'en':
      default:
        return '🇺🇸';
    }
  }
}
