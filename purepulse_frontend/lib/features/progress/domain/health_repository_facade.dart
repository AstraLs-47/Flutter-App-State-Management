import 'health_record_model.dart';
import '../../../domain/core/result.dart';
import '../../../domain/core/failures.dart';

abstract class HealthRepositoryFacade {
  Future<Result<List<HealthRecord>, CoreFailure>> getHealthRecords(
    String userId,
  );
  Future<Result<HealthRecord, CoreFailure>> addHealthRecord(
    HealthRecord record,
    String userId,
  );
}
