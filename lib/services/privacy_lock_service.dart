import 'package:shared_preferences/shared_preferences.dart';

class PrivacyLockService {
  static const String _prefKeyLockEnabled = 'privacy_lock_enabled';
  static const String _prefKeyLockPin = 'privacy_lock_pin';

  static final PrivacyLockService instance = PrivacyLockService();

  Future<bool> isLockEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyLockEnabled) ?? false;
  }

  Future<void> setLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyLockEnabled, enabled);
  }

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(_prefKeyLockPin);
    return pin != null && pin.length == 4;
  }

  Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_prefKeyLockPin);
    return storedPin == enteredPin;
  }

  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLockPin, pin);
    await prefs.setBool(_prefKeyLockEnabled, true);
  }

  Future<void> removePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyLockPin);
    await prefs.setBool(_prefKeyLockEnabled, false);
  }
}
