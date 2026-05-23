import 'workout_entry_model.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';

abstract class WorkoutRepositoryFacade {
  Future<Result<List<WorkoutEntry>, CoreFailure>> getWorkouts(String userId);
  Future<Result<WorkoutEntry, CoreFailure>> addWorkout(
    WorkoutEntry workout,
    String userId,
  );
  Future<Result<WorkoutEntry, CoreFailure>> updateWorkout(
    WorkoutEntry workout,
    String userId,
  );
  Future<Result<void, CoreFailure>> deleteWorkout(String id);
}
