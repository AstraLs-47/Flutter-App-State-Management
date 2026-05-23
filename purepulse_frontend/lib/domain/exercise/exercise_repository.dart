import '../core/result.dart';
import '../core/failures.dart';
import 'exercise.dart';

abstract class ExerciseRepository {
  Future<Result<List<Exercise>, CoreFailure>> getExercisesForWorkout(
    String workoutId,
  );
  Future<Result<Exercise, CoreFailure>> createExercise(Exercise exercise);
  Future<Result<Exercise, CoreFailure>> updateExercise(Exercise exercise);
  Future<Result<void, CoreFailure>> deleteExercise(String id);
}
