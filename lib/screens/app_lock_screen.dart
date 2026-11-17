import 'package:flutter/material.dart';
import '../services/privacy_lock_service.dart';

class AppLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _isError = false;

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
        _isError = false;
      });

      if (_pin.length == 4) {
        _verify();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verify() async {
    final valid = await PrivacyLockService.instance.verifyPin(_pin);
    if (valid) {
      widget.onUnlocked();
    } else {
      setState(() {
        _isError = true;
        _pin = '';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect PIN. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_outline, size: 36, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'CalorieFit Privacy Lock',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your 4-digit PIN to access your health diary',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isError
                        ? Colors.red
                        : filled
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                    border: Border.all(
                      color: _isError ? Colors.red : theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),

            // Numpad
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['1', '2', '3'].map(_buildNumpadButton).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['4', '5', '6'].map(_buildNumpadButton).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['7', '8', '9'].map(_buildNumpadButton).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 72, height: 72),
                      _buildNumpadButton('0'),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _onBackspace,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String digit) {
    return InkWell(
      borderRadius: BorderRadius.circular(36),
      onTap: () => _onKeyPress(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class PrivacyLockSettingsDialog extends StatefulWidget {
  const PrivacyLockSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const PrivacyLockSettingsDialog(),
    );
  }

  @override
  State<PrivacyLockSettingsDialog> createState() => _PrivacyLockSettingsDialogState();
}

class _PrivacyLockSettingsDialogState extends State<PrivacyLockSettingsDialog> {
  bool _enabled = false;
  final TextEditingController _pinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    final en = await PrivacyLockService.instance.isLockEnabled();
    setState(() => _enabled = en);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.security, color: Colors.indigo),
          SizedBox(width: 8),
          Text('Privacy PIN Lock'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Require PIN on Launch'),
            subtitle: const Text('Keep your diet logs and photos private on your device.'),
            value: _enabled,
            onChanged: (val) async {
              if (val) {
                // Prompt for 4-digit PIN
                setState(() => _enabled = true);
              } else {
                await PrivacyLockService.instance.removePin();
                setState(() => _enabled = false);
              }
            },
          ),
          if (_enabled) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Set 4-Digit PIN',
                hintText: 'e.g. 1234',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        if (_enabled)
          FilledButton(
            onPressed: () async {
              final pin = _pinCtrl.text.trim();
              if (pin.length == 4) {
                await PrivacyLockService.instance.savePin(pin);
                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy PIN successfully saved and enabled!')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be exactly 4 digits.')),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
      ],
    );
  }
}
