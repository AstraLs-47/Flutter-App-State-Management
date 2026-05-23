import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/health_record_model.dart';
import '../../../core/services/database_helper.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../../auth/application/auth_notifier.dart';
import '../infrastructure/health_local_data_source.dart';
import '../infrastructure/health_remote_data_source.dart';
import '../infrastructure/health_repository_impl.dart';

part 'health_metrics_notifier.g.dart';

@riverpod
HealthRepositoryImpl healthRepository(Ref ref) {
  final local = HealthLocalDataSource(DatabaseHelper());
  final remote = HealthRemoteDataSource();
  return HealthRepositoryImpl(local, remote);
}

@riverpod
class HealthMetricsNotifier extends _$HealthMetricsNotifier {
  @override
  FutureOr<List<HealthRecord>> build() async {
    ref.watch(authStateNotifierProvider);
    return _fetchHealthRecords();
  }

  Future<List<HealthRecord>> _fetchHealthRecords() async {
    final user = ref.read(authStateNotifierProvider).value;
    if (user == null) return [];

    final repo = ref.read(healthRepositoryProvider);
    final result = await repo.getHealthRecords(user.id);
    if (result is Success<List<HealthRecord>, CoreFailure>) {
      return result.value;
    } else {
      throw Exception((result as Failure).error.message);
    }
  }

  Future<void> addRecord(HealthRecord record) async {
    final user = ref.read(authStateNotifierProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    final repo = ref.read(healthRepositoryProvider);
    await repo.addHealthRecord(record, user.id);
    state = AsyncValue.data(await _fetchHealthRecords());
  }
}
