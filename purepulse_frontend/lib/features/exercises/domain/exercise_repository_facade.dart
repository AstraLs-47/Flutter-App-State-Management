import '../../../core/models/activity_model.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';

abstract class ExerciseRepositoryFacade {
  Future<Result<List<Activity>, CoreFailure>> getActivities();
  Future<Result<Activity, CoreFailure>> addActivity(Activity activity);
  Future<Result<Activity, CoreFailure>> updateActivity(Activity activity);
  Future<Result<void, CoreFailure>> deleteActivity(String id);
}
