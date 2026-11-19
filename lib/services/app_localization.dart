import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  en('en', 'English', 'English', false),
  es('es', 'Español', 'Spanish', false),
  fr('fr', 'Français', 'French', false),
  de('de', 'Deutsch', 'German', false),
  ur('ur', 'اردو', 'Urdu', true),
  ar('ar', 'العربية', 'Arabic', true),
  hi('hi', 'हिन्दी', 'Hindi', false);

  final String code;
  final String nativeName;
  final String englishName;
  final bool isRtl;

  const AppLanguage(this.code, this.nativeName, this.englishName, this.isRtl);

  static AppLanguage fromCode(String code) {
    for (final l in AppLanguage.values) {
      if (l.code.toLowerCase() == code.toLowerCase()) return l;
    }
    return AppLanguage.en;
  }
}

class AppLocalization {
  static const String _prefKeyLanguage = 'app_language_code';

  static AppLanguage _current = AppLanguage.en;
  static final ValueNotifier<AppLanguage> currentLanguageNotifier = ValueNotifier<AppLanguage>(AppLanguage.en);

  static AppLanguage get current => _current;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKeyLanguage) ?? 'en';
    _current = AppLanguage.fromCode(code);
    currentLanguageNotifier.value = _current;
  }

  static Future<void> setLanguage(AppLanguage language) async {
    _current = language;
    currentLanguageNotifier.value = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLanguage, language.code);
  }

  static TextDirection get textDirection => _current.isRtl ? TextDirection.rtl : TextDirection.ltr;

  static final Map<String, Map<String, String>> _strings = {
    'en': {
      'app_title': 'CalorieFit',
      'daily_diary': 'Daily Diary',
      'fasting_tracker': 'Fasting Tracker',
      'exercise_logger': 'Exercise Logger',
      'recipe_builder': 'Recipe & Meal Builder',
      'ai_meal_estimator': 'AI Meal Estimator',
      'camera_food_scanner': 'Camera Food Scanner',
      'visual_journal': 'Photo Meal Journal',
      'health_connect': 'Google Health Connect',
      'home_widgets': 'Home Screen Widgets',
      'calories': 'Calories',
      'protein': 'Protein',
      'carbs': 'Carbs',
      'fat': 'Fat',
      'fiber': 'Fiber',
      'sodium': 'Sodium',
      'water': 'Water',
      'net_calories': 'Net Calories',
      'remaining': 'Remaining',
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snack',
      'add_food': 'Add Food',
      'scan_barcode': 'Scan Barcode',
      'search_food': 'Search Food or Brand',
      'sync_now': 'Sync Now',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
    },
    'es': {
      'app_title': 'CalorieFit',
      'daily_diary': 'Diario Diario',
      'fasting_tracker': 'Control de Ayuno',
      'exercise_logger': 'Registro de Ejercicio',
      'recipe_builder': 'Creador de Recetas',
      'ai_meal_estimator': 'Estimador de Comida IA',
      'camera_food_scanner': 'Escanear Comida con Cámara',
      'visual_journal': 'Diario Visual con Fotos',
      'health_connect': 'Google Health Connect',
      'home_widgets': 'Widgets de Pantalla de Inicio',
      'calories': 'Calorías',
      'protein': 'Proteína',
      'carbs': 'Carbohidratos',
      'fat': 'Grasa',
      'fiber': 'Fibra',
      'sodium': 'Sodio',
      'water': 'Agua',
      'net_calories': 'Calorías Netas',
      'remaining': 'Restantes',
      'breakfast': 'Desayuno',
      'lunch': 'Almuerzo',
      'dinner': 'Cena',
      'snack': 'Merienda',
      'add_food': 'Añadir Alimento',
      'scan_barcode': 'Escanear Código',
      'search_food': 'Buscar comida o marca',
      'sync_now': 'Sincronizar Ahora',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
    },
    'fr': {
      'app_title': 'CalorieFit',
      'daily_diary': 'Journal Quotidien',
      'fasting_tracker': 'Suivi du Jeûne',
      'exercise_logger': 'Journal des Exercices',
      'recipe_builder': 'Créateur de Recettes',
      'ai_meal_estimator': 'Estimateur IA de Repas',
      'camera_food_scanner': 'Scanner Repas avec Appareil Photo',
      'visual_journal': 'Journal Photo de Repas',
      'health_connect': 'Google Health Connect',
      'home_widgets': 'Widgets Écran d’accueil',
      'calories': 'Calories',
      'protein': 'Protéines',
      'carbs': 'Glucides',
      'fat': 'Lipides',
      'fiber': 'Fibres',
      'sodium': 'Sodium',
      'water': 'Eau',
      'net_calories': 'Calories Nettes',
      'remaining': 'Restantes',
      'breakfast': 'Petit déjeuner',
      'lunch': 'Déjeuner',
      'dinner': 'Dîner',
      'snack': 'Collation',
      'add_food': 'Ajouter un aliment',
      'scan_barcode': 'Scanner le code-barres',
      'search_food': 'Rechercher un aliment ou marque',
      'sync_now': 'Synchroniser',
      'save': 'Enregistrer',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
    },
    'de': {
      'app_title': 'CalorieFit',
      'daily_diary': 'Tagebuch',
      'fasting_tracker': 'Fasten-Tracker',
      'exercise_logger': 'Trainings-Tagebuch',
      'recipe_builder': 'Rezept-Builder',
      'ai_meal_estimator': 'KI-Mahlzeit-Schätzer',
      'camera_food_scanner': 'Kamera-Mahlzeit-Scanner',
      'visual_journal': 'Foto-Mahlzeitentagebuch',
      'health_connect': 'Google Health Connect',
      'home_widgets': 'Startbildschirm-Widgets',
      'calories': 'Kalorien',
      'protein': 'Eiweiß',
      'carbs': 'Kohlenhydrate',
      'fat': 'Fett',
      'fiber': 'Ballaststoffe',
      'sodium': 'Natrium',
      'water': 'Wasser',
      'net_calories': 'Netto-Kalorien',
      'remaining': 'Verbleibend',
      'breakfast': 'Frühstück',
      'lunch': 'Mittagessen',
      'dinner': 'Abendessen',
      'snack': 'Snack',
      'add_food': 'Lebensmittel hinzufügen',
      'scan_barcode': 'Barcode scannen',
      'search_food': 'Lebensmittel oder Marke suchen',
      'sync_now': 'Jetzt synchronisieren',
      'save': 'Speichern',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
    },
    'ur': {
      'app_title': 'کیلوری فٹ',
      'daily_diary': 'روزانہ ڈائری',
      'fasting_tracker': 'روزہ / فسٹنگ ٹریکر',
      'exercise_logger': 'ورزش اور ایکٹیویٹی لاگ',
      'recipe_builder': 'کھانے اور ترکیب بلڈر',
      'ai_meal_estimator': 'اے آئی نیوٹریشن تخمینہ',
      'camera_food_scanner': 'کیمرہ کھانا سکینر',
      'visual_journal': 'تصویری میل جرنل',
      'health_connect': 'گوگل ہیلتھ کنیکٹ',
      'home_widgets': 'ہوم اسکرین ویجٹس',
      'calories': 'کیلوریز',
      'protein': 'پروٹین',
      'carbs': 'کاربوہائیڈریٹ',
      'fat': 'چکنائی',
      'fiber': 'فائبر',
      'sodium': 'سوڈیم',
      'water': 'پانی',
      'net_calories': 'خالص کیلوریز',
      'remaining': 'باقی',
      'breakfast': 'ناشتہ',
      'lunch': 'دوپہر کا کھانا',
      'dinner': 'رات کا کھانا',
      'snack': 'اسنیکس',
      'add_food': 'کھانا شامل کریں',
      'scan_barcode': 'بارکوڈ اسکین کریں',
      'search_food': 'کھانا یا برانڈ تلاش کریں',
      'sync_now': 'ابھی ہم آہنگ کریں',
      'save': 'محفوظ کریں',
      'cancel': 'منسوخ',
      'delete': 'حذف کریں',
    },
    'ar': {
      'app_title': 'كالوري فيت',
      'daily_diary': 'اليوميات',
      'fasting_tracker': 'متتبع الصيام',
      'exercise_logger': 'سجل التمارين الرياضية',
      'recipe_builder': 'منشئ الوصفات والوجبات',
      'ai_meal_estimator': 'تقدير الوجبات بالذكاء الاصطناعي',
      'camera_food_scanner': 'ماسح الطعام بالكاميرا',
      'visual_journal': 'سجل الوجبات المصور',
      'health_connect': 'جوجل هيلث كونكت',
      'home_widgets': 'عناصر الشاشة الرئيسية',
      'calories': 'السعرات الحرارية',
      'protein': 'البروتين',
      'carbs': 'الكربوهيدرات',
      'fat': 'الدهون',
      'fiber': 'الألياف',
      'sodium': 'الصوديوم',
      'water': 'الماء',
      'net_calories': 'صافي السعرات',
      'remaining': 'المتبقي',
      'breakfast': 'الإفطار',
      'lunch': 'الغداء',
      'dinner': 'العشاء',
      'snack': 'وجبة خفيفة',
      'add_food': 'إضافة طعام',
      'scan_barcode': 'مسح الباركود',
      'search_food': 'ابحث عن طعام أو ماركة',
      'sync_now': 'مزامنة الآن',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'delete': 'حذف',
    },
    'hi': {
      'app_title': 'कैलोरी फिट',
      'daily_diary': 'दैनिक डायरी',
      'fasting_tracker': 'फास्टिंग ट्रैकर',
      'exercise_logger': 'व्यायाम लॉगर',
      'recipe_builder': 'रेसिपी व भोजन निर्माता',
      'ai_meal_estimator': 'एआई मील न्यूट्रिशन',
      'camera_food_scanner': 'कैमरा फ़ूड स्कैनर',
      'visual_journal': 'फोटो मील जर्नल',
      'health_connect': 'गूगल हेल्थ कनेक्ट',
      'home_widgets': 'होम स्क्रीन विजेट',
      'calories': 'कैलोरी',
      'protein': 'प्रोटीन',
      'carbs': 'कार्ब्स',
      'fat': 'वसा',
      'fiber': 'फाइबर',
      'sodium': 'सोडियम',
      'water': 'पानी',
      'net_calories': 'शुद्ध कैलोरी',
      'remaining': 'शेष',
      'breakfast': 'नाश्ता',
      'lunch': 'दोपहर का भोजन',
      'dinner': 'रात का खाना',
      'snack': 'नाश्ता / स्नैक',
      'add_food': 'भोजन जोड़ें',
      'scan_barcode': 'बारकोड स्कैन करें',
      'search_food': 'भोजन या ब्रांड खोजें',
      'sync_now': 'अभी सिंक करें',
      'save': 'सहेजें',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
    },
  };

  /// Returns translated string for key, falling back to English.
  static String tr(String key) {
    final langMap = _strings[_current.code] ?? _strings['en']!;
    return langMap[key] ?? _strings['en']?[key] ?? key;
  }
}

/// Extension method on String for convenient localization syntax: 'calories'.tr()
extension StringLocalizationExtension on String {
  String tr() => AppLocalization.tr(this);
}
