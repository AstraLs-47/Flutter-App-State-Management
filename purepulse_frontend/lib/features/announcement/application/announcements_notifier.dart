import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/announcement_model.dart';
import '../../../core/services/database_helper.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../infrastructure/announcement_local_data_source.dart';
import '../infrastructure/announcement_remote_data_source.dart';
import '../infrastructure/announcement_repository_impl.dart';

part 'announcements_notifier.g.dart';

@riverpod
AnnouncementRepositoryImpl announcementRepository(Ref ref) {
  final local = AnnouncementLocalDataSource(DatabaseHelper());
  final remote = AnnouncementRemoteDataSource();
  return AnnouncementRepositoryImpl(local, remote);
}

@riverpod
class AnnouncementsNotifier extends _$AnnouncementsNotifier {
  @override
  FutureOr<List<Announcement>> build() async {
    return _fetchAnnouncements();
  }

  Future<List<Announcement>> _fetchAnnouncements() async {
    final repo = ref.read(announcementRepositoryProvider);
    final result = await repo.getAnnouncements();
    if (result is Success<List<Announcement>, CoreFailure>) {
      return result.value;
    } else {
      throw Exception((result as Failure).error.message);
    }
  }

  Future<void> add(Announcement announcement) async {
    state = const AsyncValue.loading();
    final repo = ref.read(announcementRepositoryProvider);
    await repo.addAnnouncement(announcement);
    state = AsyncValue.data(await _fetchAnnouncements());
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    state = const AsyncValue.loading();
    final repo = ref.read(announcementRepositoryProvider);
    await repo.updateAnnouncement(announcement);
    state = AsyncValue.data(await _fetchAnnouncements());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(announcementRepositoryProvider);
    await repo.deleteAnnouncement(id);
    state = AsyncValue.data(await _fetchAnnouncements());
  }
}
