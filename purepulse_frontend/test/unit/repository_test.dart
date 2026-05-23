// Unit tests for repository layer — verifies cache-first pattern and CRUD ops.
// Uses in-memory fake implementations (no SQLite, no network required).

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/core/models/activity_model.dart';
import 'package:gym_app/core/models/announcement_model.dart';
import 'package:gym_app/core/models/product_model.dart';
import 'package:gym_app/domain/core/failures.dart';
import 'package:gym_app/domain/core/result.dart';
import 'package:gym_app/features/workout/domain/workout_entry_model.dart';
import 'package:gym_app/features/workout/domain/workout_repository_facade.dart';
import 'package:gym_app/features/exercises/domain/exercise_repository_facade.dart';
import 'package:gym_app/features/progress/domain/health_record_model.dart';
import 'package:gym_app/features/progress/domain/health_repository_facade.dart';

// ─────────────────────────────────────────────────────────────────────────────
// In-memory fake implementations (no SQLite, no network)
// These simulate the cache-first pattern the real repositories implement.
// ─────────────────────────────────────────────────────────────────────────────

/// Fake local cache for workouts
class _FakeLocalCache {
  final List<WorkoutEntry> _store = [];
  bool get hasData => _store.isNotEmpty;
  List<WorkoutEntry> getAll() => List.unmodifiable(_store);
  void add(WorkoutEntry w) => _store.add(w);
  void addAll(List<WorkoutEntry> items) => _store.addAll(items);
  void update(WorkoutEntry w) {
    final i = _store.indexWhere((e) => e.id == w.id);
    if (i != -1) _store[i] = w;
  }
  void delete(String id) => _store.removeWhere((e) => e.id == id);
}

/// Fake remote source for workouts
class _FakeRemote {
  final List<WorkoutEntry> _remoteData;
  int fetchCallCount = 0;
  bool shouldThrow;

  _FakeRemote(this._remoteData, {this.shouldThrow = false});

  List<WorkoutEntry> getAll() {
    fetchCallCount++;
    if (shouldThrow) throw Exception('Network error');
    return List.unmodifiable(_remoteData);
  }
}

/// Fake repository that implements cache-first exactly like the real repo
class CacheFirstWorkoutRepo implements WorkoutRepositoryFacade {
  final _FakeLocalCache _local;
  final _FakeRemote _remote;

  CacheFirstWorkoutRepo(this._local, this._remote);

  @override
  Future<Result<List<WorkoutEntry>, CoreFailure>> getWorkouts(
    String userId,
  ) async {
    // ── Step 1: Cache hit check ─────────────────────────────────────────────
    if (_local.hasData) {
      // Cache hit → return immediately WITHOUT calling remote
      return Success(_local.getAll());
    }

    // ── Step 2: Cache miss → fetch from remote ──────────────────────────────
    try {
      final remoteData = _remote.getAll();
      // Save to local cache
      _local.addAll(remoteData);
      return Success(remoteData);
    } catch (_) {
      return const Success([]);
    }
  }

  @override
  Future<Result<WorkoutEntry, CoreFailure>> addWorkout(
    WorkoutEntry w,
    String userId,
  ) async {
    _local.add(w);
    return Success(w);
  }

  @override
  Future<Result<WorkoutEntry, CoreFailure>> updateWorkout(
    WorkoutEntry w,
    String userId,
  ) async {
    final exists = _local.getAll().any((e) => e.id == w.id);
    if (!exists) return Failure(const ServerFailure('Not found'));
    _local.update(w);
    return Success(w);
  }

  @override
  Future<Result<void, CoreFailure>> deleteWorkout(String id) async {
    _local.delete(id);
    return const Success(null);
  }
}

class FakeWorkoutRepository implements WorkoutRepositoryFacade {
  final List<WorkoutEntry> _store = [];

  @override
  Future<Result<List<WorkoutEntry>, CoreFailure>> getWorkouts(
    String userId,
  ) async => Success(List.unmodifiable(_store));

  @override
  Future<Result<WorkoutEntry, CoreFailure>> addWorkout(
    WorkoutEntry workout,
    String userId,
  ) async {
    _store.add(workout);
    return Success(workout);
  }

  @override
  Future<Result<WorkoutEntry, CoreFailure>> updateWorkout(
    WorkoutEntry workout,
    String userId,
  ) async {
    final index = _store.indexWhere((w) => w.id == workout.id);
    if (index == -1) return Failure(const ServerFailure('Workout not found'));
    _store[index] = workout;
    return Success(workout);
  }

  @override
  Future<Result<void, CoreFailure>> deleteWorkout(String id) async {
    _store.removeWhere((w) => w.id == id);
    return const Success(null);
  }
}

class FakeExerciseRepository implements ExerciseRepositoryFacade {
  final List<Activity> _store = [];

  @override
  Future<Result<List<Activity>, CoreFailure>> getActivities() async =>
      Success(List.unmodifiable(_store));

  @override
  Future<Result<Activity, CoreFailure>> addActivity(Activity a) async {
    _store.add(a);
    return Success(a);
  }

