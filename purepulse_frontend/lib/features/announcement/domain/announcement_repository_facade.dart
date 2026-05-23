import '../../../core/models/announcement_model.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';

abstract class AnnouncementRepositoryFacade {
  Future<Result<List<Announcement>, CoreFailure>> getAnnouncements();
  Future<Result<Announcement, CoreFailure>> addAnnouncement(
    Announcement announcement,
  );
  Future<Result<Announcement, CoreFailure>> updateAnnouncement(
    Announcement announcement,
  );
  Future<Result<void, CoreFailure>> deleteAnnouncement(String id);
}
