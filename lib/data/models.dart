// lib/data/models.dart

class Food {
  final int? id;
  final String name;

  // Nutrition values are stored per baseAmount of unit
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  final double fiber;
  final double sugar;
  final double sodium;
  final double cholesterol;
  final double saturatedFat;
  final double transFat;

  final String unit;       // g, ml, tbsp, tsp, cup, liter, piece, slice
  final double baseAmount; // 100 for g/ml, 1 for others

  final bool isSystem;
  final String? category;
  final bool isFavorite;

  const Food({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.saturatedFat = 0,
    this.transFat = 0,
    this.unit = 'g',
    this.baseAmount = 100,
    this.isSystem = false,
    this.category,
    this.isFavorite = false,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'saturated_fat': saturatedFat,
      'trans_fat': transFat,
      'unit': unit,
      'base_amount': baseAmount,
      'is_system': isSystem ? 1 : 0,
      'category': category,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  static Food fromMap(Map<String, Object?> m) {
    return Food(
      id: (m['id'] as num?)?.toInt(),
      name: (m['name'] as String?) ?? '',
      calories: ((m['calories'] as num?) ?? 0).toDouble(),
      protein: ((m['protein'] as num?) ?? 0).toDouble(),
      carbs: ((m['carbs'] as num?) ?? 0).toDouble(),
      fat: ((m['fat'] as num?) ?? 0).toDouble(),
      fiber: ((m['fiber'] as num?) ?? 0).toDouble(),
      sugar: ((m['sugar'] as num?) ?? 0).toDouble(),
      sodium: ((m['sodium'] as num?) ?? 0).toDouble(),
      cholesterol: ((m['cholesterol'] as num?) ?? 0).toDouble(),
      saturatedFat: ((m['saturated_fat'] as num?) ?? 0).toDouble(),
      transFat: ((m['trans_fat'] as num?) ?? 0).toDouble(),
      unit: (m['unit'] as String?) ?? 'g',
      baseAmount: ((m['base_amount'] as num?) ?? 100).toDouble(),
      isSystem: ((m['is_system'] as num?) ?? 0).toInt() == 1,
      category: m['category'] as String?,
      isFavorite: ((m['is_favorite'] as num?) ?? 0).toInt() == 1,
    );
  }
}

class LogEntry {
  final int? id;
  final String date;

  // For food entries:
  final int? foodId;

  // Amount in chosen unit (for manual we still keep grams=1 just as placeholder)
  final double grams;

  // Snapshot of unit/baseAmount used at log time (important for history)
  final String unit;
  final double baseAmount;

  final String? time;  // "HH:mm"
  final String? label; // Breakfast/Lunch/...

  // Snapshot nutrition (per baseAmount) for food entries
  final String? foodName;
  final double? calories100;
  final double? protein100;
  final double? carbs100;
  final double? fat100;
  final double? fiber100;
  final double? sugar100;
  final double? sodium100;
  final double? cholesterol100;
  final double? saturatedFat100;
  final double? transFat100;

  // Manual one-time entry support
  final String entryType; // 'food' or 'manual'
  final String? manualName;
  final double? manualKcal;
  final double? manualProtein;
  final double? manualCarbs;
  final double? manualFat;
  final double? manualFiber;
  final double? manualSugar;
  final double? manualSodium;
  final double? manualCholesterol;
  final double? manualSaturatedFat;
  final double? manualTransFat;
  final String? notes;

  const LogEntry({
    this.id,
    required this.date,
    required this.foodId,
    required this.grams,
    this.unit = 'g',
    this.baseAmount = 100,
    this.time,
    this.label,

    this.foodName,
    this.calories100,
    this.protein100,
    this.carbs100,
    this.fat100,
    this.fiber100,
    this.sugar100,
    this.sodium100,
    this.cholesterol100,
    this.saturatedFat100,
    this.transFat100,

    this.entryType = 'food',
    this.manualName,
    this.manualKcal,
    this.manualProtein,
    this.manualCarbs,
    this.manualFat,
    this.manualFiber,
    this.manualSugar,
    this.manualSodium,
    this.manualCholesterol,
    this.manualSaturatedFat,
    this.manualTransFat,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'food_id': foodId,
      'grams': grams,
      'unit': unit,
      'base_amount': baseAmount,
      'time': time,
      'label': label,

      'food_name': foodName,
      'calories_100': calories100,
      'protein_100': protein100,
      'carbs_100': carbs100,
      'fat_100': fat100,
      'fiber_100': fiber100,
      'sugar_100': sugar100,
      'sodium_100': sodium100,
      'cholesterol_100': cholesterol100,
      'saturated_fat_100': saturatedFat100,
      'trans_fat_100': transFat100,

      'entry_type': entryType,
      'manual_name': manualName,
      'manual_kcal': manualKcal,
      'manual_protein': manualProtein,
      'manual_carbs': manualCarbs,
      'manual_fat': manualFat,
      'manual_fiber': manualFiber,
      'manual_sugar': manualSugar,
      'manual_sodium': manualSodium,
      'manual_cholesterol': manualCholesterol,
      'manual_saturated_fat': manualSaturatedFat,
      'manual_trans_fat': manualTransFat,
      'notes': notes,
    };
  }

  static LogEntry fromMap(Map<String, Object?> m) {
    return LogEntry(
      id: (m['id'] as num?)?.toInt(),
      date: (m['date'] as String?) ?? '',
      foodId: (m['food_id'] as num?)?.toInt(),
      grams: ((m['grams'] as num?) ?? 0).toDouble(),
      unit: (m['unit'] as String?) ?? 'g',
      baseAmount: ((m['base_amount'] as num?) ?? 100).toDouble(),
      time: m['time'] as String?,
      label: m['label'] as String?,

      foodName: m['food_name'] as String?,
      calories100: (m['calories_100'] as num?)?.toDouble(),
      protein100: (m['protein_100'] as num?)?.toDouble(),
      carbs100: (m['carbs_100'] as num?)?.toDouble(),
      fat100: (m['fat_100'] as num?)?.toDouble(),
      fiber100: (m['fiber_100'] as num?)?.toDouble(),
      sugar100: (m['sugar_100'] as num?)?.toDouble(),
      sodium100: (m['sodium_100'] as num?)?.toDouble(),
      cholesterol100: (m['cholesterol_100'] as num?)?.toDouble(),
      saturatedFat100: (m['saturated_fat_100'] as num?)?.toDouble(),
      transFat100: (m['trans_fat_100'] as num?)?.toDouble(),

      entryType: (m['entry_type'] as String?) ?? 'food',
      manualName: m['manual_name'] as String?,
      manualKcal: (m['manual_kcal'] as num?)?.toDouble(),
      manualProtein: (m['manual_protein'] as num?)?.toDouble(),
      manualCarbs: (m['manual_carbs'] as num?)?.toDouble(),
      manualFat: (m['manual_fat'] as num?)?.toDouble(),
      manualFiber: (m['manual_fiber'] as num?)?.toDouble(),
      manualSugar: (m['manual_sugar'] as num?)?.toDouble(),
      manualSodium: (m['manual_sodium'] as num?)?.toDouble(),
      manualCholesterol: (m['manual_cholesterol'] as num?)?.toDouble(),
      manualSaturatedFat:
          (m['manual_saturated_fat'] as num?)?.toDouble(),
      manualTransFat: (m['manual_trans_fat'] as num?)?.toDouble(),
      notes: m['notes'] as String?,
    );
  }
}

class MealTemplate {
  final int? id;
  final String name;
  final String label;
  final String createdAt;

  final bool isSystem;
  final String? systemKey;

  const MealTemplate({
    this.id,
    required this.name,
    required this.label,
    required this.createdAt,
    this.isSystem = false,
    this.systemKey,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'label': label,
      'created_at': createdAt,
      'is_system': isSystem ? 1 : 0,
      'system_key': systemKey,
    };
  }

  static MealTemplate fromMap(Map<String, Object?> m) {
    return MealTemplate(
      id: (m['id'] as num?)?.toInt(),
      name: (m['name'] as String?) ?? '',
      label: (m['label'] as String?) ?? '',
      createdAt: (m['created_at'] as String?) ?? '',
      isSystem: ((m['is_system'] as num?) ?? 0).toInt() == 1,
      systemKey: m['system_key'] as String?,
    );
  }
}

class MealTemplateItem {
  final int? id;
  final int templateId;
  final int foodId;
  final double amount;
  final String unit;
  final double baseAmount;
  final int sortOrder;

  const MealTemplateItem({
    this.id,
    required this.templateId,
    required this.foodId,
    required this.amount,
    required this.unit,
    required this.baseAmount,
    required this.sortOrder,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'template_id': templateId,
      'food_id': foodId,
      'amount': amount,
      'unit': unit,
      'base_amount': baseAmount,
      'sort_order': sortOrder,
    };
  }

  static MealTemplateItem fromMap(Map<String, Object?> m) {
    return MealTemplateItem(
      id: (m['id'] as num?)?.toInt(),
      templateId: (m['template_id'] as num).toInt(),
      foodId: (m['food_id'] as num).toInt(),
      amount: ((m['amount'] as num?) ?? 0).toDouble(),
      unit: (m['unit'] as String?) ?? 'g',
      baseAmount: ((m['base_amount'] as num?) ?? 100).toDouble(),
      sortOrder: ((m['sort_order'] as num?) ?? 0).toInt(),
    );
  }
}

class FoodServing {
  final int? id;
  final int foodId;
  final String name;   // e.g. "1 tbsp", "1 egg", "½ cup"
  final double grams;  // equivalent amount in food's base unit

  const FoodServing({
    this.id,
    required this.foodId,
    required this.name,
    required this.grams,
  });

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'food_id': foodId,
    'name': name,
    'grams': grams,
  };

  static FoodServing fromMap(Map<String, Object?> m) => FoodServing(
    id: (m['id'] as num?)?.toInt(),
    foodId: (m['food_id'] as num).toInt(),
    name: m['name'] as String,
    grams: ((m['grams'] as num?) ?? 0).toDouble(),
  );
}

class DayTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double cholesterol;
  final double saturatedFat;
  final double transFat;

