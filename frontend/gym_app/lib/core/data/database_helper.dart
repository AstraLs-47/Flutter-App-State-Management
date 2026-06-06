// Package imports:
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  sqflite.Database? _sqliteDb;
  bool _initFailed = false;
  // Serialize concurrent initialization calls — only one _initDb() runs at a time.
  Future<void>? _initFuture;

  /// Public entry-point called once from main() before runApp().
  /// Ensures the database is open and all tables exist before any widget or
  /// repository tries to query / insert data.
  Future<void> ensureInitialized() async {
    await _ensureDb();

    // On web, if the database fails to open on the first attempt (e.g. the web
    // worker is still starting up), retry once after a short delay before
    // giving up permanently.
    if (_sqliteDb == null && kIsWeb) {
      debugPrint(
        'DatabaseHelper: Web DB init failed on first attempt — '
        'retrying in 2 s (web worker may still be starting)...',
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await _ensureDb();
    }

    if (_sqliteDb != null) {
      debugPrint('DatabaseHelper: ensureInitialized — DB is open and ready.');
      // Avoid dumping all tables on every init in tests to prevent hangs
      // await debugDumpAll();
    } else {
      debugPrint(
        'DatabaseHelper: ensureInitialized — DB could not be opened; '
        'app will run in API-only mode.',
      );
    }
  }

  /// Closes the current database connection and resets the initialization state.
  /// Essential for integration tests to prevent file locks and deadlocks.
  Future<void> close() async {
    await _sqliteDb?.close();
    _sqliteDb = null;
    _initFuture = null;
    _initFailed = false;
    debugPrint('DatabaseHelper: Database closed and state reset');
  }

  /// Prints the entire contents of a table to the debug console.
  /// Useful for verifying cache state during integration tests.
  Future<void> dumpTable(String table) async {
    try {
      final rows = await queryAll(table);
      debugPrint('--- [CACHE] SQLite Table: $table (${rows.length} rows) ---');
      for (final row in rows) {
        debugPrint(row.toString());
      }
      debugPrint('--- [CACHE] End of $table ---');
    } catch (e) {
      debugPrint('DatabaseHelper: Could not dump table $table: $e');
    }
  }

  /// Dumps all known cache tables to the console.
  Future<void> debugDumpAll() async {
    debugPrint('DatabaseHelper: === Cached Data Snapshot ===');
    await dumpTable('exercises');
    await dumpTable('products');
    await dumpTable('announcements');
    await dumpTable('categories');
    await dumpTable('users');
    debugPrint('DatabaseHelper: === End of Cached Data Snapshot ===');
  }

  Future<void> _initDb() async {
    try {
      if (kIsWeb) {
        // The global sqflite.databaseFactory has already been set to
        // databaseFactoryFfiWeb in main() before ensureInitialized() is called.
        // Using sqflite.openDatabase() here respects that factory and avoids
        // the race condition that occurred when calling databaseFactoryFfiWeb
        // directly before the service worker was fully registered.
        debugPrint('DatabaseHelper: Opening web database via global factory');
        _sqliteDb = await sqflite.openDatabase(
          'purepulse.db',
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        debugPrint('DatabaseHelper: Web database opened successfully');
      } else {
        debugPrint('DatabaseHelper: Opening mobile/desktop database');
        final documentsDirectory = await getApplicationDocumentsDirectory();
        final path = p.join(documentsDirectory.path, 'purepulse.db');
        debugPrint('DatabaseHelper: Database path: $path');
        _sqliteDb = await sqflite.openDatabase(
          path,
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        debugPrint(
          'DatabaseHelper: Mobile/desktop database opened successfully',
        );
      }
      debugPrint('DatabaseHelper: Initialization complete');
    } catch (e) {
      if (kIsWeb && e.toString().contains('null')) {
        debugPrint('--- [CRITICAL WEB ERROR] ---');
        debugPrint(
          'Service Worker failed. Ensure sqflite_sw.js and sqlite3.wasm exist in web/ folder.',
        );
        debugPrint('Run: dart run sqflite_ffi_web:setup');
      }
      _initFailed = true;
      debugPrint('DatabaseHelper init failed: $e');
      debugPrint('Continuing in API-only mode (no local cache).');
    }
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    try {
      debugPrint('DatabaseHelper: Creating products table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS products (
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          category TEXT,
          image_url TEXT,
          is_active INTEGER,
          cached_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create products table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating exercises table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id TEXT PRIMARY KEY,
          name TEXT,
          description TEXT,
          image_url TEXT,
          category_name TEXT,
          duration TEXT,
          warmup TEXT,
          main_workout TEXT,
          rest TEXT,
          cached_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create exercises table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating announcements table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS announcements (
          id TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          date TEXT,
          cached_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create announcements table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating progress_entries table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS progress_entries (
          id TEXT PRIMARY KEY,
          exercise_name TEXT,
          entry_date TEXT,
          duration_minutes INTEGER,
          sets INTEGER,
          reps INTEGER,
          weight REAL,
          intensity TEXT,
          notes TEXT,
          achievement TEXT,
          calories INTEGER,
          created_at TEXT,
          cached_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create progress_entries table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating health_metrics table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS health_metrics (
          id TEXT PRIMARY KEY,
          blood_pressure_systolic INTEGER,
          blood_pressure_diastolic INTEGER,
          resting_heart_rate INTEGER,
          blood_sugar REAL,
          weight REAL,
          height REAL,
          bmi REAL,
          date TEXT,
          cached_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create health_metrics table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating categories table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS categories (
          id TEXT PRIMARY KEY,
          name TEXT,
          type TEXT
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create categories table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating user_sessions table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_sessions (
          id INTEGER PRIMARY KEY,
          user_id TEXT,
          token TEXT,
          created_at INTEGER
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create user_sessions table: $e');
    }

    try {
      debugPrint('DatabaseHelper: Creating users table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          role TEXT,
          created_at TEXT
        )
      ''');
    } catch (e) {
      debugPrint('DatabaseHelper: Failed to create users table: $e');
    }

    debugPrint('DatabaseHelper: All tables created/verified successfully');
  }

  Future<void> _onUpgrade(
    sqflite.Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE progress_entries ADD COLUMN calories INTEGER DEFAULT 0',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      try {
        await db.execute(
          'ALTER TABLE progress_entries ADD COLUMN created_at TEXT',
        );
      } catch (_) {}
    }
  }

  Future<void> _ensureDb() async {
    if (_sqliteDb != null) return;
    if (_initFailed) {
      // Don't permanently give up — allow a retry in case the previous attempt
      // was a transient failure (e.g. service-worker not yet active on first load).
      debugPrint('DatabaseHelper: Retrying database initialization...');
      _initFailed = false;
      _initFuture = null;
    }
    // Only one initialization runs; all concurrent callers await the same future.
    _initFuture ??= _initDb();
    await _initFuture;
    // Reset the future slot so a retry next call works.
    _initFuture = null;
  }

  // ── Generic Cache CRUD helpers ──────────────────────────────────────────────

  Future<void> insertAll(String table, List<Map<String, dynamic>> rows) async {
    try {
      await _ensureDb();
      if (_sqliteDb == null) {
        debugPrint(
          'DatabaseHelper.insertAll($table): Database unavailable, skipping insert',
        );
        return;
      }
      final batch = _sqliteDb!.batch();
      for (var row in rows) {
        batch.insert(
          table,
          row,
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint(
        'DatabaseHelper.insertAll($table): Successfully inserted ${rows.length} rows',
      );
    } catch (e) {
      debugPrint('DatabaseHelper.insertAll($table) error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    try {
      await _ensureDb();
      if (_sqliteDb == null) {
        debugPrint(
          'DatabaseHelper.queryAll($table): Database unavailable, returning empty list',
        );
        return [];
      }
      final result = await _sqliteDb!.query(table);
      debugPrint(
        'DatabaseHelper.queryAll($table): Retrieved ${result.length} rows',
      );
      return result;
    } catch (e) {
      debugPrint('DatabaseHelper.queryAll($table) error: $e');
      return [];
    }
  }

  Future<void> insert(String table, Map<String, dynamic> row) async {
    try {
      await _ensureDb();
      if (_sqliteDb == null) {
        debugPrint(
          'DatabaseHelper.insert($table): Database unavailable, skipping insert',
        );
        return;
      }
      await _sqliteDb!.insert(
        table,
        row,
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      debugPrint('DatabaseHelper.insert($table): Successfully inserted 1 row');
    } catch (e) {
      debugPrint('DatabaseHelper.insert($table) error: $e');
    }
  }

  Future<void> delete(String table, String id) async {
    try {
      await _ensureDb();
      if (_sqliteDb == null) {
        debugPrint(
          'DatabaseHelper.delete($table): Database unavailable, skipping delete',
        );
        return;
      }
      await _sqliteDb!.delete(table, where: 'id = ?', whereArgs: [id]);
      debugPrint('DatabaseHelper.delete($table, $id): Successfully deleted');
    } catch (e) {
      debugPrint('DatabaseHelper.delete($table) error: $e');
    }
  }

  Future<void> clearTable(String table) async {
    try {
      await _ensureDb();
      if (_sqliteDb == null) {
        debugPrint(
          'DatabaseHelper.clearTable($table): Database unavailable, skipping clear',
        );
        return;
      }
      await _sqliteDb!.delete(table);
      debugPrint('DatabaseHelper.clearTable($table): Successfully cleared');
    } catch (e) {
      debugPrint('DatabaseHelper.clearTable($table) error: $e');
    }
  }

  Future<void> clearAllCaches() async {
    await clearTable('products');
    await clearTable('exercises');
    await clearTable('announcements');
    await clearTable('progress_entries');
    await clearTable('health_metrics');
    await clearTable('categories');
  }
}
