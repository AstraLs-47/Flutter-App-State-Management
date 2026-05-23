import '../domain/health_record_model.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/core/result.dart';
import '../domain/health_repository_facade.dart';
import 'health_local_data_source.dart';
import 'health_remote_data_source.dart';

/// Repository implementation for health metrics.
///
/// Cache-first strategy:
///   1. Check local SQLite cache (HealthLocalDataSource) first
///   2. Cache hit → return local data immediately
///   3. Cache miss → fetch from remote, persist, return
class HealthRepositoryImpl implements HealthRepositoryFacade {
  final HealthLocalDataSource _localDataSource;
  final HealthRemoteDataSource _remoteDataSource;

  HealthRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<HealthRecord>, CoreFailure>> getHealthRecords(
    String userId,
  ) async {
    _localDataSource.setUserId(userId);
    try {
      // ── Step 1: Cache hit check ───────────────────────────────────────────
      final localRecords = await _localDataSource.getAll();
      if (localRecords.isNotEmpty) {
        // Cache hit → return immediately without network request
        return Success(localRecords);
      }

      // ── Step 2: Cache miss → fetch from remote ────────────────────────────
      try {
        final remoteRecords = await _remoteDataSource.getAll();
        await _localDataSource.clear();
        await _localDataSource.saveAll(remoteRecords);
        return Success(remoteRecords);
      } catch (_) {
        // Remote unavailable (expected) → return empty list for first-time user
        return const Success([]);
      }
    } catch (e) {
      try {
        final local = await _localDataSource.getAll();
        return Success(local);
      } catch (_) {}
      return Failure(ServerFailure('Failed to fetch health records: $e'));
    }
  }

  @override
  Future<Result<HealthRecord, CoreFailure>> addHealthRecord(
    HealthRecord record,
    String userId,
  ) async {
    _localDataSource.setUserId(userId);
    try {
      HealthRecord toSave = record;
      // Try remote first (gracefully falls back to local)
      try {
        toSave = await _remoteDataSource.create(record);
      } catch (_) {}
      // Always persist to local cache
      await _localDataSource.save(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to add health record: $e'));
    }
  }
}