  const DayTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.saturatedFat = 0,
    this.transFat = 0,
  });

  DayTotals addScaledFood(Food f, double amount) {
    final base = f.baseAmount <= 0 ? 1.0 : f.baseAmount;
    final factor = amount / base;

    return DayTotals(
      calories: calories + (f.calories * factor),
      protein: protein + (f.protein * factor),
      carbs: carbs + (f.carbs * factor),
      fat: fat + (f.fat * factor),
      fiber: fiber + (f.fiber * factor),
      sugar: sugar + (f.sugar * factor),
      sodium: sodium + (f.sodium * factor),
      cholesterol: cholesterol + (f.cholesterol * factor),
      saturatedFat: saturatedFat + (f.saturatedFat * factor),
      transFat: transFat + (f.transFat * factor),
    );
  }

  DayTotals addManual({
    required double caloriesAdd,
    required double proteinAdd,
    required double carbsAdd,
    required double fatAdd,
    double fiberAdd = 0,
    double sugarAdd = 0,
    double sodiumAdd = 0,
    double cholesterolAdd = 0,
    double saturatedFatAdd = 0,
    double transFatAdd = 0,
  }) {
    return DayTotals(
      calories: calories + caloriesAdd,
      protein: protein + proteinAdd,
      carbs: carbs + carbsAdd,
      fat: fat + fatAdd,
      fiber: fiber + fiberAdd,
      sugar: sugar + sugarAdd,
      sodium: sodium + sodiumAdd,
      cholesterol: cholesterol + cholesterolAdd,
      saturatedFat: saturatedFat + saturatedFatAdd,
      transFat: transFat + transFatAdd,
    );
  }
}

