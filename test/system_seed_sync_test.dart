import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common/sqflite.dart' as common;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:calorie_fit/data/db.dart';
import 'package:calorie_fit/settings/target_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    common.databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppDb.instance.resetDb();
    await TargetSettings.resetAllTargets();
    await AppDb.instance.db;
  });

  tearDown(() async {
    await AppDb.instance.resetDb();
    await TargetSettings.resetAllTargets();
  });

  test('system food sync updates existing rows by stable system_key', () async {
    final db = await AppDb.instance.db;

    final before = await db.query(
      'foods',
      where: 'system_key = ? AND is_system = 1',
      whereArgs: ['black_coffee'],
      limit: 1,
    );

    expect(before, hasLength(1));

    final foodId = before.first['id'] as int;
    await db.update(
      'foods',
      {
        'name': 'Black Coffee Unsweetened',
        'calories': 1,
        'seed_version': 0,
        'is_active': 0,
      },
      where: 'id = ?',
      whereArgs: [foodId],
    );

    await AppDb.instance.ensureSystemSeeded(db);

    final after = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [foodId],
      limit: 1,
    );

    expect(after, hasLength(1));
    expect(after.first['name'], 'Black Coffee');
    expect((after.first['calories'] as num).toDouble(), 2);
    expect(after.first['seed_version'], 1);
    expect(after.first['is_active'], 1);
  });

  test('system food sync marks missing packaged rows inactive', () async {
    final db = await AppDb.instance.db;

    final insertedId = await db.insert('foods', {
      'name': 'Temporary Removed Food',
      'calories': 123,
      'protein': 1,
      'carbs': 2,
      'fat': 3,
      'fiber': 0,
      'sugar': 0,
      'sodium': 0,
      'unit': 'g',
      'base_amount': 100,
      'is_system': 1,
      'is_active': 1,
      'category': 'test',
      'system_key': 'temporary_removed_food',
      'seed_version': 1,
    });

    await AppDb.instance.ensureSystemSeeded(db);

    final row = await db.query(
      'foods',
      where: 'id = ?',
      whereArgs: [insertedId],
      limit: 1,
    );

    expect(row, hasLength(1));
    expect(row.first['is_active'], 0);

    final visibleFoods = await AppDb.instance.getSystemFoods();
    expect(
      visibleFoods.any((food) => food.name == 'Temporary Removed Food'),
      isFalse,
    );
  });

  test(
    'system template sync refreshes packaged template rows and items',
    () async {
      final db = await AppDb.instance.db;

      final templateRows = await db.query(
        'meal_templates',
        where: 'system_key = ? AND is_system = 1',
        whereArgs: ['breakfast_oats_protein'],
        limit: 1,
      );

      expect(templateRows, hasLength(1));
      final templateId = templateRows.first['id'] as int;

      await db.update(
        'meal_templates',
        {
          'name': 'Broken Template Name',
          'label': 'Broken Label',
          'seed_version': 0,
          'is_active': 0,
        },
        where: 'id = ?',
        whereArgs: [templateId],
      );

      await db.delete(
        'meal_template_items',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );

      await AppDb.instance.ensureSystemSeeded(db);

      final refreshedTemplate = await db.query(
        'meal_templates',
        where: 'id = ?',
        whereArgs: [templateId],
        limit: 1,
      );

      expect(refreshedTemplate, hasLength(1));
      expect(refreshedTemplate.first['name'], 'Protein Oats Bowl');
      expect(refreshedTemplate.first['label'], 'Breakfast');
      expect(refreshedTemplate.first['seed_version'], 1);
      expect(refreshedTemplate.first['is_active'], 1);

      final itemRows = await db.query(
        'meal_template_items',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );

      expect(itemRows, hasLength(4));
    },
  );
}
