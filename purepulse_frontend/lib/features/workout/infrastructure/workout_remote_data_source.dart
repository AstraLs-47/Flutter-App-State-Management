import '../../../core/data/remote_data_source.dart';
import '../domain/workout_entry_model.dart';

class WorkoutRemoteDataSource implements RemoteDataSource<WorkoutEntry> {
  // Simulate network delay and return mock data for now
  @override
  Future<WorkoutEntry> create(WorkoutEntry item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<WorkoutEntry>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Not implemented backend yet');
  }

  @override
  Future<WorkoutEntry> update(WorkoutEntry item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }
}
