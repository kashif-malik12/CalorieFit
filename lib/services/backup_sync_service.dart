import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../data/db.dart';

class CloudSyncConfig {
  final String endpointUrl;
  final String apiKey;
  final bool autoSyncEnabled;
  final String? lastSyncTime;

  const CloudSyncConfig({
    this.endpointUrl = '',
    this.apiKey = '',
    this.autoSyncEnabled = false,
    this.lastSyncTime,
  });
}

class BackupSyncService {
  BackupSyncService._();
  static final BackupSyncService instance = BackupSyncService._();

  static const _kEndpointUrl = 'cloud_sync_endpoint_url';
  static const _kApiKey = 'cloud_sync_api_key';
  static const _kAutoSync = 'cloud_sync_auto_enabled';
  static const _kLastSync = 'cloud_sync_last_time';

  Future<CloudSyncConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    return CloudSyncConfig(
      endpointUrl: prefs.getString(_kEndpointUrl) ?? '',
      apiKey: prefs.getString(_kApiKey) ?? '',
      autoSyncEnabled: prefs.getBool(_kAutoSync) ?? false,
      lastSyncTime: prefs.getString(_kLastSync),
    );
  }

  Future<void> saveConfig(CloudSyncConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kEndpointUrl, cfg.endpointUrl);
    await prefs.setString(_kApiKey, cfg.apiKey);
    await prefs.setBool(_kAutoSync, cfg.autoSyncEnabled);
    if (cfg.lastSyncTime != null) {
      await prefs.setString(_kLastSync, cfg.lastSyncTime!);
    }
  }

  /// Generates a comprehensive JSON backup string
  Future<String> createFullBackupJson() async {
    final db = await AppDb.instance.db;

    final logEntries = await db.query('log_entries');
    final waterLogs = await db.query('water_logs');
    final weightLogs = await db.query('weight_logs');
    final dayTargets = await db.query('day_targets');
    final templates = await db.query('templates');
    final templateItems = await db.query('template_items');
    final userFoods = await db.query('foods', where: 'is_system = 0');
    final questions = await db.query('questions');
    final answers = await db.query('answers');

    final backupData = {
      'app': 'CalorieFit',
      'version': '1.3.0',
      'created_at': DateTime.now().toIso8601String(),
      'tables': {
        'log_entries': logEntries,
        'water_logs': waterLogs,
        'weight_logs': weightLogs,
        'day_targets': dayTargets,
        'templates': templates,
        'template_items': templateItems,
        'user_foods': userFoods,
        'questions': questions,
        'answers': answers,
      },
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Restores records from a JSON backup payload
  Future<Map<String, int>> restoreFromJson(String jsonString) async {
    final data = json.decode(jsonString);
    if (data is! Map<String, dynamic> || !data.containsKey('tables')) {
      throw const FormatException('Invalid CalorieFit backup format');
    }

    final db = await AppDb.instance.db;
    final tables = data['tables'] as Map<String, dynamic>;
    final restoredCounts = <String, int>{};

    await db.transaction((txn) async {
      // 1. Water logs
      if (tables.containsKey('water_logs')) {
        final rows = List<Map<String, dynamic>>.from(tables['water_logs']);
        for (final row in rows) {
          await txn.insert('water_logs', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        restoredCounts['water_logs'] = rows.length;
      }

      // 2. Weight logs
      if (tables.containsKey('weight_logs')) {
        final rows = List<Map<String, dynamic>>.from(tables['weight_logs']);
        for (final row in rows) {
          final copy = Map<String, dynamic>.from(row)..remove('id');
          await txn.insert('weight_logs', copy, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        restoredCounts['weight_logs'] = rows.length;
      }

      // 3. Day targets
      if (tables.containsKey('day_targets')) {
        final rows = List<Map<String, dynamic>>.from(tables['day_targets']);
        for (final row in rows) {
          await txn.insert('day_targets', row, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        restoredCounts['day_targets'] = rows.length;
      }

      // 4. Custom foods
      if (tables.containsKey('user_foods')) {
        final rows = List<Map<String, dynamic>>.from(tables['user_foods']);
        for (final row in rows) {
          final copy = Map<String, dynamic>.from(row)..remove('id');
          await txn.insert('foods', copy, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        restoredCounts['user_foods'] = rows.length;
      }

      // 5. Food logs
      if (tables.containsKey('log_entries')) {
        final rows = List<Map<String, dynamic>>.from(tables['log_entries']);
        for (final row in rows) {
          final copy = Map<String, dynamic>.from(row)..remove('id');
          await txn.insert('log_entries', copy, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        restoredCounts['log_entries'] = rows.length;
      }
    });

    return restoredCounts;
  }

  /// Syncs current diary state with a remote cloud endpoint
  Future<bool> syncWithCloud({
    required String endpointUrl,
    required String apiKey,
  }) async {
    final cleanUrl = endpointUrl.trim();
    if (cleanUrl.isEmpty) {
      throw Exception('Endpoint URL cannot be empty');
    }

    final backupPayload = await createFullBackupJson();
    final uri = Uri.parse(cleanUrl);

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.trim().isNotEmpty) 'apikey': apiKey.trim(),
        if (apiKey.trim().isNotEmpty) 'Authorization': 'Bearer ${apiKey.trim()}',
      },
      body: backupPayload,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final nowStr = DateTime.now().toIso8601String();
      final cfg = await loadConfig();
      await saveConfig(CloudSyncConfig(
        endpointUrl: cfg.endpointUrl,
        apiKey: cfg.apiKey,
        autoSyncEnabled: cfg.autoSyncEnabled,
        lastSyncTime: nowStr,
      ));
      return true;
    } else {
      throw Exception('Server responded with HTTP ${response.statusCode}: ${response.body}');
    }
  }
}
