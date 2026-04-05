// lib/settings/target_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

class TargetSettings {
  static const _kCalories = 'targets_calories';
  static const _kProtein = 'targets_protein';
  static const _kCarbs = 'targets_carbs';
  static const _kFat = 'targets_fat';
  static const _kFiber = 'targets_fiber';
  static const _kSugar = 'targets_sugar';
  static const _kSodium = 'targets_sodium';

  static Future<int> getCalories() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCalories) ?? 2000;
  }

  static Future<int> getProtein() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kProtein) ?? 150;
  }

  static Future<int> getCarbs() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCarbs) ?? 200;
  }

  static Future<int> getFat() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kFat) ?? 70;
  }

  static Future<int> getFiber() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kFiber) ?? 30;
  }

  static Future<int> getSugar() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kSugar) ?? 50;
  }

  static Future<int> getSodium() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kSodium) ?? 2300;
  }

  static Future<void> setCalories(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCalories, v);
  }

  static Future<void> setProtein(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kProtein, v);
  }

  static Future<void> setCarbs(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kCarbs, v);
  }

  static Future<void> setFat(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kFat, v);
  }

  static Future<void> setFiber(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kFiber, v);
  }

  static Future<void> setSugar(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSugar, v);
  }

  static Future<void> setSodium(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kSodium, v);
  }

  static Future<void> resetAllTargets() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kCalories);
    await sp.remove(_kProtein);
    await sp.remove(_kCarbs);
    await sp.remove(_kFat);
    await sp.remove(_kFiber);
    await sp.remove(_kSugar);
    await sp.remove(_kSodium);
  }
}