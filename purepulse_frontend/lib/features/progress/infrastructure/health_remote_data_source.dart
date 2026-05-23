import '../../../core/data/remote_data_source.dart';
import '../domain/health_record_model.dart';

class HealthRemoteDataSource implements RemoteDataSource<HealthRecord> {
  // Simulate network delay and return mock data for now
  @override
  Future<HealthRecord> create(HealthRecord item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }

  @override
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<HealthRecord>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 800));
    throw Exception('Not implemented backend yet');
  }

  @override
  Future<HealthRecord> update(HealthRecord item) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return item;
  }
}
