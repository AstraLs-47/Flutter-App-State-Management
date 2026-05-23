import '../../../core/data/remote_data_source.dart';
import '../../../core/models/activity_model.dart';

class ExerciseRemoteDataSource implements RemoteDataSource<Activity> {
  // Simulate network delay and return mock data for now
  @override
  Future<Activity> create(Activity item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Activity>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Not implemented backend yet');
  }

  @override
  Future<Activity> update(Activity item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }
}
