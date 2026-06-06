// Integration test: Cache strategy flow
//
// Verifies the strict cache-first strategy of ExerciseRepository using
// an in-memory SQLite database (sqflite_common_ffi) so the test is
// hermetic and requires no device.
//
// Flow 1 — cache hit:
//   Pre-populate the SQLite exercises table → call getExercises(forceRefresh: false)
//   → assert the result contains exactly those rows and ApiClient.get() was NOT called.
//
// Flow 2 — cache miss:
//   Start with an empty exercises table → call getExercises(forceRefresh: false)
//   → assert that ApiClient.get() was called exactly once and results were
//     written to SQLite.

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/data/database_helper.dart';
import 'package:gym_app/core/network/api_client.dart';
import 'package:gym_app/features/exercises/data/exercise_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------
class MockApiClient extends Mock implements ApiClient {}

// ---------------------------------------------------------------------------
// SQLite helpers
// ---------------------------------------------------------------------------

/// Opens a fresh in-memory SQLite database, creates the exercises schema,
/// and returns both the raw [Database] and a [DatabaseHelper]-compatible
/// wrapper that the [ExerciseRepository] can use.
///
/// We create a thin [_InMemoryDatabaseHelper] that delegates every call to
/// the in-memory database so ExerciseRepository's cache logic is exercised
/// against a real SQLite engine.
Future<_InMemoryDatabaseHelper> _openInMemoryHelper() async {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final db = await factory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE exercises (
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
      },
    ),
  );
  return _InMemoryDatabaseHelper(db);
}

/// A DatabaseHelper backed by an explicit in-memory [Database].
/// Only overrides the methods called by ExerciseRepository.
class _InMemoryDatabaseHelper implements DatabaseHelper {
  final Database _db;

  _InMemoryDatabaseHelper(this._db);

  @override
  Future<List<Map<String, dynamic>>> queryAll(String table) => _db.query(table);

  @override
  Future<void> clearTable(String table) async {
    await _db.delete(table);
  }

  @override
  Future<void> insertAll(String table, List<Map<String, dynamic>> rows) async {
    final batch = _db.batch();
    for (final row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> insert(String table, Map<String, dynamic> row) async {
    await _db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> delete(String table, String id) async {
    await _db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAllCaches() async {
    await clearTable('products');
    await clearTable('exercises');
    await clearTable('announcements');
    await clearTable('progress_entries');
    await clearTable('health_metrics');
    await clearTable('categories');
  }

  @override
  Future<void> close() async {
    await _db.close();
  }

  // ── New methods added to DatabaseHelper interface ──────────────────────────

  @override
  Future<void> ensureInitialized() async {
    // No-op: in-memory DB is already open before tests run.
  }

  @override
  Future<void> debugDumpAll() async {
    // No-op in tests.
  }

  @override
  Future<void> dumpTable(String table) async {
    // No-op in tests.
  }
}

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------
final _cachedExerciseRow1 = <String, dynamic>{
  'id': 'e1',
  'name': 'Push Up',
  'description': 'Chest exercise',
  'image_url': 'pushup.png',
  'category_name': 'Chest',
  'duration': '15 min',
  'warmup': 'Arm circles',
  'main_workout': '3 sets of 15',
  'rest': '60s',
  'cached_at': 1000,
};

final _cachedExerciseRow2 = <String, dynamic>{
  'id': 'e2',
  'name': 'Squat',
  'description': 'Leg exercise',
  'image_url': 'squat.png',
  'category_name': 'Legs',
  'duration': '20 min',
  'warmup': 'Leg swings',
  'main_workout': '4 sets of 12',
  'rest': '90s',
  'cached_at': 1001,
};

final _apiExercise = {
  'id': 'e_net',
  'title': 'Deadlift',
  'description': 'Back exercise',
  'category': 'Back',
  'image': 'deadlift.png',
  'duration': '30 min',
  'warmup': 'Hip hinges',
  'main_workout': '5 sets of 5',
  'rest': '2 min',
};

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  late MockApiClient mockApi;

  setUp(() {
    mockApi = MockApiClient();
  });

  group('Cache strategy — ExerciseRepository', () {
    // -----------------------------------------------------------------------
    // Flow 1: cache hit
    // -----------------------------------------------------------------------
    test('Flow 1 (cache hit): getExercises(forceRefresh:false) returns '
        'exactly the 2 cached rows and never calls ApiClient.get()', () async {
      final helper = await _openInMemoryHelper();

      // Pre-populate the SQLite exercises table with 2 rows.
      await helper.insertAll('exercises', [
        _cachedExerciseRow1,
        _cachedExerciseRow2,
      ]);

      final repo = ExerciseRepository(apiClient: mockApi, dbHelper: helper);

      final results = await repo.getExercises(forceRefresh: false);

      // Assert: exactly 2 rows returned.
      expect(results, hasLength(2));
      expect(results.map((e) => e.id), containsAll(['e1', 'e2']));

      // Assert: API was NEVER called.
      verifyNever(() => mockApi.get(any()));
    });

    // -----------------------------------------------------------------------
    // Flow 2: cache miss
    // -----------------------------------------------------------------------
    test('Flow 2 (cache miss): getExercises(forceRefresh:false) calls '
        'ApiClient.get() exactly once and writes results to SQLite', () async {
      final helper = await _openInMemoryHelper();
      // Start with an empty exercises table.
      await helper.clearTable('exercises');

      when(() => mockApi.get(any())).thenAnswer((_) async => [_apiExercise]);

      final repo = ExerciseRepository(apiClient: mockApi, dbHelper: helper);

      final results = await repo.getExercises(forceRefresh: false);

      // Assert: API was called exactly once.
      verify(() => mockApi.get(any())).called(1);

      // Assert: the returned data is the API data.
      expect(results, hasLength(1));
      expect(results.first.id, 'e_net');

      // Assert: data was written to SQLite.
      final rows = await helper.queryAll('exercises');
      expect(rows, hasLength(1));
      expect(rows.first['id'], 'e_net');
    });
  });
}
