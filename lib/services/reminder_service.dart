import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  final bool enabled;
  final TimeOfDay breakfastTime;
  final bool breakfastEnabled;
  final TimeOfDay lunchTime;
  final bool lunchEnabled;
  final TimeOfDay dinnerTime;
  final bool dinnerEnabled;
  final bool waterEnabled;
  final int waterIntervalHours;

  const ReminderSettings({
    this.enabled = true,
    this.breakfastTime = const TimeOfDay(hour: 8, minute: 30),
    this.breakfastEnabled = true,
    this.lunchTime = const TimeOfDay(hour: 13, minute: 0),
    this.lunchEnabled = true,
    this.dinnerTime = const TimeOfDay(hour: 19, minute: 30),
    this.dinnerEnabled = true,
    this.waterEnabled = true,
    this.waterIntervalHours = 2,
  });

  ReminderSettings copyWith({
    bool? enabled,
    TimeOfDay? breakfastTime,
    bool? breakfastEnabled,
    TimeOfDay? lunchTime,
    bool? lunchEnabled,
    TimeOfDay? dinnerTime,
    bool? dinnerEnabled,
    bool? waterEnabled,
    int? waterIntervalHours,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      breakfastEnabled: breakfastEnabled ?? this.breakfastEnabled,
      lunchTime: lunchTime ?? this.lunchTime,
      lunchEnabled: lunchEnabled ?? this.lunchEnabled,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      dinnerEnabled: dinnerEnabled ?? this.dinnerEnabled,
      waterEnabled: waterEnabled ?? this.waterEnabled,
      waterIntervalHours: waterIntervalHours ?? this.waterIntervalHours,
    );
  }
}

class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _kEnabled = 'reminders_enabled';
  static const _kBreakfastHour = 'reminder_breakfast_hour';
  static const _kBreakfastMinute = 'reminder_breakfast_minute';
  static const _kBreakfastEnabled = 'reminder_breakfast_enabled';

  static const _kLunchHour = 'reminder_lunch_hour';
  static const _kLunchMinute = 'reminder_lunch_minute';
  static const _kLunchEnabled = 'reminder_lunch_enabled';

  static const _kDinnerHour = 'reminder_dinner_hour';
  static const _kDinnerMinute = 'reminder_dinner_minute';
  static const _kDinnerEnabled = 'reminder_dinner_enabled';

  static const _kWaterEnabled = 'reminder_water_enabled';
  static const _kWaterInterval = 'reminder_water_interval';

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? true,
      breakfastTime: TimeOfDay(
        hour: prefs.getInt(_kBreakfastHour) ?? 8,
        minute: prefs.getInt(_kBreakfastMinute) ?? 30,
      ),
      breakfastEnabled: prefs.getBool(_kBreakfastEnabled) ?? true,
      lunchTime: TimeOfDay(
        hour: prefs.getInt(_kLunchHour) ?? 13,
        minute: prefs.getInt(_kLunchMinute) ?? 0,
      ),
      lunchEnabled: prefs.getBool(_kLunchEnabled) ?? true,
      dinnerTime: TimeOfDay(
        hour: prefs.getInt(_kDinnerHour) ?? 19,
        minute: prefs.getInt(_kDinnerMinute) ?? 30,
      ),
      dinnerEnabled: prefs.getBool(_kDinnerEnabled) ?? true,
      waterEnabled: prefs.getBool(_kWaterEnabled) ?? true,
      waterIntervalHours: prefs.getInt(_kWaterInterval) ?? 2,
    );
  }

  Future<void> saveSettings(ReminderSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, s.enabled);
    await prefs.setInt(_kBreakfastHour, s.breakfastTime.hour);
    await prefs.setInt(_kBreakfastMinute, s.breakfastTime.minute);
    await prefs.setBool(_kBreakfastEnabled, s.breakfastEnabled);

    await prefs.setInt(_kLunchHour, s.lunchTime.hour);
    await prefs.setInt(_kLunchMinute, s.lunchTime.minute);
    await prefs.setBool(_kLunchEnabled, s.lunchEnabled);

    await prefs.setInt(_kDinnerHour, s.dinnerTime.hour);
    await prefs.setInt(_kDinnerMinute, s.dinnerTime.minute);
    await prefs.setBool(_kDinnerEnabled, s.dinnerEnabled);

    await prefs.setBool(_kWaterEnabled, s.waterEnabled);
    await prefs.setInt(_kWaterInterval, s.waterIntervalHours);
  }

  /// Calculates the next upcoming reminder based on current time
  String? getNextReminderNotice(ReminderSettings s, {DateTime? nowOverride}) {
    if (!s.enabled) return null;
    final now = nowOverride ?? DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    final schedule = <MapEntry<String, int>>[];
    if (s.breakfastEnabled) {
      schedule.add(MapEntry('Breakfast Log (Morning)', s.breakfastTime.hour * 60 + s.breakfastTime.minute));
    }
    if (s.lunchEnabled) {
      schedule.add(MapEntry('Lunch Log (Midday)', s.lunchTime.hour * 60 + s.lunchTime.minute));
    }
    if (s.dinnerEnabled) {
      schedule.add(MapEntry('Dinner Log (Evening)', s.dinnerTime.hour * 60 + s.dinnerTime.minute));
    }

    if (s.waterEnabled && s.waterIntervalHours > 0) {
      for (int h = 9; h <= 21; h += s.waterIntervalHours) {
        schedule.add(MapEntry('Hydration Check (Drink Water 💧)', h * 60));
      }
    }

    schedule.sort((a, b) => a.value.compareTo(b.value));

    for (final item in schedule) {
      if (item.value >= currentMinutes) {
        final hr = (item.value ~/ 60).toString().padLeft(2, '0');
        final mn = (item.value % 60).toString().padLeft(2, '0');
        return 'Upcoming reminder: ${item.key} at $hr:$mn';
      }
    }

    if (schedule.isNotEmpty) {
      final first = schedule.first;
      final hr = (first.value ~/ 60).toString().padLeft(2, '0');
      final mn = (first.value % 60).toString().padLeft(2, '0');
      return 'Next reminder tomorrow: ${first.key} at $hr:$mn';
    }

    return null;
  }
}
