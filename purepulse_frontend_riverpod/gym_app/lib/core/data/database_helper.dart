// Dart imports:
import 'dart:convert';

// Package imports:
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A functional wrapper using SharedPreferences to simulate a SQL database.
/// This provides persistence across Web and Mobile without requiring sqflite.
class SharedPreferencesDatabase {
  static const String _dbPrefix = 'db_table_';

  Future<void> execute(String sql) async {
    // No-op for schema creation as JSON storage is schema-less.
    return;
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('$_dbPrefix$table');
    if (data == null) return [];

    try {
      final List<dynamic> decoded = json.decode(data);
      if (decoded.isNotEmpty) {
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Database Error: Failed to decode table $table: $e');
      return [];
    }
  }

  Future<int> insert(
    String table,
    Map<String, dynamic> values, {
    dynamic conflictAlgorithm,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_dbPrefix$table';
    final List<Map<String, dynamic>> currentData = await query(table);

    // Simulate "ConflictAlgorithm.replace" by checking for existing ID
    final id = values['id'];
    if (id != null) {
      currentData.removeWhere((item) => item['id'].toString() == id.toString());
    }
    currentData.add(values);

    await prefs.setString(key, json.encode(currentData));
    return 1;
  }

  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = '$_dbPrefix$table';

    if (where == null) {
      await prefs.remove(key);
      return 1;
    }

    // Specific deletion logic (usually by ID in this app)
    final List<Map<String, dynamic>> currentData = await query(table);
    if (where.contains('id = ?') && whereArgs != null && whereArgs.isNotEmpty) {
      final targetId = whereArgs[0].toString();
      final originalLength = currentData.length;
      currentData.removeWhere((item) => item['id'].toString() == targetId);
      if (currentData.length != originalLength) {
        await prefs.setString(key, json.encode(currentData));
        return 1;
      }
    }

    return 0;
  }

  SharedPreferencesBatch batch() {
    return SharedPreferencesBatch(this);
  }
}

class SharedPreferencesBatch {
  final SharedPreferencesDatabase _db;
  final List<Map<String, dynamic>> _ops = [];
  final List<String> _tables = [];

  SharedPreferencesBatch(this._db);

  void insert(
    String table,
    Map<String, dynamic> values, {
    dynamic conflictAlgorithm,
  }) {
    _ops.add(values);
    _tables.add(table);
  }

  Future<List<dynamic>> commit({bool? noResult}) async {
    if (_ops.isEmpty) return [];

    final Map<String, List<Map<String, dynamic>>> tableOps = {};
    for (int i = 0; i < _tables.length; i++) {
      tableOps.putIfAbsent(_tables[i], () => []).add(_ops[i]);
    }

    for (var entry in tableOps.entries) {
      final table = entry.key;
      final List<Map<String, dynamic>> data = await _db.query(table);
      for (var row in entry.value) {
        final id = row['id'];
        if (id != null) {
          data.removeWhere((item) => item['id'].toString() == id.toString());
        }
        data.add(row);
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('db_table_$table', json.encode(data));
    }
    return [];
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  SharedPreferencesDatabase? _db;

  Future<SharedPreferencesDatabase> get database async {
    // Handles hot-reload state corruption if _db contains an old instance (e.g., DummyDatabase)
    if (_db is SharedPreferencesDatabase) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<SharedPreferencesDatabase> _initDb() async {
    _db = SharedPreferencesDatabase();
    return _db!;
  }

  // Generic Cache CRUD helpers
  Future<void> insertAll(String table, List<Map<String, dynamic>> rows) async {
    final db = await database;
    final batch = db.batch();
    for (var row in rows) {
      batch.insert(table, row);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table);
  }

  Future<void> insert(String table, Map<String, dynamic> row) async {
    final db = await database;
    await db.insert(table, row);
  }

  Future<void> delete(String table, String id) async {
    final db = await database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearTable(String table) async {
    final db = await database;
    await db.delete(table);
  }

  Future<void> clearAllCaches() async {
    final db = await database;
    await db.delete('products');
    await db.delete('exercises');
    await db.delete('announcements');
    await db.delete('progress_entries');
    await db.delete('health_metrics');
  }
}
