import '../../../core/models/activity_model.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/core/result.dart';
import '../domain/exercise_repository_facade.dart';
import 'exercise_local_data_source.dart';
import 'exercise_remote_data_source.dart';

/// Repository implementation for exercises/activities.
///
/// Cache-first strategy:
///   1. Check local SQLite cache (ExerciseLocalDataSource) first
///   2. Cache hit → return local data immediately
///   3. Cache miss → fetch from remote, persist, return
class ExerciseRepositoryImpl implements ExerciseRepositoryFacade {
  final ExerciseLocalDataSource _localDataSource;
  final ExerciseRemoteDataSource _remoteDataSource;

  ExerciseRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<Activity>, CoreFailure>> getActivities() async {
    try {
      // ── Step 1: Cache hit check ───────────────────────────────────────────
      final localActivities = await _localDataSource.getAll();
      if (localActivities.isNotEmpty) {
        // Cache hit → return immediately without network request
        return Success(localActivities);
      }

      // ── Step 2: Cache miss → fetch from remote ────────────────────────────
      final remoteActivities = await _remoteDataSource.getAll();
      // Persist remote data to local cache
      await _localDataSource.clear();
      await _localDataSource.saveAll(remoteActivities);
      return Success(remoteActivities);
    } catch (e) {
      // Last resort: re-check local cache
      try {
        final local = await _localDataSource.getAll();
        if (local.isNotEmpty) return Success(local);
      } catch (_) {}
      return Failure(ServerFailure('Failed to fetch activities: $e'));
    }
  }

  @override
  Future<Result<Activity, CoreFailure>> addActivity(Activity activity) async {
    try {
      Activity toSave = activity;
      try {
        toSave = await _remoteDataSource.create(activity);
      } catch (_) {}
      await _localDataSource.save(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to add activity: $e'));
    }
  }

  @override
  Future<Result<Activity, CoreFailure>> updateActivity(
    Activity activity,
  ) async {
    try {
      Activity toSave = activity;
      try {
        toSave = await _remoteDataSource.update(activity);
      } catch (_) {}
      await _localDataSource.update(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to update activity: $e'));
    }
  }

  @override
  Future<Result<void, CoreFailure>> deleteActivity(String id) async {
    try {
      try {
        await _remoteDataSource.delete(id);
      } catch (_) {}
      await _localDataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Failed to delete activity: $e'));
    }
  }
}
