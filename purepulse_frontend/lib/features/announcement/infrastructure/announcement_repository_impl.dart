import '../../../core/models/announcement_model.dart';
import '../../../domain/core/failures.dart';
import '../../../domain/core/result.dart';
import '../domain/announcement_repository_facade.dart';
import 'announcement_local_data_source.dart';
import 'announcement_remote_data_source.dart';

/// Repository implementation for announcements.
///
/// Cache-first strategy:
///   1. Check local SQLite cache (AnnouncementLocalDataSource) first
///   2. Cache hit → return local data immediately
///   3. Cache miss → fetch from remote, persist, return
class AnnouncementRepositoryImpl implements AnnouncementRepositoryFacade {
  final AnnouncementLocalDataSource _localDataSource;
  final AnnouncementRemoteDataSource _remoteDataSource;

  AnnouncementRepositoryImpl(this._localDataSource, this._remoteDataSource);

  @override
  Future<Result<List<Announcement>, CoreFailure>> getAnnouncements() async {
    try {
      // ── Step 1: Cache hit check ───────────────────────────────────────────
      final localAnnouncements = await _localDataSource.getAll();
      if (localAnnouncements.isNotEmpty) {
        // Cache hit → return immediately without network request
        return Success(localAnnouncements);
      }

      // ── Step 2: Cache miss → fetch from remote ────────────────────────────
      final remoteAnnouncements = await _remoteDataSource.getAll();
      await _localDataSource.clear();
      await _localDataSource.saveAll(remoteAnnouncements);
      return Success(remoteAnnouncements);
    } catch (e) {
      try {
        final local = await _localDataSource.getAll();
        if (local.isNotEmpty) return Success(local);
      } catch (_) {}
      return Failure(ServerFailure('Failed to fetch announcements: $e'));
    }
  }

  @override
  Future<Result<Announcement, CoreFailure>> addAnnouncement(
    Announcement announcement,
  ) async {
    try {
      Announcement toSave = announcement;
      try {
        toSave = await _remoteDataSource.create(announcement);
      } catch (_) {}
      await _localDataSource.save(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to add announcement: $e'));
    }
  }

  @override
  Future<Result<Announcement, CoreFailure>> updateAnnouncement(
    Announcement announcement,
  ) async {
    try {
      Announcement toSave = announcement;
      try {
        toSave = await _remoteDataSource.update(announcement);
      } catch (_) {}
      await _localDataSource.update(toSave);
      return Success(toSave);
    } catch (e) {
      return Failure(ServerFailure('Failed to update announcement: $e'));
    }
  }

  @override
  Future<Result<void, CoreFailure>> deleteAnnouncement(String id) async {
    try {
      try {
        await _remoteDataSource.delete(id);
      } catch (_) {}
      await _localDataSource.delete(id);
      return const Success(null);
    } catch (e) {
      return Failure(ServerFailure('Failed to delete announcement: $e'));
    }
  }
}
