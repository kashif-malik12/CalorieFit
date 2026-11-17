import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  static const _kThemeMode = 'app_theme_mode';
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final modeStr = sp.getString(_kThemeMode) ?? 'system';
    switch (modeStr) {
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    final sp = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.dark) val = 'dark';
    if (mode == ThemeMode.light) val = 'light';
    await sp.setString(_kThemeMode, val);
  }

  static Future<void> toggleTheme(BuildContext context) async {
    final isDark = themeModeNotifier.value == ThemeMode.dark ||
        (themeModeNotifier.value == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }
}