class WeightLog {
  final int? id;
  final String date;
  final double weight;
  final String unit; // 'kg' or 'lbs'
  final String? notes;
  final String createdAt;

  const WeightLog({
    this.id,
    required this.date,
    required this.weight,
    this.unit = 'kg',
    this.notes,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'weight': weight,
      'unit': unit,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  static WeightLog fromMap(Map<String, Object?> m) {
    return WeightLog(
      id: (m['id'] as num?)?.toInt(),
      date: (m['date'] as String?) ?? '',
      weight: ((m['weight'] as num?) ?? 0).toDouble(),
      unit: (m['unit'] as String?) ?? 'kg',
      notes: m['notes'] as String?,
      createdAt: (m['created_at'] as String?) ?? '',
    );
  }
}

class WaterLog {
  final String date;
  final int amountMl;
  final int targetMl;

  const WaterLog({
    required this.date,
    required this.amountMl,
    this.targetMl = 2000,
  });

  Map<String, Object?> toMap() {
    return {
      'date': date,
      'amount_ml': amountMl,
      'target_ml': targetMl,
    };
  }

  static WaterLog fromMap(Map<String, Object?> m) {
    return WaterLog(
      date: (m['date'] as String?) ?? '',
      amountMl: ((m['amount_ml'] as num?) ?? 0).toInt(),
      targetMl: ((m['target_ml'] as num?) ?? 2000).toInt(),
    );
  }
}

class FastingSession {
  final int? id;
  final String protocol; // '16:8', '14:10', '18:6', '20:4', 'custom'
  final double targetHours;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final String? notes;

  const FastingSession({
    this.id,
    required this.protocol,
    required this.targetHours,
    required this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.notes,
  });

  bool get isActive => endTime == null && !isCompleted;

  Duration get elapsed {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get progressPercent {
    final totalMinutes = targetHours * 60;
    if (totalMinutes <= 0) return 0.0;
    return (elapsed.inMinutes / totalMinutes).clamp(0.0, 1.0);
  }

  Duration get remaining {
    final targetDuration = Duration(minutes: (targetHours * 60).round());
    final rem = targetDuration - elapsed;
    return rem.isNegative ? Duration.zero : rem;
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'protocol': protocol,
      'target_hours': targetHours,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  static FastingSession fromMap(Map<String, Object?> m) {
    return FastingSession(
      id: m['id'] as int?,
      protocol: (m['protocol'] as String?) ?? '16:8',
      targetHours: ((m['target_hours'] as num?) ?? 16.0).toDouble(),
      startTime: DateTime.tryParse((m['start_time'] as String?) ?? '') ?? DateTime.now(),
      endTime: m['end_time'] != null ? DateTime.tryParse(m['end_time'] as String) : null,
      isCompleted: (m['is_completed'] as int? ?? 0) == 1,
      notes: m['notes'] as String?,
    );
  }
}

class ExerciseLog {
  final int? id;
  final String date;
  final String activityName;
  final int durationMinutes;
  final double caloriesBurned;
  final int steps;
  final String? notes;

  const ExerciseLog({
    this.id,
    required this.date,
    required this.activityName,
    required this.durationMinutes,
    required this.caloriesBurned,
    this.steps = 0,
    this.notes,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'activity_name': activityName,
      'duration_minutes': durationMinutes,
      'calories_burned': caloriesBurned,
      'steps': steps,
      'notes': notes,
    };
  }

  static ExerciseLog fromMap(Map<String, Object?> m) {
    return ExerciseLog(
      id: m['id'] as int?,
      date: (m['date'] as String?) ?? '',
      activityName: (m['activity_name'] as String?) ?? 'Workout',
      durationMinutes: ((m['duration_minutes'] as num?) ?? 0).toInt(),
      caloriesBurned: ((m['calories_burned'] as num?) ?? 0.0).toDouble(),
      steps: ((m['steps'] as num?) ?? 0).toInt(),
      notes: m['notes'] as String?,
    );
  }
}
