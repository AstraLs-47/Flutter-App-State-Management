import '../domain/workout_entry_model.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/core/result.dart';
import '../domain/workout_repository_facade.dart';
import 'workout_local_data_source.dart';
import 'workout_remote_data_source.dart';

/// Repository implementation for workouts.
///
/// Cache-first strategy (required by course specification):
///   1. Check local SQLite cache first (WorkoutLocalDataSource)
///   2. If cache hit → return cached data immediately (no network call)
///   3. If cache miss → fetch from remote API (WorkoutRemoteDataSource)
///   4. On remote success → persist to local cache, then return
///   5. On remote failure → return Failure or empty list
///
/// Write operations (add/update/delete):
///   - Try remote first, fall back to local-only on network failure
///   - Always update local cache to stay in sync
class WorkoutRepositoryImpl implements WorkoutRepositoryFacade {
  final WorkoutLocalDataSource _localDataSource;
  final WorkoutRemoteDataSource _remoteDataSource;

  WorkoutRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<WorkoutEntry>, CoreFailure>> getWorkouts(
    String userId,
  ) async {
    _localDataSource.setUserId(userId);
    try {
      // ── Step 1: Cache hit check ───────────────────────────────────────────
      final localWorkouts = await _localDataSource.getAll();
      if (localWorkouts.isNotEmpty) {
        // Cache hit → return immediately without network request
        return Success(localWorkouts);
      }

      // ── Step 2: Cache miss → fetch from remote ────────────────────────────
      try {
        final remoteWorkouts = await _remoteDataSource.getAll();
        // Persist remote data to local cache
        await _localDataSource.saveAll(remoteWorkouts);
        return Success(remoteWorkouts);
      } catch (_) {
        // Remote also unavailable → return empty (first-time user)
        return const Success([]);
      }
    } catch (e) {
      // Last resort: try local cache before returning failure
      try {
        final localWorkouts = await _localDataSource.getAll();
        return Success(localWorkouts);
      } catch (_) {}
      return Failure(ServerFailure('Failed to fetch workouts: $e'));
    }
  }

  @override
  Future<Result<WorkoutEntry, CoreFailure>> addWorkout(
    WorkoutEntry workout,
    String userId,
  ) async {
    _localDataSource.setUserId(userId);
    try {
      WorkoutEntry toSave = workout;
      // Try remote first (gracefully falls back to local)
      try {
        toSave = await _remoteDataSource.create(workout);
      } catch (_) {}
      // Always persist to local cache
      await _localDataSource.save(toSave);
      return Success(toSave);
    } catch (localError) {
      return Failure(ServerFailure('Failed to add workout: $localError'));
    }
  }

  @override
  Future<Result<WorkoutEntry, CoreFailure>> updateWorkout(
    WorkoutEntry workout,
    String userId,
  ) async {
    _localDataSource.setUserId(userId);
    try {
      WorkoutEntry toSave = workout;
      try {
        toSave = await _remoteDataSource.update(workout);
      } catch (_) {}
      await _localDataSource.update(toSave);
      return Success(toSave);
    } catch (localError) {
      return Failure(ServerFailure('Failed to update workout: $localError'));
    }
  }

  @override
  Future<Result<void, CoreFailure>> deleteWorkout(String id) async {
    try {
      try {
        await _remoteDataSource.delete(id);
      } catch (_) {}
      await _localDataSource.delete(id);
      return const Success(null);
    } catch (localError) {
      return Failure(ServerFailure('Failed to delete workout: $localError'));
    }
  }
}