  @override
  Future<Result<Activity, CoreFailure>> updateActivity(Activity a) async {
    final i = _store.indexWhere((e) => e.id == a.id);
    if (i == -1) return Failure(const ServerFailure('Activity not found'));
    _store[i] = a;
    return Success(a);
  }

  @override
  Future<Result<void, CoreFailure>> deleteActivity(String id) async {
    _store.removeWhere((a) => a.id == id);
    return const Success(null);
  }
}

class FakeHealthRepository implements HealthRepositoryFacade {
  final List<HealthRecord> _store = [];

  @override
  Future<Result<List<HealthRecord>, CoreFailure>> getHealthRecords(
    String userId,
  ) async => Success(List.unmodifiable(_store));

  @override
  Future<Result<HealthRecord, CoreFailure>> addHealthRecord(
    HealthRecord record,
    String userId,
  ) async {
    _store.add(record);
    return Success(record);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

WorkoutEntry makeWorkout(String id, {String title = 'Test Workout'}) =>
    WorkoutEntry(
      id: id,
      title: title,
      date: '2024-01-15',
      duration: '30 MIN',
      exercise: 'Running (Cardio)',
      intensity: 'Moderate',
      weight: '0',
      sets: '3',
      reps: '10',
    );

Activity makeActivity(String id, {String title = 'Test Activity'}) => Activity(
      id: id,
      title: title,
      description: 'A workout activity',
      image: 'assets/running_image.jpg',
      category: 'Cardio',
      duration: '30 mins',
    );

HealthRecord makeHealthRecord(String id) => HealthRecord(
      id: id,
      systolic: 120,
      diastolic: 80,
      heartRate: 72,
      bloodSugar: 95,
      weight: 70,
      height: 175,
      bmi: 22.9,
      date: DateTime(2024, 1, 15),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── Cache-First Pattern Tests ─────────────────────────────────────────────
  group('Cache-First Pattern (core requirement)', () {
    test(
      'returns local data WITHOUT calling remote when cache has data',
      () async {
        final local = _FakeLocalCache();
        final remote = _FakeRemote([makeWorkout('remote-1')]);
        final repo = CacheFirstWorkoutRepo(local, remote);

        // Pre-populate local cache
        local.add(makeWorkout('cached-1', title: 'Cached Workout'));

        final result = await repo.getWorkouts('user-1');

        // Should return cached data
        final list = (result as Success<List<WorkoutEntry>, CoreFailure>).value;
        expect(list.first.title, 'Cached Workout');

        // CRITICAL: remote must NOT have been called (fetchCallCount == 0)
        expect(remote.fetchCallCount, 0,
            reason: 'Remote should NOT be called when cache has data');
      },
    );

    test(
      'calls remote when cache is empty (cache miss)',
      () async {
        final local = _FakeLocalCache();
        final remote = _FakeRemote([
          makeWorkout('remote-1', title: 'Remote Workout'),
        ]);
        final repo = CacheFirstWorkoutRepo(local, remote);

        // Cache is empty → should hit remote
        final result = await repo.getWorkouts('user-1');

        final list = (result as Success<List<WorkoutEntry>, CoreFailure>).value;
        expect(list.first.title, 'Remote Workout');

        // Remote must have been called exactly once
        expect(remote.fetchCallCount, 1,
            reason: 'Remote MUST be called on cache miss');
      },
    );

    test(
      'persists remote data to local cache after cache miss',
      () async {
        final local = _FakeLocalCache();
        final remote = _FakeRemote([makeWorkout('r1')]);
        final repo = CacheFirstWorkoutRepo(local, remote);

        // Cache miss triggers remote fetch
        await repo.getWorkouts('user-1');

        // Subsequent call should use cache (remote call count stays at 1)
        await repo.getWorkouts('user-1');

        expect(remote.fetchCallCount, 1,
            reason: 'Remote should only be called once — second call hits cache');
        expect(local.hasData, isTrue);
      },
    );

    test(
      'returns empty list gracefully when both cache and remote are empty',
      () async {
        final local = _FakeLocalCache();
        final remote = _FakeRemote([]);
        final repo = CacheFirstWorkoutRepo(local, remote);

        final result = await repo.getWorkouts('user-1');
        expect(
          (result as Success<List<WorkoutEntry>, CoreFailure>).value,
          isEmpty,
        );
      },
    );

    test(
      'returns empty list when cache is empty and remote throws',
      () async {
        final local = _FakeLocalCache();
        final remote = _FakeRemote([], shouldThrow: true);
        final repo = CacheFirstWorkoutRepo(local, remote);

        final result = await repo.getWorkouts('user-1');
        // Should gracefully return empty, not throw
        expect(result, isA<Success>());
      },
    );
  });

  // ── WorkoutRepository CRUD ────────────────────────────────────────────────
  group('WorkoutRepository CRUD (fake)', () {
    late FakeWorkoutRepository repo;

    setUp(() => repo = FakeWorkoutRepository());

    test('getWorkouts returns empty list initially', () async {
      final result = await repo.getWorkouts('user-1');
      expect((result as Success<List<WorkoutEntry>, CoreFailure>).value, isEmpty);
    });

    test('addWorkout inserts entry', () async {
      await repo.addWorkout(makeWorkout('w1'), 'user-1');
      final result = await repo.getWorkouts('user-1');
      expect((result as Success<List<WorkoutEntry>, CoreFailure>).value.length, 1);
    });

    test('addWorkout returns the added workout', () async {
      final w = makeWorkout('w2', title: 'Evening Run');
      final result = await repo.addWorkout(w, 'user-1');
      expect((result as Success<WorkoutEntry, CoreFailure>).value.title, 'Evening Run');
    });

    test('updateWorkout modifies existing entry', () async {
      await repo.addWorkout(makeWorkout('w3', title: 'Old'), 'user-1');
      await repo.updateWorkout(makeWorkout('w3', title: 'New'), 'user-1');
      final result = await repo.getWorkouts('user-1');
      expect((result as Success<List<WorkoutEntry>, CoreFailure>).value.first.title, 'New');
    });

    test('updateWorkout returns Failure for unknown id', () async {
      final result = await repo.updateWorkout(makeWorkout('nonexistent'), 'user-1');
      expect(result, isA<Failure>());
    });

    test('deleteWorkout removes entry', () async {
      await repo.addWorkout(makeWorkout('w4'), 'user-1');
      await repo.deleteWorkout('w4');
      final result = await repo.getWorkouts('user-1');
      expect((result as Success<List<WorkoutEntry>, CoreFailure>).value, isEmpty);
    });

    test('multiple workouts stored independently', () async {
      await repo.addWorkout(makeWorkout('w5', title: 'A'), 'user-1');
      await repo.addWorkout(makeWorkout('w6', title: 'B'), 'user-1');
      await repo.addWorkout(makeWorkout('w7', title: 'C'), 'user-1');
      final result = await repo.getWorkouts('user-1');
      expect((result as Success<List<WorkoutEntry>, CoreFailure>).value.length, 3);
    });

    test('delete only removes the correct entry', () async {
      await repo.addWorkout(makeWorkout('w8', title: 'Keep'), 'user-1');
      await repo.addWorkout(makeWorkout('w9', title: 'Delete'), 'user-1');
      await repo.deleteWorkout('w9');
      final result = await repo.getWorkouts('user-1');
      final list = (result as Success<List<WorkoutEntry>, CoreFailure>).value;
      expect(list.length, 1);
      expect(list.first.title, 'Keep');
    });
  });

  // ── ExerciseRepository CRUD ───────────────────────────────────────────────
  group('ExerciseRepository CRUD (fake)', () {
    late FakeExerciseRepository repo;

    setUp(() => repo = FakeExerciseRepository());

    test('getActivities returns empty list initially', () async {
      final result = await repo.getActivities();
      expect((result as Success<List<Activity>, CoreFailure>).value, isEmpty);
    });

    test('addActivity inserts activity', () async {
      await repo.addActivity(makeActivity('a1', title: 'Cardio Blast'));
      final result = await repo.getActivities();
      final list = (result as Success<List<Activity>, CoreFailure>).value;
      expect(list.length, 1);
      expect(list.first.title, 'Cardio Blast');
    });

    test('updateActivity modifies existing activity', () async {
      await repo.addActivity(makeActivity('a2', title: 'Old'));
      await repo.updateActivity(makeActivity('a2', title: 'Updated'));
      final result = await repo.getActivities();
      expect((result as Success<List<Activity>, CoreFailure>).value.first.title, 'Updated');
    });

    test('updateActivity returns Failure for unknown id', () async {
      final result = await repo.updateActivity(makeActivity('unknown'));
      expect(result, isA<Failure>());
    });

    test('deleteActivity removes activity', () async {
      await repo.addActivity(makeActivity('a3'));
      await repo.deleteActivity('a3');
      final result = await repo.getActivities();
      expect((result as Success<List<Activity>, CoreFailure>).value, isEmpty);
    });
  });

  // ── HealthRepository ──────────────────────────────────────────────────────
  group('HealthRepository (fake)', () {
    late FakeHealthRepository repo;

    setUp(() => repo = FakeHealthRepository());

    test('getHealthRecords returns empty list initially', () async {
      final result = await repo.getHealthRecords('user-1');
      expect((result as Success<List<HealthRecord>, CoreFailure>).value, isEmpty);
    });

    test('addHealthRecord inserts record', () async {
      await repo.addHealthRecord(makeHealthRecord('hr1'), 'user-1');
      final result = await repo.getHealthRecords('user-1');
      expect((result as Success<List<HealthRecord>, CoreFailure>).value.length, 1);
    });

    test('multiple records can be added', () async {
      await repo.addHealthRecord(makeHealthRecord('hr2'), 'user-1');
      await repo.addHealthRecord(makeHealthRecord('hr3'), 'user-1');
      final result = await repo.getHealthRecords('user-1');
      expect((result as Success<List<HealthRecord>, CoreFailure>).value.length, 2);
    });

    test('addHealthRecord returns the record', () async {
      final record = makeHealthRecord('hr4');
      final result = await repo.addHealthRecord(record, 'user-1');
      expect((result as Success<HealthRecord, CoreFailure>).value.id, 'hr4');
    });
  });
}
