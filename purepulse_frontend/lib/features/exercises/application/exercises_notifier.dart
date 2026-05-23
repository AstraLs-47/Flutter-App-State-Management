import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/models/activity_model.dart';
import '../../../core/services/database_helper.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../infrastructure/exercise_local_data_source.dart';
import '../infrastructure/exercise_remote_data_source.dart';
import '../infrastructure/exercise_repository_impl.dart';

part 'exercises_notifier.g.dart';

@riverpod
ExerciseRepositoryImpl exerciseRepository(Ref ref) {
  final local = ExerciseLocalDataSource(DatabaseHelper());
  final remote = ExerciseRemoteDataSource();
  return ExerciseRepositoryImpl(local, remote);
}

@riverpod
class ActivitiesNotifier extends _$ActivitiesNotifier {
  @override
  FutureOr<List<Activity>> build() async {
    return _fetchActivities();
  }

  Future<List<Activity>> _fetchActivities() async {
    final repo = ref.read(exerciseRepositoryProvider);
    final result = await repo.getActivities();
    if (result is Success<List<Activity>, CoreFailure>) {
      return result.value;
    } else {
      throw Exception((result as Failure).error.message);
    }
  }

  Future<void> add(Activity activity) async {
    state = const AsyncValue.loading();
    final repo = ref.read(exerciseRepositoryProvider);
    await repo.addActivity(activity);
    state = AsyncValue.data(await _fetchActivities());
  }

  Future<void> updateActivity(Activity activity) async {
    state = const AsyncValue.loading();
    final repo = ref.read(exerciseRepositoryProvider);
    await repo.updateActivity(activity);
    state = AsyncValue.data(await _fetchActivities());
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(exerciseRepositoryProvider);
    await repo.deleteActivity(id);
    state = AsyncValue.data(await _fetchActivities());
  }
}
