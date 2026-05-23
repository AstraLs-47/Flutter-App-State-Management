import '../../../core/data/remote_data_source.dart';
import '../../../core/models/announcement_model.dart';

class AnnouncementRemoteDataSource implements RemoteDataSource<Announcement> {
  // Simulate network delay and return mock data for now
  @override
  Future<Announcement> create(Announcement item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Announcement>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Not implemented backend yet');
  }

  @override
  Future<Announcement> update(Announcement item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }
}
