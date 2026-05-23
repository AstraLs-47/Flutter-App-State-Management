import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/workout_entry_model.dart';
import '../../../core/services/database_helper.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';
import '../../auth/application/auth_notifier.dart';
import '../infrastructure/workout_local_data_source.dart';
import '../infrastructure/workout_remote_data_source.dart';
import '../infrastructure/workout_repository_impl.dart';

part 'workouts_notifier.g.dart';

@riverpod
WorkoutRepositoryImpl workoutRepository(Ref ref) {
  final local = WorkoutLocalDataSource(DatabaseHelper());
  final remote = WorkoutRemoteDataSource();
  return WorkoutRepositoryImpl(local, remote);
}

@riverpod
class WorkoutsNotifier extends _$WorkoutsNotifier {
  @override
  FutureOr<List<WorkoutEntry>> build() async {
    ref.watch(authStateNotifierProvider);
    return _fetchWorkouts();
  }

  Future<List<WorkoutEntry>> _fetchWorkouts() async {
    final user = ref.read(authStateNotifierProvider).value;
    if (user == null) return [];

    final repo = ref.read(workoutRepositoryProvider);
    final result = await repo.getWorkouts(user.id);
    if (result is Success<List<WorkoutEntry>, CoreFailure>) {
      return result.value;
    } else {
      throw Exception((result as Failure).error.message);
    }
  }

  Future<void> addWorkout(WorkoutEntry workout) async {
    final user = ref.read(authStateNotifierProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    final repo = ref.read(workoutRepositoryProvider);
    await repo.addWorkout(workout, user.id);
    state = AsyncValue.data(await _fetchWorkouts());
  }

  Future<void> updateWorkout(WorkoutEntry workout) async {
    final user = ref.read(authStateNotifierProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    final repo = ref.read(workoutRepositoryProvider);
    await repo.updateWorkout(workout, user.id);
    state = AsyncValue.data(await _fetchWorkouts());
  }

  Future<void> deleteWorkout(String id) async {
    state = const AsyncValue.loading();
    final repo = ref.read(workoutRepositoryProvider);
    await repo.deleteWorkout(id);
    state = AsyncValue.data(await _fetchWorkouts());
  }
}
